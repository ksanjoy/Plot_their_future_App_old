package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.dto.SectionGiftingRequest;
import com.plottheirfuture.plottheirfuture_backend.entity.Contribution;
import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatSection;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.PaymentStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.exception.ConflictException;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.ContributionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatSectionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SectionGiftingService {

    private final WeddingRepository weddingRepository;
    private final FlatRepository flatRepository;
    private final FlatSectionRepository flatSectionRepository;
    private final FloorPlanZoneRepository floorPlanZoneRepository;
    private final ContributionRepository contributionRepository;

    /**
     * Get sections for a wedding microsite page
     */
    public Map<String, Object> getWeddingSections(String slug) {
        Wedding wedding = weddingRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with slug: " + slug));

        Flat flat = flatRepository.findByAssignedWeddingId(wedding.getId())
                .orElseGet(() -> flatRepository.findByAssignedWeddingSlug(slug).orElse(null));

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("weddingId", wedding.getId());
        resp.put("slug", wedding.getSlug());
        resp.put("coupleTitle", wedding.getGroomName() + " & " + wedding.getBrideName());
        resp.put("totalTargetSft", wedding.getTargetSft());

        if (flat != null) {
            resp.put("flatId", flat.getFlatId());
            resp.put("flatName", flat.getName());
            resp.put("location", flat.getLocation());
            resp.put("coverImageUrl", flat.getCoverImageUrl());
            resp.put("bricksPerSft", flat.getBricksPerSft() != null ? flat.getBricksPerSft() : 10);
            resp.put("pricePerSft", flat.getPricePerSft());

            List<FlatSection> sections = flatSectionRepository.findByFlatIdOrderByIdAsc(flat.getId());
            int totalGifted = 0;
            int totalArea = 0;
            List<Map<String, Object>> secList = new java.util.ArrayList<>();

            for (FlatSection s : sections) {
                int gifted = (s.getGiftedSft() != null) ? s.getGiftedSft() : 0;
                int remaining = Math.max(0, s.getAreaSft() - gifted);
                double pct = (s.getAreaSft() > 0) ? ((double) gifted / s.getAreaSft()) * 100.0 : 0.0;

                totalGifted += gifted;
                totalArea += s.getAreaSft();

                Map<String, Object> sMap = new LinkedHashMap<>();
                sMap.put("sectionId", s.getId());
                sMap.put("sectionName", s.getSectionName());
                sMap.put("sectionImageUrl", s.getSectionImageUrl());
                sMap.put("description", s.getDescription());
                sMap.put("totalSft", s.getAreaSft());
                sMap.put("giftedSft", gifted);
                sMap.put("remainingSft", remaining);
                sMap.put("pricePerSft", s.getPricePerSft());
                sMap.put("brickEquivalent", remaining * (flat.getBricksPerSft() != null ? flat.getBricksPerSft() : 10));
                sMap.put("progressPercent", Math.round(pct * 10.0) / 10.0);
                secList.add(sMap);
            }

            resp.put("sections", secList);
            resp.put("totalGiftedSft", totalGifted);
            resp.put("totalRemainingSft", Math.max(0, totalArea - totalGifted));
            resp.put("overallProgressPercent", totalArea > 0 ? Math.round(((double) totalGifted / totalArea) * 1000.0) / 10.0 : 0.0);
        } else {
            // Fallback to FloorPlanZones if no explicit flat assigned yet
            List<FloorPlanZone> zones = floorPlanZoneRepository.findByWeddingId(wedding.getId());
            List<Map<String, Object>> secList = new java.util.ArrayList<>();
            int totalGifted = 0;
            int totalArea = 0;

            for (FloorPlanZone z : zones) {
                int gifted = (z.getFundedSft() != null) ? z.getFundedSft() : 0;
                int remaining = Math.max(0, z.getTotalSft() - gifted);
                double pct = (z.getTotalSft() > 0) ? ((double) gifted / z.getTotalSft()) * 100.0 : 0.0;

                totalGifted += gifted;
                totalArea += z.getTotalSft();

                Map<String, Object> zMap = new LinkedHashMap<>();
                zMap.put("sectionId", z.getId());
                zMap.put("sectionName", z.getRoomName());
                zMap.put("sectionImageUrl", "assets/images/apartment_poster.jpg");
                zMap.put("description", z.getRoomName());
                zMap.put("totalSft", z.getTotalSft());
                zMap.put("giftedSft", gifted);
                zMap.put("remainingSft", remaining);
                zMap.put("pricePerSft", z.getRatePerSft() != null ? z.getRatePerSft() : 4500.0);
                zMap.put("brickEquivalent", remaining * 10);
                zMap.put("progressPercent", Math.round(pct * 10.0) / 10.0);
                secList.add(zMap);
            }

            resp.put("sections", secList);
            resp.put("totalGiftedSft", totalGifted);
            resp.put("totalRemainingSft", Math.max(0, totalArea - totalGifted));
            resp.put("overallProgressPercent", totalArea > 0 ? Math.round(((double) totalGifted / totalArea) * 1000.0) / 10.0 : 0.0);
        }

        return resp;
    }

    /**
     * Atomic Section Gifting with Concurrency Protection & Availability Validation
     */
    @Transactional(isolation = Isolation.REPEATABLE_READ)
    public Map<String, Object> giftSection(String slug, SectionGiftingRequest req) {
        Wedding wedding = weddingRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with slug: " + slug));

        FlatSection section = flatSectionRepository.findById(req.getSectionId())
                .orElseThrow(() -> new ResourceNotFoundException("Flat section not found with id: " + req.getSectionId()));

        Flat flat = flatRepository.findById(section.getFlatId())
                .orElseThrow(() -> new ResourceNotFoundException("Flat not found with id: " + section.getFlatId()));

        // Concurrency / Availability check: Never allow gifting more than remaining
        int currentGifted = (section.getGiftedSft() != null) ? section.getGiftedSft() : 0;
        int remaining = section.getAreaSft() - currentGifted;

        if (req.getUnitsSft() > remaining) {
            throw new ConflictException("Cannot gift " + req.getUnitsSft() + " Sq. Ft. Only " + remaining + " Sq. Ft. remaining in " + section.getSectionName() + ".");
        }

        // Recalculate everything strictly on the backend
        int bricksPerSft = (flat.getBricksPerSft() != null && flat.getBricksPerSft() > 0) ? flat.getBricksPerSft() : 10;
        int brickEquivalent = req.getUnitsSft() * bricksPerSft;
        double pricePerSft = section.getPricePerSft();
        double totalAmount = req.getUnitsSft() * pricePerSft;

        String txnId = (req.getPaymentReference() != null && !req.getPaymentReference().isBlank())
                ? req.getPaymentReference().trim()
                : "TXN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // 1. Update section atomically
        section.setGiftedSft(currentGifted + req.getUnitsSft());
        flatSectionRepository.save(section);

        // 2. Record Contribution entity for permanent transaction ledger
        Contribution contrib = Contribution.builder()
                .weddingId(wedding.getId())
                .flatId(flat.getId())
                .sectionId(section.getId())
                .sectionName(section.getSectionName())
                .guestName(req.getGuestName().trim())
                .guestMobile(req.getGuestMobile().trim())
                .guestEmail(req.getGuestEmail() != null ? req.getGuestEmail().trim() : null)
                .unitsSft(req.getUnitsSft())
                .brickEquivalent(brickEquivalent)
                .pricePerSft(pricePerSft)
                .amount(totalAmount)
                .txnId(txnId)
                .bankRef("BANK-REF-" + System.currentTimeMillis())
                .paymentStatus(PaymentStatus.SUCCESS)
                .isAnonymous(Boolean.TRUE.equals(req.getIsAnonymous()))
                .blessingMessage(req.getBlessingMessage())
                .createdAt(LocalDateTime.now())
                .build();

        Contribution savedContrib = contributionRepository.save(contrib);

        // 3. Sync FloorPlanZone funded count if matching zone exists
        List<FloorPlanZone> zones = floorPlanZoneRepository.findByWeddingId(wedding.getId());
        for (FloorPlanZone z : zones) {
            if (z.getRoomName().equalsIgnoreCase(section.getSectionName())) {
                int zFunded = (z.getFundedSft() != null) ? z.getFundedSft() : 0;
                z.setFundedSft(zFunded + req.getUnitsSft());
                floorPlanZoneRepository.save(z);
                break;
            }
        }

        log.info("Guest {} gifted {} Sq. Ft. ({} bricks) in section '{}' for wedding '{}' (Amount: INR {})",
                req.getGuestName(), req.getUnitsSft(), brickEquivalent, section.getSectionName(), wedding.getSlug(), totalAmount);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "SUCCESS");
        resp.put("transactionId", savedContrib.getId());
        resp.put("referenceNumber", txnId);
        resp.put("weddingSlug", wedding.getSlug());
        resp.put("flatName", flat.getName());
        resp.put("sectionName", section.getSectionName());
        resp.put("giftedSft", req.getUnitsSft());
        resp.put("brickEquivalent", brickEquivalent);
        resp.put("ratePerSft", pricePerSft);
        resp.put("amountPaid", totalAmount);
        resp.put("donorName", req.getGuestName());
        resp.put("paymentStatus", "SUCCESS");
        resp.put("timestamp", savedContrib.getCreatedAt());
        resp.put("sectionRemainingSft", section.getRemainingSft());
        resp.put("message", "Congratulations! Your gift of " + req.getUnitsSft() + " Sq. Ft. (" + brickEquivalent + " Bricks) towards " + section.getSectionName() + " has been successfully confirmed.");

        return resp;
    }
}
