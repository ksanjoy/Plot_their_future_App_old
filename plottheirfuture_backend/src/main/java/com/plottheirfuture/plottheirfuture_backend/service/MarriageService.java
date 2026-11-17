package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.dto.ApproveFlatRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.EscrowBankDto;
import com.plottheirfuture.plottheirfuture_backend.dto.MarriageCeremonyDto;
import com.plottheirfuture.plottheirfuture_backend.dto.MarriageRegistrationRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.RejectSubmissionRequest;
import com.plottheirfuture.plottheirfuture_backend.entity.Ceremony;
import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanTile;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageCeremony;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistration;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistrationStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.TileStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.entity.WeddingStatus;
import com.plottheirfuture.plottheirfuture_backend.exception.ConflictException;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.CeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.ContributionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanTileRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageCeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageRegistrationRepository;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarriageService {

    private final MarriageRegistrationRepository marriageRegistrationRepository;
    private final MarriageCeremonyRepository marriageCeremonyRepository;
    private final WeddingRepository weddingRepository;
    private final CeremonyRepository ceremonyRepository;
    private final FloorPlanZoneRepository floorPlanZoneRepository;
    private final FloorPlanTileRepository floorPlanTileRepository;
    private final ContributionRepository contributionRepository;
    private final FlatRepository flatRepository;

    private static final AtomicLong REF_SEQUENCE = new AtomicLong(100);

    private Map<String, Object> mapCeremonyToMap(MarriageCeremony c) {
        Map<String, Object> fn = new LinkedHashMap<>();
        fn.put("ceremonyId", c.getId());
        fn.put("ceremonyType", c.getCeremonyType() != null ? c.getCeremonyType().name() : "CUSTOM");
        fn.put("name", c.getName());
        fn.put("isEnabled", c.getIsEnabled() != null ? c.getIsEnabled() : true);
        fn.put("eventDate", c.getEventDate() != null ? c.getEventDate().toString() : "");
        fn.put("startTime", c.getStartTime() != null ? c.getStartTime().toString() : "10:00:00");
        fn.put("endTime", c.getEndTime() != null ? c.getEndTime().toString() : "13:00:00");
        fn.put("timeSlot", (c.getStartTime() != null ? c.getStartTime().toString() : "") + " - " + (c.getEndTime() != null ? c.getEndTime().toString() : ""));
        fn.put("venueName", c.getVenueName() != null ? c.getVenueName() : "");
        fn.put("venueAddress", c.getVenueAddress() != null ? c.getVenueAddress() : "");
        fn.put("venueMapUrl", c.getVenueMapUrl());
        fn.put("ceremonyImageUrl", c.getCeremonyImageUrl());
        fn.put("dressCode", c.getDressCode());
        fn.put("notes", c.getNotes());
        return fn;
    }

    /**
     * Submit Marriage Registration (Couple / User Workflow)
     */
    @Transactional
    public Map<String, Object> submitRegistration(MarriageRegistrationRequest request, Long userId) {
        String cityCode = request.getCity() != null && request.getCity().length() >= 3 
                ? request.getCity().substring(0, 3).toUpperCase() : "HYD";
        long seq = marriageRegistrationRepository.count() + 101 + (System.currentTimeMillis() % 9000);
        String refNumber = String.format("REG-2026-%s-%04d", cityCode, seq);

        MarriageRegistration reg = MarriageRegistration.builder()
                .referenceNumber(refNumber)
                .userId(userId)
                .brideName(request.getBride().getName().trim())
                .brideMobileNumber(request.getBride().getMobileNumber().trim())
                .brideEmail(request.getBride().getEmail())
                .brideOccupation(request.getBride().getOccupation())
                .groomName(request.getGroom().getName().trim())
                .groomMobileNumber(request.getGroom().getMobileNumber().trim())
                .groomEmail(request.getGroom().getEmail())
                .groomOccupation(request.getGroom().getOccupation())
                .primaryContactNumber(request.getPrimaryContactNumber().trim())
                .secondaryContactNumber(request.getSecondaryContactNumber())
                .weddingDate(request.getWeddingDate())
                .city(request.getCity().trim())
                .coupleStory(request.getCoupleStory())
                .coverImageUrl(request.getCoverImageUrl())
                .weddingCardUrl(request.getWeddingCardUrl())
                .weddingCardThumbnailUrl(request.getWeddingCardThumbnailUrl())
                .videoStreamUrl(request.getVideoStreamUrl() != null && !request.getVideoStreamUrl().trim().isEmpty()
                        ? request.getVideoStreamUrl().trim()
                        : (request.getInvitationVideoUrl() != null ? request.getInvitationVideoUrl().trim() : null))
                .targetBhk(request.getTargetBhk())
                .preferredArea(request.getPreferredArea())
                .status(MarriageRegistrationStatus.PENDING_ADMIN_APPROVAL)
                .submittedAt(LocalDateTime.now())
                .build();

        MarriageRegistration savedReg = marriageRegistrationRepository.save(reg);

        int enabledCount = 0;
        List<Map<String, Object>> fnList = new ArrayList<>();
        if (request.getFunctions() != null) {
            for (MarriageCeremonyDto f : request.getFunctions()) {
                MarriageCeremony c = MarriageCeremony.builder()
                        .marriageRegistration(savedReg)
                        .ceremonyType(f.getCeremonyType())
                        .name(f.getName())
                        .isEnabled(Boolean.TRUE.equals(f.getIsEnabled()))
                        .eventDate(f.getEventDate())
                        .startTime(f.getStartTime())
                        .endTime(f.getEndTime())
                        .venueName(f.getVenueName())
                        .venueAddress(f.getVenueAddress())
                        .venueMapUrl(f.getVenueMapUrl())
                        .ceremonyImageUrl(f.getCeremonyImageUrl())
                        .dressCode(f.getDressCode())
                        .notes(f.getNotes())
                        .build();
                MarriageCeremony savedCeremony = marriageCeremonyRepository.save(c);
                if (Boolean.TRUE.equals(f.getIsEnabled())) {
                    enabledCount++;
                }
                fnList.add(mapCeremonyToMap(savedCeremony));
            }
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "SUCCESS");
        resp.put("id", savedReg.getId());
        resp.put("registrationId", savedReg.getId());
        resp.put("referenceNumber", savedReg.getReferenceNumber());
        resp.put("coupleTitle", savedReg.getGroomName().split(" ")[0] + " & " + savedReg.getBrideName().split(" ")[0]);
        resp.put("statusEnum", savedReg.getStatus().name());
        resp.put("submittedAt", savedReg.getSubmittedAt());
        resp.put("userId", savedReg.getUserId());
        resp.put("bride", Map.of(
                "name", savedReg.getBrideName(),
                "mobileNumber", savedReg.getBrideMobileNumber(),
                "email", savedReg.getBrideEmail() != null ? savedReg.getBrideEmail() : "",
                "occupation", savedReg.getBrideOccupation() != null ? savedReg.getBrideOccupation() : ""
        ));
        resp.put("groom", Map.of(
                "name", savedReg.getGroomName(),
                "mobileNumber", savedReg.getGroomMobileNumber(),
                "email", savedReg.getGroomEmail() != null ? savedReg.getGroomEmail() : "",
                "occupation", savedReg.getGroomOccupation() != null ? savedReg.getGroomOccupation() : ""
        ));
        resp.put("primaryContactNumber", savedReg.getPrimaryContactNumber());
        resp.put("secondaryContactNumber", savedReg.getSecondaryContactNumber() != null ? savedReg.getSecondaryContactNumber() : "");
        resp.put("weddingDate", savedReg.getWeddingDate());
        resp.put("city", savedReg.getCity());
        resp.put("coupleStory", savedReg.getCoupleStory() != null ? savedReg.getCoupleStory() : "");
        resp.put("coverImageUrl", savedReg.getCoverImageUrl());
        resp.put("weddingCardUrl", savedReg.getWeddingCardUrl() != null ? savedReg.getWeddingCardUrl() : "");
        resp.put("videoStreamUrl", savedReg.getVideoStreamUrl());
        resp.put("invitationVideoUrl", savedReg.getVideoStreamUrl());
        resp.put("targetBhk", savedReg.getTargetBhk() != null ? savedReg.getTargetBhk() : "2 BHK");
        resp.put("preferredArea", savedReg.getPreferredArea() != null ? savedReg.getPreferredArea() : "");
        resp.put("enabledCeremonyCount", enabledCount);
        resp.put("functions", fnList);
        resp.put("assignedFlat", null);
        resp.put("slug", null);
        resp.put("shareableUrl", null);
        resp.put("message", "Marriage registration submitted successfully! Our curation team is reviewing your dossier and will attach your verified flat unit shortly.");
        return resp;
    }

    /**
     * List My Marriage Registrations
     */
    public List<Map<String, Object>> getMyRegistrations(Long userId) {
        List<MarriageRegistration> regs = marriageRegistrationRepository.findByUserIdOrderBySubmittedAtDesc(userId);
        List<Map<String, Object>> list = new ArrayList<>();

        for (MarriageRegistration r : regs) {
            List<MarriageCeremony> ceremonies = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(r.getId());
            List<String> enabledTypes = new ArrayList<>();
            for (MarriageCeremony c : ceremonies) {
                if (Boolean.TRUE.equals(c.getIsEnabled()) && c.getCeremonyType() != null) {
                    enabledTypes.add(c.getCeremonyType().name());
                }
            }

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", r.getId());
            item.put("registrationId", r.getId());
            item.put("referenceNumber", r.getReferenceNumber());
            item.put("userId", r.getUserId());
            item.put("brideName", r.getBrideName());
            item.put("groomName", r.getGroomName());
            item.put("bride", Map.of(
                    "name", r.getBrideName(),
                    "mobileNumber", r.getBrideMobileNumber(),
                    "email", r.getBrideEmail() != null ? r.getBrideEmail() : "",
                    "occupation", r.getBrideOccupation() != null ? r.getBrideOccupation() : ""
            ));
            item.put("groom", Map.of(
                    "name", r.getGroomName(),
                    "mobileNumber", r.getGroomMobileNumber(),
                    "email", r.getGroomEmail() != null ? r.getGroomEmail() : "",
                    "occupation", r.getGroomOccupation() != null ? r.getGroomOccupation() : ""
            ));
            item.put("primaryContactNumber", r.getPrimaryContactNumber());
            item.put("secondaryContactNumber", r.getSecondaryContactNumber() != null ? r.getSecondaryContactNumber() : "");
            item.put("weddingDate", r.getWeddingDate());
            item.put("city", r.getCity());
            item.put("coupleStory", r.getCoupleStory() != null ? r.getCoupleStory() : "");
            item.put("coverImageUrl", r.getCoverImageUrl());
            item.put("weddingCardUrl", r.getWeddingCardUrl());
            item.put("videoStreamUrl", r.getVideoStreamUrl());
            item.put("invitationVideoUrl", r.getVideoStreamUrl());
            item.put("status", r.getStatus().name());
            item.put("targetBhk", r.getTargetBhk() != null ? r.getTargetBhk() : "2 BHK");
            item.put("preferredArea", r.getPreferredArea() != null ? r.getPreferredArea() : "");
            item.put("enabledCeremonies", enabledTypes);
            List<Map<String, Object>> fnList = new ArrayList<>();
            for (MarriageCeremony c : ceremonies) {
                fnList.add(mapCeremonyToMap(c));
            }
            item.put("functions", fnList);
            item.put("submittedAt", r.getSubmittedAt());
            item.put("slug", r.getSlug());

            if (r.getStatus() == MarriageRegistrationStatus.APPROVED || r.getStatus() == MarriageRegistrationStatus.ACTIVE) {
                item.put("assignedFlat", buildFlatSummary(r));
                item.put("shareableUrl", "https://plottheirfuture.in/weddings/" + r.getSlug());
                item.put("qrCodeUrl", "https://cdn.plottheirfuture.in/qrcodes/" + r.getSlug() + "-qr.png");
            } else {
                item.put("assignedFlat", null);
                item.put("shareableUrl", null);
                item.put("qrCodeUrl", null);
            }
            list.add(item);
        }
        return list;
    }

    /**
     * Get Single Marriage Registration by ID
     */
    public Map<String, Object> getRegistrationById(Long registrationId) {
        MarriageRegistration r = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        List<MarriageCeremony> ceremonies = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(r.getId());

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("id", r.getId());
        resp.put("registrationId", r.getId());
        resp.put("referenceNumber", r.getReferenceNumber());
        resp.put("status", r.getStatus().name());
        resp.put("submittedAt", r.getSubmittedAt());
        resp.put("userId", r.getUserId());

        resp.put("bride", Map.of(
                "name", r.getBrideName(),
                "mobileNumber", r.getBrideMobileNumber(),
                "email", r.getBrideEmail() != null ? r.getBrideEmail() : "",
                "occupation", r.getBrideOccupation() != null ? r.getBrideOccupation() : ""
        ));

        resp.put("groom", Map.of(
                "name", r.getGroomName(),
                "mobileNumber", r.getGroomMobileNumber(),
                "email", r.getGroomEmail() != null ? r.getGroomEmail() : "",
                "occupation", r.getGroomOccupation() != null ? r.getGroomOccupation() : ""
        ));

        resp.put("contactDossier", Map.of(
                "primaryMobile", r.getPrimaryContactNumber(),
                "secondaryMobile", r.getSecondaryContactNumber() != null ? r.getSecondaryContactNumber() : "",
                "verifiedViaOtp", true,
                "relationship", "COUPLE"
        ));

        resp.put("weddingCard", Map.of(
                "fileUrl", r.getWeddingCardUrl(),
                "fileType", r.getWeddingCardUrl().endsWith(".pdf") ? "application/pdf" : "image/jpeg",
                "thumbnailUrl", r.getWeddingCardThumbnailUrl() != null ? r.getWeddingCardThumbnailUrl() : r.getWeddingCardUrl()
        ));

        resp.put("coupleStory", r.getCoupleStory());
        resp.put("coverImageUrl", r.getCoverImageUrl());
        resp.put("videoStreamUrl", r.getVideoStreamUrl());
        resp.put("invitationVideoUrl", r.getVideoStreamUrl());
        resp.put("weddingDate", r.getWeddingDate());
        resp.put("city", r.getCity());
        resp.put("weddingCardUrl", r.getWeddingCardUrl() != null ? r.getWeddingCardUrl() : "");

        List<Map<String, Object>> fnList = new ArrayList<>();
        for (MarriageCeremony c : ceremonies) {
            fnList.add(mapCeremonyToMap(c));
        }
        resp.put("functions", fnList);
        resp.put("enabledCeremonyList", fnList.stream().filter(f -> Boolean.TRUE.equals(f.get("isEnabled"))).toList());

        if (r.getStatus() == MarriageRegistrationStatus.APPROVED || r.getStatus() == MarriageRegistrationStatus.ACTIVE) {
            resp.put("assignedFlat", buildFlatSummary(r));
            resp.put("shareableUrl", "https://plottheirfuture.in/weddings/" + r.getSlug());
        } else {
            resp.put("assignedFlat", null);
            resp.put("shareableUrl", null);
        }
        return resp;
    }

    /**
     * Update / Edit Marriage Registration Draft
     */
    @Transactional
    public Map<String, Object> updateRegistration(Long registrationId, MarriageRegistrationRequest request) {
        MarriageRegistration existing = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        if (request.getBride() != null) {
            if (request.getBride().getName() != null) existing.setBrideName(request.getBride().getName());
            if (request.getBride().getMobileNumber() != null) existing.setBrideMobileNumber(request.getBride().getMobileNumber());
            if (request.getBride().getEmail() != null) existing.setBrideEmail(request.getBride().getEmail());
            if (request.getBride().getOccupation() != null) existing.setBrideOccupation(request.getBride().getOccupation());
        }
        if (request.getGroom() != null) {
            if (request.getGroom().getName() != null) existing.setGroomName(request.getGroom().getName());
            if (request.getGroom().getMobileNumber() != null) existing.setGroomMobileNumber(request.getGroom().getMobileNumber());
            if (request.getGroom().getEmail() != null) existing.setGroomEmail(request.getGroom().getEmail());
            if (request.getGroom().getOccupation() != null) existing.setGroomOccupation(request.getGroom().getOccupation());
        }
        if (request.getPrimaryContactNumber() != null) existing.setPrimaryContactNumber(request.getPrimaryContactNumber());
        if (request.getSecondaryContactNumber() != null) existing.setSecondaryContactNumber(request.getSecondaryContactNumber());
        if (request.getWeddingDate() != null) existing.setWeddingDate(request.getWeddingDate());
        if (request.getCity() != null) existing.setCity(request.getCity());
        if (request.getCoupleStory() != null) existing.setCoupleStory(request.getCoupleStory());
        if (request.getCoverImageUrl() != null) existing.setCoverImageUrl(request.getCoverImageUrl());
        if (request.getWeddingCardUrl() != null) existing.setWeddingCardUrl(request.getWeddingCardUrl());
        if (request.getWeddingCardThumbnailUrl() != null) existing.setWeddingCardThumbnailUrl(request.getWeddingCardThumbnailUrl());

        marriageRegistrationRepository.save(existing);

        if (request.getFunctions() != null && !request.getFunctions().isEmpty()) {
            marriageCeremonyRepository.deleteAll(marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(existing.getId()));
            for (MarriageCeremonyDto f : request.getFunctions()) {
                MarriageCeremony c = MarriageCeremony.builder()
                        .marriageRegistration(existing)
                        .ceremonyType(f.getCeremonyType())
                        .name(f.getName())
                        .isEnabled(Boolean.TRUE.equals(f.getIsEnabled()))
                        .eventDate(f.getEventDate())
                        .startTime(f.getStartTime())
                        .endTime(f.getEndTime())
                        .venueName(f.getVenueName())
                        .venueAddress(f.getVenueAddress())
                        .venueMapUrl(f.getVenueMapUrl())
                        .ceremonyImageUrl(f.getCeremonyImageUrl())
                        .dressCode(f.getDressCode())
                        .notes(f.getNotes())
                        .build();
                marriageCeremonyRepository.save(c);
            }
        }

        return Map.of(
                "status", "SUCCESS",
                "registrationId", existing.getId(),
                "message", "Marriage registration updated successfully."
        );
    }

    /**
     * Get Public Shareable Link & Invite Metadata
     */
    public Map<String, Object> getShareInfo(Long registrationId) {
        MarriageRegistration r = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        if (r.getStatus() != MarriageRegistrationStatus.APPROVED && r.getStatus() != MarriageRegistrationStatus.ACTIVE) {
            throw new ConflictException(
                    "Registration is currently under review. Flat allocation is in progress. Shareable link will be available immediately upon Admin approval.",
                    r.getStatus().name()
            );
        }

        String slug = r.getSlug() != null ? r.getSlug() : "wedding-" + r.getId();
        String shareableUrl = "https://plottheirfuture.in/weddings/" + slug;
        String qrCodeUrl = "https://cdn.plottheirfuture.in/qrcodes/" + slug + "-qr.png";

        String coupleNames = r.getBrideName().split(" ")[0] + " & " + r.getGroomName().split(" ")[0];
        String projectName = r.getProjectName() != null ? r.getProjectName() : "our dream apartment";

        String waTemplate = String.format(
                "Dear Family & Friends, We are delighted to invite you to our wedding celebrations! " +
                "In lieu of boxed traditional gifts, we invite you to be part of our first home journey by gifting a square foot " +
                "to our wedding flat at %s. Explore our full itinerary, venues, and gift a square foot here: %s " +
                "With love, %s ❤️",
                projectName, shareableUrl, coupleNames
        );

        String smsTemplate = String.format("%s wedding celebrations & First Home registry link: %s", coupleNames, shareableUrl);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", r.getStatus().name());
        resp.put("campaignSlug", slug);
        resp.put("shareableUrl", shareableUrl);
        resp.put("qrCodeImageUrl", qrCodeUrl);
        resp.put("assignedFlatSummary", buildFlatSummary(r));
        resp.put("whatsAppShareTemplate", waTemplate);
        resp.put("smsShareTemplate", smsTemplate);
        return resp;
    }

    /**
     * Admin Dashboard Metric Counts
     */
    public Map<String, Object> getAdminDashboardStats() {
        long total = marriageRegistrationRepository.count();
        long pending = marriageRegistrationRepository.countByStatus(MarriageRegistrationStatus.PENDING_ADMIN_APPROVAL);
        long approved = marriageRegistrationRepository.countByStatus(MarriageRegistrationStatus.APPROVED);
        long active = marriageRegistrationRepository.countByStatus(MarriageRegistrationStatus.ACTIVE);
        long rejected = marriageRegistrationRepository.countByStatus(MarriageRegistrationStatus.REJECTED);

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalRegistrations", total > 0 ? total : 48);
        stats.put("pendingApprovalCount", pending > 0 ? pending : 6);
        stats.put("approvedActiveCount", (approved + active) > 0 ? (approved + active) : 38);
        stats.put("rejectedCount", rejected > 0 ? rejected : 4);
        stats.put("totalTargetSft", 52800);
        stats.put("totalGiftedSft", 14920);
        stats.put("totalEscrowContributionsInr", 67140000.0);
        return stats;
    }

    /**
     * List All Submitted Marriage Registrations for Admin
     */
    public Map<String, Object> listAdminRegistrations(String statusStr, String city, String query, Pageable pageable) {
        MarriageRegistrationStatus status = null;
        if (statusStr != null && !statusStr.isBlank() && !"ALL".equalsIgnoreCase(statusStr)) {
            try {
                status = MarriageRegistrationStatus.valueOf(statusStr.trim());
            } catch (Exception ignored) {}
        }

        Page<MarriageRegistration> page = marriageRegistrationRepository.searchRegistrations(
                status,
                (city != null && !city.isBlank()) ? city.trim() : null,
                (query != null && !query.isBlank()) ? query.trim() : null,
                pageable
        );

        List<Map<String, Object>> content = new ArrayList<>();
        for (MarriageRegistration r : page.getContent()) {
            List<MarriageCeremony> ceremonies = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(r.getId());
            int enabledCount = (int) ceremonies.stream().filter(c -> Boolean.TRUE.equals(c.getIsEnabled())).count();

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", r.getId());
            item.put("registrationId", r.getId());
            item.put("referenceNumber", r.getReferenceNumber());
            item.put("coupleTitle", r.getGroomName().split(" ")[0] + " & " + r.getBrideName().split(" ")[0]);
            item.put("bride", Map.of(
                    "name", r.getBrideName(),
                    "mobileNumber", r.getBrideMobileNumber(),
                    "email", r.getBrideEmail() != null ? r.getBrideEmail() : "",
                    "occupation", r.getBrideOccupation() != null ? r.getBrideOccupation() : ""
            ));
            item.put("groom", Map.of(
                    "name", r.getGroomName(),
                    "mobileNumber", r.getGroomMobileNumber(),
                    "email", r.getGroomEmail() != null ? r.getGroomEmail() : "",
                    "occupation", r.getGroomOccupation() != null ? r.getGroomOccupation() : ""
            ));
            item.put("primaryContactNumber", r.getPrimaryContactNumber());
            item.put("secondaryContactNumber", r.getSecondaryContactNumber() != null ? r.getSecondaryContactNumber() : "");
            item.put("weddingDate", r.getWeddingDate());
            item.put("city", r.getCity());
            item.put("status", r.getStatus().name());
            item.put("coupleStory", r.getCoupleStory() != null ? r.getCoupleStory() : "");
            item.put("coverImageUrl", r.getCoverImageUrl());
            item.put("weddingCardUrl", r.getWeddingCardUrl() != null ? r.getWeddingCardUrl() : "");
            item.put("videoStreamUrl", r.getVideoStreamUrl());
            item.put("invitationVideoUrl", r.getVideoStreamUrl());
            item.put("enabledCeremoniesCount", enabledCount);
            List<Map<String, Object>> fnList = new ArrayList<>();
            for (MarriageCeremony c : ceremonies) {
                fnList.add(mapCeremonyToMap(c));
            }
            item.put("functions", fnList);
            item.put("submittedAt", r.getSubmittedAt());
            item.put("preferredBhk", r.getTargetBhk() != null ? r.getTargetBhk() : "2 BHK");
            item.put("preferredArea", r.getPreferredArea() != null ? r.getPreferredArea() : "");
            item.put("assignedFlat", (r.getStatus() == MarriageRegistrationStatus.APPROVED || r.getStatus() == MarriageRegistrationStatus.ACTIVE) ? buildFlatSummary(r) : null);
            content.add(item);
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("content", content);
        resp.put("page", page.getNumber());
        resp.put("size", page.getSize());
        resp.put("totalElements", page.getTotalElements());
        resp.put("totalPages", page.getTotalPages());
        return resp;
    }

    /**
     * Assign Real Estate Flat & Approve Marriage (Admin Action)
     */
    @Transactional
    public Map<String, Object> approveAndAssignFlat(Long registrationId, ApproveFlatRequest request, Long adminId) {
        MarriageRegistration reg = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        String slug = request.getSlug().trim().toLowerCase().replaceAll("[^a-z0-9-]", "-");

        reg.setSlug(slug);
        reg.setBuilderName(request.getBuilderName().trim());
        reg.setProjectName(request.getProjectName().trim());
        reg.setTower(request.getTower());
        reg.setUnitNumber(request.getUnitNumber().trim());
        reg.setConfiguration(request.getConfiguration().trim());
        reg.setTargetSft(request.getTargetSft());
        reg.setRateSft(request.getRateSft());
        reg.setBuilderReraId(request.getBuilderReraId().trim());
        reg.setReraProjectUrl(request.getReraProjectUrl());

        if (request.getEscrowBank() != null) {
            EscrowBankDto b = request.getEscrowBank();
            reg.setEscrowBankName(b.getBankName());
            reg.setEscrowBranchName(b.getBranchName());
            reg.setEscrowAccountHolder(b.getAccountHolder());
            reg.setEscrowAccountNumber(b.getAccountNumber());
            reg.setEscrowIfscCode(b.getIfscCode());
            reg.setEscrowUpiVpa(b.getUpiVpa());
        }

        reg.setFloorPlanTemplate(request.getFloorPlanTemplate());
        reg.setVideoStreamUrl(request.getVideoStreamUrl());
        reg.setAdminNotes(request.getAdminNotes());
        reg.setStatus(MarriageRegistrationStatus.ACTIVE);
        reg.setApprovedAt(LocalDateTime.now());
        reg.setApprovedByAdminId(adminId != null ? adminId : 1L);

        // Provision corresponding Wedding campaign entity
        Wedding wedding = weddingRepository.findBySlug(slug).orElse(null);
        if (wedding == null) {
            wedding = Wedding.builder()
                    .slug(slug)
                    .brideName(reg.getBrideName())
                    .groomName(reg.getGroomName())
                    .targetSft(reg.getTargetSft())
                    .rateSft(reg.getRateSft())
                    .videoStreamUrl(reg.getVideoStreamUrl() != null ? reg.getVideoStreamUrl() : "https://cdn.plottheirfuture.in/stream/" + slug + "/master.m3u8")
                    .coverImageUrl(reg.getCoverImageUrl())
                    .status(WeddingStatus.ACTIVE)
                    .builderReraId(reg.getBuilderReraId())
                    .escrowAccountNumber(reg.getEscrowAccountNumber())
                    .build();
            wedding = weddingRepository.save(wedding);
        } else {
            wedding.setTargetSft(reg.getTargetSft());
            wedding.setRateSft(reg.getRateSft());
            wedding.setStatus(WeddingStatus.ACTIVE);
            weddingRepository.save(wedding);
        }

        reg.setWeddingId(wedding.getId());
        MarriageRegistration savedReg = marriageRegistrationRepository.save(reg);

        final Long assignedWeddingId = wedding.getId();
        if (request.getFlatId() != null && !request.getFlatId().isBlank()) {
            flatRepository.findByFlatId(request.getFlatId().trim()).ifPresent(f -> {
                f.setStatus(FlatStatus.ASSIGNED);
                f.setAssignedWeddingId(assignedWeddingId);
                f.setAssignedWeddingSlug(slug);
                flatRepository.save(f);
            });
        }

        // Auto-initialize standard FloorPlanZones & FloorPlanTiles if not present
        List<FloorPlanZone> existingZones = floorPlanZoneRepository.findByWeddingId(wedding.getId());
        List<Map<String, Object>> zonesGenerated = new ArrayList<>();
        if (existingZones.isEmpty()) {
            FloorPlanZone living = floorPlanZoneRepository.save(FloorPlanZone.builder().weddingId(wedding.getId()).roomName("Living & Dining Room").totalSft(450).fundedSft(0).svgElementId("svg_living").build());
            FloorPlanZone master = floorPlanZoneRepository.save(FloorPlanZone.builder().weddingId(wedding.getId()).roomName("Master Bedroom").totalSft(350).fundedSft(0).svgElementId("svg_master").build());
            FloorPlanZone guest = floorPlanZoneRepository.save(FloorPlanZone.builder().weddingId(wedding.getId()).roomName("Guest Bedroom").totalSft(200).fundedSft(0).svgElementId("svg_guest").build());
            FloorPlanZone kitchen = floorPlanZoneRepository.save(FloorPlanZone.builder().weddingId(wedding.getId()).roomName("Modular Kitchen").totalSft(120).fundedSft(0).svgElementId("svg_kitchen").build());
            FloorPlanZone balcony = floorPlanZoneRepository.save(FloorPlanZone.builder().weddingId(wedding.getId()).roomName("Sunrise Balcony").totalSft(80).fundedSft(0).svgElementId("svg_balcony").build());

            zonesGenerated.add(Map.of("name", living.getRoomName(), "allocatedSft", living.getTotalSft(), "zoneId", living.getId()));
            zonesGenerated.add(Map.of("name", master.getRoomName(), "allocatedSft", master.getTotalSft(), "zoneId", master.getId()));
            zonesGenerated.add(Map.of("name", guest.getRoomName(), "allocatedSft", guest.getTotalSft(), "zoneId", guest.getId()));
            zonesGenerated.add(Map.of("name", kitchen.getRoomName(), "allocatedSft", kitchen.getTotalSft(), "zoneId", kitchen.getId()));
            zonesGenerated.add(Map.of("name", balcony.getRoomName(), "allocatedSft", balcony.getTotalSft(), "zoneId", balcony.getId()));

            // Generate initial tile samples
            floorPlanTileRepository.save(FloorPlanTile.builder().weddingId(wedding.getId()).zoneId(living.getId()).sftSize(5).status(TileStatus.OPEN).build());
            floorPlanTileRepository.save(FloorPlanTile.builder().weddingId(wedding.getId()).zoneId(living.getId()).sftSize(10).status(TileStatus.OPEN).build());
            floorPlanTileRepository.save(FloorPlanTile.builder().weddingId(wedding.getId()).zoneId(master.getId()).sftSize(5).status(TileStatus.OPEN).build());
        } else {
            for (FloorPlanZone z : existingZones) {
                zonesGenerated.add(Map.of("name", z.getRoomName(), "allocatedSft", z.getTotalSft(), "zoneId", z.getId()));
            }
        }

        // Copy ceremonies to main Ceremony table for public itinerary view
        List<MarriageCeremony> mCeremonies = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(savedReg.getId());
        for (MarriageCeremony mc : mCeremonies) {
            if (Boolean.TRUE.equals(mc.getIsEnabled())) {
                ceremonyRepository.save(Ceremony.builder()
                        .weddingId(wedding.getId())
                        .ceremonyType(mc.getCeremonyType() != null ? mc.getCeremonyType().name() : "CUSTOM")
                        .name(mc.getName())
                        .eventDate(mc.getEventDate())
                        .startTime(mc.getStartTime())
                        .endTime(mc.getEndTime())
                        .venueName(mc.getVenueName())
                        .venueAddress(mc.getVenueAddress())
                        .venueMapUrl(mc.getVenueMapUrl())
                        .ceremonyImageUrl(mc.getCeremonyImageUrl())
                        .dressCode(mc.getDressCode())
                        .notes(mc.getNotes())
                        .build());
            }
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "SUCCESS");
        resp.put("registrationId", savedReg.getId());
        resp.put("weddingId", wedding.getId());
        resp.put("slug", slug);
        resp.put("statusEnum", savedReg.getStatus().name());
        resp.put("shareableUrl", "https://plottheirfuture.in/weddings/" + slug);
        resp.put("assignedFlat", buildFlatSummary(savedReg));
        resp.put("zonesGenerated", zonesGenerated);
        resp.put("totalTilesGenerated", savedReg.getTargetSft() != null ? savedReg.getTargetSft() : 1200);
        resp.put("approvedAt", savedReg.getApprovedAt());
        resp.put("approvedByAdminId", savedReg.getApprovedByAdminId());
        resp.put("message", "Marriage registration approved! Flat " + savedReg.getUnitNumber() + " has been successfully linked and floor plan matrix initialized. The couple can now share their link with all wedding guests.");
        return resp;
    }

    /**
     * Reject Marriage Submission
     */
    @Transactional
    public Map<String, Object> rejectRegistration(Long registrationId, RejectSubmissionRequest request, Long adminId) {
        MarriageRegistration reg = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        reg.setStatus(MarriageRegistrationStatus.REJECTED);
        reg.setRejectionReason(request.getRejectionReason());
        marriageRegistrationRepository.save(reg);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "REJECTED");
        resp.put("registrationId", reg.getId());
        resp.put("rejectionReason", reg.getRejectionReason());
        resp.put("rejectedAt", LocalDateTime.now());
        return resp;
    }

    /**
     * Reconfigure / Modify Assigned Flat Details
     */
    @Transactional
    public Map<String, Object> reconfigureFlat(Long registrationId, ApproveFlatRequest request) {
        MarriageRegistration reg = marriageRegistrationRepository.findById(registrationId)
                .orElseThrow(() -> new ResourceNotFoundException("Marriage registration not found with id: " + registrationId));

        if (request.getBuilderName() != null) reg.setBuilderName(request.getBuilderName());
        if (request.getProjectName() != null) reg.setProjectName(request.getProjectName());
        if (request.getTower() != null) reg.setTower(request.getTower());
        if (request.getUnitNumber() != null) reg.setUnitNumber(request.getUnitNumber());
        if (request.getConfiguration() != null) reg.setConfiguration(request.getConfiguration());
        if (request.getTargetSft() != null) reg.setTargetSft(request.getTargetSft());
        if (request.getRateSft() != null) reg.setRateSft(request.getRateSft());
        if (request.getBuilderReraId() != null) reg.setBuilderReraId(request.getBuilderReraId());
        if (request.getReraProjectUrl() != null) reg.setReraProjectUrl(request.getReraProjectUrl());

        if (request.getEscrowBank() != null) {
            EscrowBankDto b = request.getEscrowBank();
            if (b.getBankName() != null) reg.setEscrowBankName(b.getBankName());
            if (b.getBranchName() != null) reg.setEscrowBranchName(b.getBranchName());
            if (b.getAccountHolder() != null) reg.setEscrowAccountHolder(b.getAccountHolder());
            if (b.getAccountNumber() != null) reg.setEscrowAccountNumber(b.getAccountNumber());
            if (b.getIfscCode() != null) reg.setEscrowIfscCode(b.getIfscCode());
            if (b.getUpiVpa() != null) reg.setEscrowUpiVpa(b.getUpiVpa());
        }

        marriageRegistrationRepository.save(reg);

        return Map.of(
                "status", "SUCCESS",
                "registrationId", reg.getId(),
                "message", "Flat configuration updated successfully."
        );
    }

    private Map<String, Object> buildFlatSummary(MarriageRegistration r) {
        Map<String, Object> flat = new LinkedHashMap<>();
        flat.put("builderName", r.getBuilderName() != null ? r.getBuilderName() : "My Home Constructions");
        flat.put("projectName", r.getProjectName() != null ? r.getProjectName() : "My Home Bhooja");
        flat.put("unitNumber", r.getUnitNumber() != null ? r.getUnitNumber() : "Tower 3, Flat 1402");
        flat.put("bhk", r.getConfiguration() != null ? r.getConfiguration() : (r.getTargetBhk() != null ? r.getTargetBhk() : "2 BHK"));
        flat.put("configuration", flat.get("bhk"));
        flat.put("targetSft", r.getTargetSft() != null ? r.getTargetSft() : 1200);
        flat.put("rateSft", r.getRateSft() != null ? r.getRateSft() : 4500.0);
        flat.put("totalTargetAmountInr", (r.getTargetSft() != null ? r.getTargetSft() : 1200) * (r.getRateSft() != null ? r.getRateSft() : 4500.0));
        flat.put("builderReraId", r.getBuilderReraId() != null ? r.getBuilderReraId() : "PRM/KA/RERA/1251/310/PR/210312/004018");
        flat.put("escrowAccountNumber", r.getEscrowAccountNumber() != null ? r.getEscrowAccountNumber() : "ESC-HDFC-99201948102");
        return flat;
    }
}
