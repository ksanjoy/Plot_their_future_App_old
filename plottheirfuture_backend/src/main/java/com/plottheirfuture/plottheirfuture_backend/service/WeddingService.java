package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.Ceremony;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageCeremony;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistration;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistrationStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.entity.WeddingStatus;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.CeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageCeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageRegistrationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class WeddingService {

    private final WeddingRepository weddingRepository;
    private final MarriageRegistrationRepository marriageRegistrationRepository;
    private final MarriageCeremonyRepository marriageCeremonyRepository;
    private final CeremonyRepository ceremonyRepository;
    private final FloorPlanZoneRepository floorPlanZoneRepository;
    private final FloorPlanZoneService floorPlanZoneService;

    // High-concurrency in-memory read cache to absorb 100k+ simultaneous microsite loads
    private final Map<String, Wedding> slugCache = new ConcurrentHashMap<>(1024);
    private final Map<Long, Wedding> idCache = new ConcurrentHashMap<>(1024);

    public List<Wedding> getAllWeddings() {
        return weddingRepository.findAll();
    }

    public Wedding getWeddingById(Long id) {
        Wedding cached = idCache.get(id);
        if (cached != null) return cached;

        Wedding wedding = weddingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with id: " + id));
        idCache.put(id, wedding);
        slugCache.put(wedding.getSlug(), wedding);
        return wedding;
    }

    public Wedding getWeddingBySlug(String slug) {
        Wedding cached = slugCache.get(slug);
        if (cached != null) return cached;

        Wedding wedding = weddingRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with slug: " + slug));
        slugCache.put(slug, wedding);
        idCache.put(wedding.getId(), wedding);
        return wedding;
    }

    public List<Wedding> getWeddingsByStatus(WeddingStatus status) {
        return weddingRepository.findByStatus(status);
    }

    /**
     * Section 5.1: Get Public Wedding Details by Slug
     */
    public Map<String, Object> getPublicWeddingDossier(String slug) {
        MarriageRegistration r = marriageRegistrationRepository.findBySlug(slug).orElse(null);
        Wedding wedding = weddingRepository.findBySlug(slug).orElse(null);

        if (r == null && wedding == null) {
            throw new ResourceNotFoundException("Wedding not found with slug: " + slug);
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        Long weddingId = wedding != null ? wedding.getId() : (r != null ? r.getWeddingId() : null);
        resp.put("id", weddingId != null ? weddingId : (r != null ? r.getId() : 1L));
        resp.put("slug", slug);

        String statusStr = "ACTIVE";
        if (r != null && r.getStatus() != null) {
            statusStr = (r.getStatus() == MarriageRegistrationStatus.APPROVED || r.getStatus() == MarriageRegistrationStatus.ACTIVE) ? "ACTIVE" : r.getStatus().name();
        } else if (wedding != null && wedding.getStatus() != null) {
            statusStr = wedding.getStatus().name();
        }
        resp.put("status", statusStr);

        Map<String, Object> bride = new LinkedHashMap<>();
        bride.put("name", r != null ? r.getBrideName() : (wedding != null ? wedding.getBrideName() : ""));
        bride.put("occupation", r != null && r.getBrideOccupation() != null ? r.getBrideOccupation() : "");
        resp.put("bride", bride);

        Map<String, Object> groom = new LinkedHashMap<>();
        groom.put("name", r != null ? r.getGroomName() : (wedding != null ? wedding.getGroomName() : ""));
        groom.put("occupation", r != null && r.getGroomOccupation() != null ? r.getGroomOccupation() : "");
        resp.put("groom", groom);

        resp.put("coupleStory", r != null && r.getCoupleStory() != null ? r.getCoupleStory() : "");
        resp.put("weddingDate", r != null && r.getWeddingDate() != null ? r.getWeddingDate().toString() : "");
        resp.put("city", r != null && r.getCity() != null ? r.getCity() : "");
        resp.put("coverImageUrl", r != null && r.getCoverImageUrl() != null ? r.getCoverImageUrl() : (wedding != null ? wedding.getCoverImageUrl() : null));
        resp.put("weddingCardUrl", r != null ? r.getWeddingCardUrl() : null);
        resp.put("weddingCardThumbnailUrl", r != null ? r.getWeddingCardThumbnailUrl() : null);
        resp.put("videoStreamUrl", r != null && r.getVideoStreamUrl() != null ? r.getVideoStreamUrl() : (wedding != null ? wedding.getVideoStreamUrl() : null));

        // Flat details
        Map<String, Object> flat = new LinkedHashMap<>();
        flat.put("builderName", r != null && r.getBuilderName() != null ? r.getBuilderName() : "PlotTheirFuture Living");
        flat.put("projectName", r != null && r.getProjectName() != null ? r.getProjectName() : "The Milestone Project");
        String unitNumber = r != null && r.getUnitNumber() != null ? r.getUnitNumber() : "Unit 101";
        if (r != null && r.getTower() != null && !r.getTower().isBlank()) {
            unitNumber += " (" + r.getTower() + ")";
        }
        flat.put("unitNumber", unitNumber);
        flat.put("configuration", r != null && r.getConfiguration() != null ? r.getConfiguration() : "2 BHK");

        int targetSft = r != null && r.getTargetSft() != null ? r.getTargetSft() : (wedding != null && wedding.getTargetSft() != null ? wedding.getTargetSft() : 1200);
        double rateSft = r != null && r.getRateSft() != null ? r.getRateSft() : (wedding != null && wedding.getRateSft() != null ? wedding.getRateSft() : 4500.0);
        flat.put("targetSft", targetSft);
        flat.put("rateSft", rateSft);
        flat.put("totalTargetAmountInr", targetSft * rateSft);

        int fundedSft = 0;
        if (weddingId != null) {
            List<FloorPlanZone> zones = floorPlanZoneRepository.findByWeddingId(weddingId);
            for (FloorPlanZone z : zones) {
                if (z.getFundedSft() != null) fundedSft += z.getFundedSft();
            }
        }
        flat.put("fundedSft", fundedSft);
        double pct = targetSft > 0 ? ((double) fundedSft / targetSft) * 100.0 : 0.0;
        flat.put("fundedPercentage", Math.round(pct * 100.0) / 100.0);
        flat.put("builderReraId", r != null && r.getBuilderReraId() != null ? r.getBuilderReraId() : (wedding != null && wedding.getBuilderReraId() != null ? wedding.getBuilderReraId() : ""));
        flat.put("reraProjectUrl", r != null && r.getReraProjectUrl() != null ? r.getReraProjectUrl() : "https://rera.telangana.gov.in");

        Map<String, Object> escrow = new LinkedHashMap<>();
        escrow.put("bankName", r != null && r.getEscrowBankName() != null ? r.getEscrowBankName() : "HDFC Bank Ltd");
        escrow.put("accountNumber", r != null && r.getEscrowAccountNumber() != null ? r.getEscrowAccountNumber() : (wedding != null && wedding.getEscrowAccountNumber() != null ? wedding.getEscrowAccountNumber() : "ESC-99201948102"));
        escrow.put("ifscCode", r != null && r.getEscrowIfscCode() != null ? r.getEscrowIfscCode() : "HDFC0000456");
        escrow.put("upiVpa", r != null && r.getEscrowUpiVpa() != null ? r.getEscrowUpiVpa() : "plottheirfuture." + slug + "@hdfcbank");
        flat.put("escrowBank", escrow);

        resp.put("flat", flat);

        // Ceremony Summary
        List<Map<String, Object>> ceremonySummary = new ArrayList<>();
        if (r != null) {
            List<MarriageCeremony> mcs = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(r.getId());
            for (MarriageCeremony mc : mcs) {
                if (Boolean.TRUE.equals(mc.getIsEnabled())) {
                    Map<String, Object> cs = new LinkedHashMap<>();
                    cs.put("name", mc.getName());
                    cs.put("date", mc.getEventDate() != null ? mc.getEventDate().toString() : "");
                    cs.put("time", formatTimeAmPm(mc.getStartTime()));
                    ceremonySummary.add(cs);
                }
            }
        } else if (weddingId != null) {
            List<Ceremony> csList = ceremonyRepository.findByWeddingIdOrderByEventDateAscStartTimeAsc(weddingId);
            for (Ceremony c : csList) {
                Map<String, Object> cs = new LinkedHashMap<>();
                cs.put("name", c.getName());
                cs.put("date", c.getEventDate() != null ? c.getEventDate().toString() : "");
                cs.put("time", formatTimeAmPm(c.getStartTime()));
                ceremonySummary.add(cs);
            }
        }
        resp.put("ceremonySummary", ceremonySummary);

        return resp;
    }

    /**
     * Section 5.2: Get Chronological Ceremony Itinerary
     */
    public List<Map<String, Object>> getChronologicalCeremoniesBySlug(String slug) {
        MarriageRegistration r = marriageRegistrationRepository.findBySlug(slug).orElse(null);
        if (r != null) {
            List<MarriageCeremony> mcs = marriageCeremonyRepository.findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(r.getId());
            List<Map<String, Object>> list = new ArrayList<>();
            for (MarriageCeremony mc : mcs) {
                if (Boolean.TRUE.equals(mc.getIsEnabled())) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", mc.getId());
                    m.put("ceremonyType", mc.getCeremonyType() != null ? mc.getCeremonyType().name() : "CUSTOM");
                    m.put("name", mc.getName());
                    m.put("eventDate", mc.getEventDate());
                    m.put("startTime", mc.getStartTime());
                    m.put("endTime", mc.getEndTime());
                    m.put("venueName", mc.getVenueName());
                    m.put("venueAddress", mc.getVenueAddress());
                    m.put("venueMapUrl", mc.getVenueMapUrl());
                    m.put("ceremonyImageUrl", mc.getCeremonyImageUrl());
                    m.put("dressCode", mc.getDressCode());
                    m.put("notes", mc.getNotes());
                    list.add(m);
                }
            }
            return list;
        }

        Wedding wedding = weddingRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Wedding not found with slug: " + slug));

        List<Ceremony> ceremonies = ceremonyRepository.findByWeddingIdOrderByEventDateAscStartTimeAsc(wedding.getId());
        List<Map<String, Object>> list = new ArrayList<>();
        for (Ceremony c : ceremonies) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", c.getId());
            m.put("ceremonyType", c.getCeremonyType() != null ? c.getCeremonyType() : "CUSTOM");
            m.put("name", c.getName());
            m.put("eventDate", c.getEventDate());
            m.put("startTime", c.getStartTime());
            m.put("endTime", c.getEndTime());
            m.put("venueName", c.getVenueName());
            m.put("venueAddress", c.getVenueAddress());
            m.put("venueMapUrl", c.getVenueMapUrl());
            m.put("ceremonyImageUrl", c.getCeremonyImageUrl());
            m.put("dressCode", c.getDressCode());
            m.put("notes", c.getNotes());
            list.add(m);
        }
        return list;
    }

    /**
     * Section 5.3: Get Interactive Floor Plan Grid & Zone Matrix by Slug
     */
    public List<Map<String, Object>> getFloorPlanZonesBySlug(String slug) {
        Wedding wedding = weddingRepository.findBySlug(slug).orElse(null);
        Long weddingId = wedding != null ? wedding.getId() : null;
        if (weddingId == null) {
            MarriageRegistration r = marriageRegistrationRepository.findBySlug(slug).orElse(null);
            if (r != null && r.getWeddingId() != null) {
                weddingId = r.getWeddingId();
            }
        }
        if (weddingId == null) {
            throw new ResourceNotFoundException("Floor plan zones not found for slug: " + slug);
        }
        return floorPlanZoneService.getInteractiveZonesByWeddingId(weddingId);
    }

    /**
     * Section 5.4: WhatsApp / Social Share Preview Metadata
     */
    public Map<String, Object> getSharePreview(String slug) {
        MarriageRegistration r = marriageRegistrationRepository.findBySlug(slug).orElse(null);
        Wedding wedding = weddingRepository.findBySlug(slug).orElse(null);

        if (r == null && wedding == null) {
            throw new ResourceNotFoundException("Wedding not found with slug: " + slug);
        }

        String brideShort = "";
        String groomShort = "";
        if (r != null) {
            brideShort = extractFirstName(r.getBrideName());
            groomShort = extractFirstName(r.getGroomName());
        } else if (wedding != null) {
            brideShort = extractFirstName(wedding.getBrideName());
            groomShort = extractFirstName(wedding.getGroomName());
        }

        String unitNumber = r != null && r.getUnitNumber() != null ? r.getUnitNumber() : "Flat 1402";
        String projectName = r != null && r.getProjectName() != null ? r.getProjectName() : "My Home Bhooja";
        String builderName = r != null && r.getBuilderName() != null ? r.getBuilderName() : "My Home Constructions";
        String city = r != null && r.getCity() != null ? r.getCity() : "Hyderabad";
        int targetSft = r != null && r.getTargetSft() != null ? r.getTargetSft() : (wedding != null && wedding.getTargetSft() != null ? wedding.getTargetSft() : 1200);

        Long weddingId = wedding != null ? wedding.getId() : (r != null ? r.getWeddingId() : null);
        int fundedSft = 0;
        if (weddingId != null) {
            List<FloorPlanZone> zones = floorPlanZoneRepository.findByWeddingId(weddingId);
            for (FloorPlanZone z : zones) {
                if (z.getFundedSft() != null) fundedSft += z.getFundedSft();
            }
        }

        String title = String.format("%s & %s's Wedding Registry • %s, %s", brideShort, groomShort, unitNumber, projectName);
        String description = "Celebrate our wedding! In lieu of boxed gifts, help us lay the bricks for our first home. Explore our ceremony itinerary & gift a square foot into our verified escrow.";
        String ogImage = r != null && r.getCoverImageUrl() != null ? r.getCoverImageUrl() : "https://cdn.plottheirfuture.in/previews/" + slug + "-share-banner.jpg";
        String url = "https://plottheirfuture.in/weddings/" + slug;
        String dateFormatted = r != null && r.getWeddingDate() != null ? formatDateFormatted(r.getWeddingDate()) : "December 18, 2026";

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("title", title);
        resp.put("description", description);
        resp.put("ogImage", ogImage);
        resp.put("url", url);
        resp.put("weddingDateFormatted", dateFormatted);
        resp.put("city", city);
        resp.put("targetSft", targetSft);
        resp.put("fundedSft", fundedSft);
        resp.put("builder", builderName);
        return resp;
    }

    private String extractFirstName(String fullName) {
        if (fullName == null || fullName.isBlank()) return "Couple";
        String[] parts = fullName.trim().split("\\s+");
        for (String part : parts) {
            String clean = part.replaceAll("[^a-zA-Z]", "");
            if (!clean.equalsIgnoreCase("dr") && !clean.equalsIgnoreCase("mr") && !clean.equalsIgnoreCase("mrs") && !clean.equalsIgnoreCase("ms") && !clean.equalsIgnoreCase("shri") && !clean.equalsIgnoreCase("smt")) {
                return part.replaceAll("[^a-zA-Z0-9]", "");
            }
        }
        return parts[0];
    }

    private String formatTimeAmPm(LocalTime time) {
        if (time == null) return "";
        int hour = time.getHour();
        int min = time.getMinute();
        String amPm = hour >= 12 ? "PM" : "AM";
        int h12 = hour % 12;
        if (h12 == 0) h12 = 12;
        return String.format("%02d:%02d %s", h12, min, amPm);
    }

    private String formatDateFormatted(LocalDate date) {
        if (date == null) return "";
        return date.format(DateTimeFormatter.ofPattern("MMMM d, yyyy", Locale.ENGLISH));
    }

    @Transactional
    public Wedding createWedding(Wedding wedding) {
        if (wedding.getSlug() != null && weddingRepository.existsBySlug(wedding.getSlug())) {
            throw new IllegalArgumentException("Wedding slug already exists: " + wedding.getSlug());
        }
        Wedding saved = weddingRepository.save(wedding);
        slugCache.put(saved.getSlug(), saved);
        idCache.put(saved.getId(), saved);
        return saved;
    }

    @Transactional
    public Wedding updateWedding(Long id, Wedding updated) {
        Wedding existing = getWeddingById(id);

        if (updated.getSlug() != null && !updated.getSlug().equals(existing.getSlug())) {
            if (weddingRepository.existsBySlug(updated.getSlug())) {
                throw new IllegalArgumentException("Wedding slug already exists: " + updated.getSlug());
            }
            slugCache.remove(existing.getSlug());
            existing.setSlug(updated.getSlug());
        }
        if (updated.getBrideName() != null) existing.setBrideName(updated.getBrideName());
        if (updated.getGroomName() != null) existing.setGroomName(updated.getGroomName());
        if (updated.getTargetSft() != null) existing.setTargetSft(updated.getTargetSft());
        if (updated.getRateSft() != null) existing.setRateSft(updated.getRateSft());
        if (updated.getVideoStreamUrl() != null) existing.setVideoStreamUrl(updated.getVideoStreamUrl());
        if (updated.getCoverImageUrl() != null) existing.setCoverImageUrl(updated.getCoverImageUrl());
        if (updated.getStatus() != null) existing.setStatus(updated.getStatus());
        if (updated.getBuilderReraId() != null) existing.setBuilderReraId(updated.getBuilderReraId());
        if (updated.getEscrowAccountNumber() != null) existing.setEscrowAccountNumber(updated.getEscrowAccountNumber());

        Wedding saved = weddingRepository.save(existing);
        slugCache.put(saved.getSlug(), saved);
        idCache.put(saved.getId(), saved);
        return saved;
    }

    @Transactional
    public void deleteWedding(Long id) {
        Wedding existing = getWeddingById(id);
        slugCache.remove(existing.getSlug());
        idCache.remove(id);
        weddingRepository.deleteById(id);
    }
}
