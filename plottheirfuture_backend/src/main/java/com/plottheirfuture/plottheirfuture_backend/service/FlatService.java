package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.dto.FlatDto;
import com.plottheirfuture.plottheirfuture_backend.dto.FlatSectionDto;
import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatSection;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.entity.WeddingStatus;
import com.plottheirfuture.plottheirfuture_backend.exception.ConflictException;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatSectionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Slf4j
public class FlatService {

    private final FlatRepository flatRepository;
    private final FlatSectionRepository flatSectionRepository;
    private final WeddingRepository weddingRepository;
    private final FloorPlanZoneRepository floorPlanZoneRepository;

    private String serializeList(List<String> list) {
        if (list == null || list.isEmpty()) return "";
        return String.join("||", list);
    }

    private List<String> deserializeList(String raw) {
        if (raw == null || raw.isBlank()) return Collections.emptyList();
        String[] parts = raw.split("\\|\\|");
        List<String> list = new ArrayList<>();
        for (String p : parts) {
            if (!p.isBlank()) list.add(p.trim());
        }
        return list;
    }

    /**
     * Generate sequential unique Flat ID (e.g., FLAT-2026-HYD-001)
     */
    public synchronized String generateNextFlatId() {
        long count = flatRepository.count() + 1;
        return String.format("FLAT-2026-HYD-%03d", count);
    }

    /**
     * List all flats with optional status filter, search query, and pagination
     */
    public Page<FlatDto> searchFlats(FlatStatus status, String query, Pageable pageable) {
        Page<Flat> page = flatRepository.searchFlats(status, query, pageable);
        return page.map(this::toDto);
    }

    /**
     * Get all flats as list (for dropdowns / quick lists)
     */
    public List<FlatDto> getAllFlats(FlatStatus status) {
        List<Flat> flats = (status != null) ? flatRepository.findByStatus(status) : flatRepository.findAll();
        List<FlatDto> list = new ArrayList<>();
        for (Flat f : flats) {
            list.add(toDto(f));
        }
        return list;
    }

    /**
     * Get Flat by Database ID with full section breakdown and live area validation
     */
    public FlatDto getFlatById(Long id) {
        Flat flat = flatRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + id));
        return toDto(flat);
    }

    /**
     * Register a new flat
     */
    @Transactional
    public FlatDto createFlat(FlatDto dto) {
        String generatedId = (dto.getFlatId() != null && !dto.getFlatId().isBlank())
                ? dto.getFlatId().trim()
                : generateNextFlatId();

        int bricksPerSft = (dto.getBricksPerSft() != null && dto.getBricksPerSft() > 0)
                ? dto.getBricksPerSft()
                : 10;

        double pricePerSft = (dto.getPricePerSft() != null && dto.getPricePerSft() > 0)
                ? dto.getPricePerSft()
                : 4500.0;

        double pricePerBrick = (dto.getPricePerBrick() != null && dto.getPricePerBrick() > 0)
                ? dto.getPricePerBrick()
                : Math.round((pricePerSft / bricksPerSft) * 100.0) / 100.0;

        String galleryJson = serializeList(dto.getGalleryImages());

        Flat flat = Flat.builder()
                .flatId(generatedId)
                .name(dto.getName().trim())
                .description(dto.getDescription())
                .coverImageUrl(dto.getCoverImageUrl() != null ? dto.getCoverImageUrl() : "assets/images/apartment_poster.jpg")
                .galleryImagesJson(galleryJson)
                .builtUpAreaSft(dto.getBuiltUpAreaSft())
                .carpetAreaSft(dto.getCarpetAreaSft())
                .bedrooms(dto.getBedrooms() != null ? dto.getBedrooms() : 2)
                .bathrooms(dto.getBathrooms() != null ? dto.getBathrooms() : 2)
                .balconies(dto.getBalconies() != null ? dto.getBalconies() : 1)
                .halls(dto.getHalls() != null ? dto.getHalls() : 1)
                .kitchens(dto.getKitchens() != null ? dto.getKitchens() : 1)
                .location(dto.getLocation() != null ? dto.getLocation() : "Hyderabad (Financial District)")
                .address(dto.getAddress())
                .pricePerSft(pricePerSft)
                .bricksPerSft(bricksPerSft)
                .pricePerBrick(pricePerBrick)
                .status(FlatStatus.DRAFT)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Flat saved = flatRepository.save(flat);

        // If default or custom sections provided in registration payload, create them
        if (dto.getSections() != null && !dto.getSections().isEmpty()) {
            for (FlatSectionDto secDto : dto.getSections()) {
                addSection(saved.getId(), secDto);
            }
        }

        return toDto(saved);
    }

    /**
     * Update Flat details
     */
    @Transactional
    public FlatDto updateFlat(Long id, FlatDto dto) {
        Flat existing = flatRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + id));

        if (existing.getStatus() == FlatStatus.ASSIGNED) {
            log.info("Updating assigned flat {}: updating non-destructive metadata", existing.getFlatId());
        }

        if (dto.getName() != null) existing.setName(dto.getName().trim());
        if (dto.getDescription() != null) existing.setDescription(dto.getDescription());
        if (dto.getCoverImageUrl() != null) existing.setCoverImageUrl(dto.getCoverImageUrl());
        if (dto.getBuiltUpAreaSft() != null) existing.setBuiltUpAreaSft(dto.getBuiltUpAreaSft());
        if (dto.getCarpetAreaSft() != null) existing.setCarpetAreaSft(dto.getCarpetAreaSft());
        if (dto.getBedrooms() != null) existing.setBedrooms(dto.getBedrooms());
        if (dto.getBathrooms() != null) existing.setBathrooms(dto.getBathrooms());
        if (dto.getBalconies() != null) existing.setBalconies(dto.getBalconies());
        if (dto.getHalls() != null) existing.setHalls(dto.getHalls());
        if (dto.getKitchens() != null) existing.setKitchens(dto.getKitchens());
        if (dto.getLocation() != null) existing.setLocation(dto.getLocation());
        if (dto.getAddress() != null) existing.setAddress(dto.getAddress());

        if (dto.getPricePerSft() != null) {
            existing.setPricePerSft(dto.getPricePerSft());
            if (dto.getBricksPerSft() != null) {
                existing.setBricksPerSft(dto.getBricksPerSft());
            }
            int bPerSft = existing.getBricksPerSft() != null ? existing.getBricksPerSft() : 10;
            existing.setPricePerBrick(Math.round((existing.getPricePerSft() / bPerSft) * 100.0) / 100.0);
        }

        if (dto.getGalleryImages() != null) {
            existing.setGalleryImagesJson(serializeList(dto.getGalleryImages()));
        }

        existing.setUpdatedAt(LocalDateTime.now());
        return toDto(flatRepository.save(existing));
    }

    /**
     * Delete Flat
     */
    @Transactional
    public void deleteFlat(Long id) {
        Flat flat = flatRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + id));

        if (flat.getStatus() == FlatStatus.ASSIGNED) {
            throw new ConflictException("Cannot delete flat " + flat.getFlatId() + " because it is currently assigned to active wedding " + flat.getAssignedWeddingSlug());
        }

        flatSectionRepository.deleteByFlatId(id);
        flatRepository.delete(flat);
    }

    /**
     * Dynamic Section Management: Add a section
     */
    @Transactional
    public FlatSectionDto addSection(Long flatId, FlatSectionDto secDto) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        double secPricePerSft = (secDto.getPricePerSft() != null && secDto.getPricePerSft() > 0)
                ? secDto.getPricePerSft()
                : flat.getPricePerSft();

        int area = secDto.getAreaSft();
        if (area <= 0 && secDto.getLengthFt() != null && secDto.getWidthFt() != null) {
            area = (int) Math.round(secDto.getLengthFt() * secDto.getWidthFt());
        }

        double totalPrice = area * secPricePerSft;

        FlatSection section = FlatSection.builder()
                .flatId(flatId)
                .sectionName(secDto.getSectionName().trim())
                .sectionImageUrl(secDto.getSectionImageUrl() != null ? secDto.getSectionImageUrl() : "assets/images/apartment_poster.jpg")
                .description(secDto.getDescription())
                .areaSft(area)
                .lengthFt(secDto.getLengthFt())
                .widthFt(secDto.getWidthFt())
                .pricePerSft(secPricePerSft)
                .totalPrice(totalPrice)
                .giftedSft(0)
                .svgElementId(secDto.getSvgElementId() != null ? secDto.getSvgElementId() : "sec_" + System.currentTimeMillis())
                .build();

        FlatSection saved = flatSectionRepository.save(section);
        flat.setUpdatedAt(LocalDateTime.now());
        flatRepository.save(flat);

        return toSectionDto(saved, flat.getBricksPerSft());
    }

    /**
     * Dynamic Section Management: Update a section
     */
    @Transactional
    public FlatSectionDto updateSection(Long flatId, Long sectionId, FlatSectionDto secDto) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        FlatSection section = flatSectionRepository.findById(sectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Section not found with id: " + sectionId));

        if (!Objects.equals(section.getFlatId(), flatId)) {
            throw new ConflictException("Section does not belong to flat " + flatId);
        }

        if (secDto.getSectionName() != null) section.setSectionName(secDto.getSectionName().trim());
        if (secDto.getSectionImageUrl() != null) section.setSectionImageUrl(secDto.getSectionImageUrl());
        if (secDto.getDescription() != null) section.setDescription(secDto.getDescription());
        if (secDto.getLengthFt() != null) section.setLengthFt(secDto.getLengthFt());
        if (secDto.getWidthFt() != null) section.setWidthFt(secDto.getWidthFt());

        if (secDto.getAreaSft() != null && secDto.getAreaSft() > 0) {
            section.setAreaSft(secDto.getAreaSft());
        } else if (secDto.getLengthFt() != null && secDto.getWidthFt() != null) {
            section.setAreaSft((int) Math.round(secDto.getLengthFt() * secDto.getWidthFt()));
        }

        if (secDto.getPricePerSft() != null && secDto.getPricePerSft() > 0) {
            section.setPricePerSft(secDto.getPricePerSft());
        }

        section.setTotalPrice(section.getAreaSft() * section.getPricePerSft());

        FlatSection saved = flatSectionRepository.save(section);
        flat.setUpdatedAt(LocalDateTime.now());
        flatRepository.save(flat);

        return toSectionDto(saved, flat.getBricksPerSft());
    }

    /**
     * Dynamic Section Management: Remove a section
     */
    @Transactional
    public void deleteSection(Long flatId, Long sectionId) {
        FlatSection section = flatSectionRepository.findById(sectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Section not found with id: " + sectionId));

        if (!Objects.equals(section.getFlatId(), flatId)) {
            throw new ConflictException("Section does not belong to flat " + flatId);
        }

        if (section.getGiftedSft() != null && section.getGiftedSft() > 0) {
            throw new ConflictException("Cannot remove section '" + section.getSectionName() + "' because guests have already gifted " + section.getGiftedSft() + " sq. ft. toward it.");
        }

        flatSectionRepository.delete(section);
    }

    /**
     * Workflow Step 4: Submit for Approval
     */
    @Transactional
    public FlatDto submitForApproval(Long flatId) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        List<FlatSection> sections = flatSectionRepository.findByFlatIdOrderByIdAsc(flatId);
        if (sections.isEmpty()) {
            throw new ConflictException("Cannot submit flat for approval: at least one section must be configured.");
        }

        int totalSecArea = sections.stream().mapToInt(FlatSection::getAreaSft).sum();
        if (totalSecArea != flat.getBuiltUpAreaSft()) {
            throw new ConflictException("Area validation warning: Sum of sections (" + totalSecArea + " Sq. Ft.) does not match declared total built-up area (" + flat.getBuiltUpAreaSft() + " Sq. Ft.). Please adjust section areas before submission.");
        }

        flat.setStatus(FlatStatus.PENDING_APPROVAL);
        flat.setUpdatedAt(LocalDateTime.now());
        return toDto(flatRepository.save(flat));
    }

    /**
     * Workflow Step 7: Approve Flat (Validates all section area sums & pricing)
     */
    @Transactional
    public FlatDto approveFlat(Long flatId, Long adminId) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        List<FlatSection> sections = flatSectionRepository.findByFlatIdOrderByIdAsc(flatId);
        if (sections.isEmpty()) {
            throw new ConflictException("Cannot approve flat: No sections configured. Please add sections first.");
        }

        int totalSecArea = sections.stream().mapToInt(FlatSection::getAreaSft).sum();
        if (totalSecArea != flat.getBuiltUpAreaSft()) {
            throw new ConflictException("Approval blocked: Sum of section areas (" + totalSecArea + " Sq. Ft.) does not equal declared built-up area (" + flat.getBuiltUpAreaSft() + " Sq. Ft.). All validations must pass before approval.");
        }

        flat.setStatus(FlatStatus.APPROVED);
        flat.setApprovedAt(LocalDateTime.now());
        flat.setApprovedByAdminId(adminId != null ? adminId : 1L);
        flat.setRejectionReason(null);
        flat.setUpdatedAt(LocalDateTime.now());

        return toDto(flatRepository.save(flat));
    }

    /**
     * Workflow: Reject Flat with Reason
     */
    @Transactional
    public FlatDto rejectFlat(Long flatId, String reason) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        flat.setStatus(FlatStatus.DRAFT);
        flat.setRejectionReason(reason != null ? reason : "Section area mismatch or missing documentation");
        flat.setUpdatedAt(LocalDateTime.now());

        return toDto(flatRepository.save(flat));
    }

    /**
     * Workflow Step 8: Assign Approved Flat to Wedding
     */
    @Transactional
    public FlatDto assignFlatToWedding(Long flatId, Long weddingId) {
        Flat flat = flatRepository.findById(flatId)
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + flatId));

        if (flat.getStatus() != FlatStatus.APPROVED && flat.getStatus() != FlatStatus.ASSIGNED) {
            throw new ConflictException("Only approved flats can be assigned to weddings. Current status: " + flat.getStatus());
        }

        Wedding wedding = weddingRepository.findById(weddingId)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with id: " + weddingId));

        // Check if flat is already assigned to a DIFFERENT active wedding
        if (flat.getAssignedWeddingId() != null && !Objects.equals(flat.getAssignedWeddingId(), weddingId)) {
            throw new ConflictException("Flat " + flat.getFlatId() + " is already assigned to wedding #" + flat.getAssignedWeddingId() + " (" + flat.getAssignedWeddingSlug() + ")");
        }

        flat.setAssignedWeddingId(wedding.getId());
        flat.setAssignedWeddingSlug(wedding.getSlug());
        flat.setStatus(FlatStatus.ASSIGNED);
        flat.setUpdatedAt(LocalDateTime.now());
        Flat saved = flatRepository.save(flat);

        // Synchronize wedding target SFT and rate
        wedding.setTargetSft(flat.getBuiltUpAreaSft());
        wedding.setRateSft(flat.getPricePerSft());
        wedding.setStatus(WeddingStatus.ACTIVE);
        weddingRepository.save(wedding);

        // Sync sections to FloorPlanZones so interactive grid and mobile views reflect the new flat sections!
        List<FlatSection> sections = flatSectionRepository.findByFlatIdOrderByIdAsc(flatId);
        List<FloorPlanZone> existingZones = floorPlanZoneRepository.findByWeddingId(wedding.getId());
        if (existingZones.isEmpty()) {
            for (FlatSection sec : sections) {
                floorPlanZoneRepository.save(FloorPlanZone.builder()
                        .weddingId(wedding.getId())
                        .roomName(sec.getSectionName())
                        .totalSft(sec.getAreaSft())
                        .fundedSft(sec.getGiftedSft())
                        .ratePerSft(sec.getPricePerSft())
                        .svgElementId(sec.getSvgElementId())
                        .build());
            }
        }

        log.info("Assigned flat {} ({}) to wedding {} ({})", flat.getFlatId(), flat.getName(), wedding.getId(), wedding.getSlug());
        return toDto(saved);
    }

    /**
     * DTO mapping with live area summation, brick conversions, and gift progress
     */
    public FlatDto toDto(Flat flat) {
        List<FlatSection> sections = flatSectionRepository.findByFlatIdOrderByIdAsc(flat.getId());
        int bricksPerSft = flat.getBricksPerSft() != null ? flat.getBricksPerSft() : 10;

        List<FlatSectionDto> sectionDtos = new ArrayList<>();
        int totalSecArea = 0;
        int totalGifted = 0;
        double totalGiftedAmt = 0.0;
        double totalTargetAmt = 0.0;

        for (FlatSection s : sections) {
            FlatSectionDto sDto = toSectionDto(s, bricksPerSft);
            sectionDtos.add(sDto);
            totalSecArea += s.getAreaSft();
            totalGifted += (s.getGiftedSft() != null ? s.getGiftedSft() : 0);
            totalGiftedAmt += ((s.getGiftedSft() != null ? s.getGiftedSft() : 0) * s.getPricePerSft());
            totalTargetAmt += s.getTotalPrice();
        }

        List<String> gallery = deserializeList(flat.getGalleryImagesJson());

        boolean matches = (totalSecArea == flat.getBuiltUpAreaSft());
        int remaining = Math.max(0, flat.getBuiltUpAreaSft() - totalGifted);

        return FlatDto.builder()
                .id(flat.getId())
                .flatId(flat.getFlatId())
                .name(flat.getName())
                .description(flat.getDescription())
                .coverImageUrl(flat.getCoverImageUrl())
                .galleryImages(gallery)
                .builtUpAreaSft(flat.getBuiltUpAreaSft())
                .carpetAreaSft(flat.getCarpetAreaSft())
                .bedrooms(flat.getBedrooms())
                .bathrooms(flat.getBathrooms())
                .balconies(flat.getBalconies())
                .halls(flat.getHalls())
                .kitchens(flat.getKitchens())
                .location(flat.getLocation())
                .address(flat.getAddress())
                .pricePerSft(flat.getPricePerSft())
                .bricksPerSft(bricksPerSft)
                .pricePerBrick(flat.getPricePerBrick())
                .status(flat.getStatus())
                .assignedWeddingId(flat.getAssignedWeddingId())
                .assignedWeddingSlug(flat.getAssignedWeddingSlug())
                .rejectionReason(flat.getRejectionReason())
                .sections(sectionDtos)
                .totalSectionArea(totalSecArea)
                .areaMatches(matches)
                .totalGiftedSft(totalGifted)
                .totalRemainingSft(remaining)
                .totalTargetAmount(totalTargetAmt)
                .totalGiftedAmount(totalGiftedAmt)
                .totalBricksEquivalent(flat.getBuiltUpAreaSft() * bricksPerSft)
                .createdAt(flat.getCreatedAt())
                .updatedAt(flat.getUpdatedAt())
                .approvedAt(flat.getApprovedAt())
                .approvedByAdminId(flat.getApprovedByAdminId())
                .build();
    }

    public FlatSectionDto toSectionDto(FlatSection sec, int bricksPerSft) {
        int gifted = (sec.getGiftedSft() != null) ? sec.getGiftedSft() : 0;
        int remaining = Math.max(0, sec.getAreaSft() - gifted);
        double progress = (sec.getAreaSft() > 0) ? ((double) gifted / sec.getAreaSft()) * 100.0 : 0.0;

        return FlatSectionDto.builder()
                .id(sec.getId())
                .flatId(sec.getFlatId())
                .sectionName(sec.getSectionName())
                .sectionImageUrl(sec.getSectionImageUrl())
                .description(sec.getDescription())
                .areaSft(sec.getAreaSft())
                .lengthFt(sec.getLengthFt())
                .widthFt(sec.getWidthFt())
                .pricePerSft(sec.getPricePerSft())
                .totalPrice(sec.getTotalPrice())
                .giftedSft(gifted)
                .remainingSft(remaining)
                .brickEquivalent(sec.getAreaSft() * bricksPerSft)
                .giftProgressPercent(Math.round(progress * 10.0) / 10.0)
                .svgElementId(sec.getSvgElementId())
                .build();
    }
}
