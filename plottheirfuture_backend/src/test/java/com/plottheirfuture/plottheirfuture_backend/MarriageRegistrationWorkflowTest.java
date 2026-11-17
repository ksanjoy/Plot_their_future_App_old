package com.plottheirfuture.plottheirfuture_backend;

import com.plottheirfuture.plottheirfuture_backend.dto.ApproveFlatRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.EscrowBankDto;
import com.plottheirfuture.plottheirfuture_backend.dto.MarriageCeremonyDto;
import com.plottheirfuture.plottheirfuture_backend.dto.MarriageRegistrationRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.PersonDto;
import com.plottheirfuture.plottheirfuture_backend.entity.Ceremony;
import com.plottheirfuture.plottheirfuture_backend.entity.CeremonyType;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanTile;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageCeremony;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistration;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistrationStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.exception.ConflictException;
import com.plottheirfuture.plottheirfuture_backend.repository.CeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.ContributionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanTileRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageCeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageRegistrationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.UserRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import com.plottheirfuture.plottheirfuture_backend.service.FloorPlanZoneService;
import com.plottheirfuture.plottheirfuture_backend.service.MarriageService;
import com.plottheirfuture.plottheirfuture_backend.service.WeddingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class MarriageRegistrationWorkflowTest {

    private MarriageService marriageService;
    private WeddingService weddingService;

    private final Map<Long, MarriageRegistration> regStore = new ConcurrentHashMap<>();
    private final Map<Long, MarriageCeremony> ceremonyStore = new ConcurrentHashMap<>();
    private final Map<Long, Wedding> weddingStore = new ConcurrentHashMap<>();
    private final Map<Long, FloorPlanZone> zoneStore = new ConcurrentHashMap<>();
    private final Map<Long, FloorPlanTile> tileStore = new ConcurrentHashMap<>();
    private final Map<Long, Ceremony> mainCeremonyStore = new ConcurrentHashMap<>();

    private final AtomicLong regIdGen = new AtomicLong(100);
    private final AtomicLong ceremonyIdGen = new AtomicLong(200);
    private final AtomicLong weddingIdGen = new AtomicLong(1);
    private final AtomicLong zoneIdGen = new AtomicLong(500);
    private final AtomicLong tileIdGen = new AtomicLong(1000);
    private final AtomicLong mainCeremonyIdGen = new AtomicLong(300);

    @BeforeEach
    void setUp() {
        regStore.clear();
        ceremonyStore.clear();
        weddingStore.clear();
        zoneStore.clear();
        tileStore.clear();
        mainCeremonyStore.clear();

        // Dynamic Proxy for MarriageRegistrationRepository
        MarriageRegistrationRepository regRepo = (MarriageRegistrationRepository) Proxy.newProxyInstance(
                MarriageRegistrationRepository.class.getClassLoader(),
                new Class<?>[]{MarriageRegistrationRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        MarriageRegistration r = (MarriageRegistration) args[0];
                        if (r.getId() == null) {
                            r.setId(regIdGen.incrementAndGet());
                        }
                        regStore.put(r.getId(), r);
                        return r;
                    } else if ("findById".equals(name)) {
                        Long id = (Long) args[0];
                        return Optional.ofNullable(regStore.get(id));
                    } else if ("findBySlug".equals(name)) {
                        String slug = (String) args[0];
                        return regStore.values().stream().filter(r -> slug.equals(r.getSlug())).findFirst();
                    } else if ("findByUserIdOrderBySubmittedAtDesc".equals(name)) {
                        Long uid = (Long) args[0];
                        List<MarriageRegistration> list = new ArrayList<>();
                        for (MarriageRegistration r : regStore.values()) {
                            if (uid.equals(r.getUserId())) list.add(r);
                        }
                        return list;
                    } else if ("count".equals(name)) {
                        return (long) regStore.size();
                    } else if ("countByStatus".equals(name)) {
                        MarriageRegistrationStatus st = (MarriageRegistrationStatus) args[0];
                        return regStore.values().stream().filter(r -> r.getStatus() == st).count();
                    }
                    return null;
                }
        );

        // Dynamic Proxy for MarriageCeremonyRepository
        MarriageCeremonyRepository mcRepo = (MarriageCeremonyRepository) Proxy.newProxyInstance(
                MarriageCeremonyRepository.class.getClassLoader(),
                new Class<?>[]{MarriageCeremonyRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        MarriageCeremony c = (MarriageCeremony) args[0];
                        if (c.getId() == null) {
                            c.setId(ceremonyIdGen.incrementAndGet());
                        }
                        ceremonyStore.put(c.getId(), c);
                        return c;
                    } else if ("findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc".equals(name)) {
                        Long regId = (Long) args[0];
                        List<MarriageCeremony> list = new ArrayList<>();
                        for (MarriageCeremony c : ceremonyStore.values()) {
                            if (c.getMarriageRegistration() != null && regId.equals(c.getMarriageRegistration().getId())) {
                                list.add(c);
                            }
                        }
                        return list;
                    } else if ("deleteAll".equals(name)) {
                        @SuppressWarnings("unchecked")
                        Iterable<MarriageCeremony> entities = (Iterable<MarriageCeremony>) args[0];
                        for (MarriageCeremony e : entities) {
                            ceremonyStore.remove(e.getId());
                        }
                        return null;
                    }
                    return null;
                }
        );

        // Dynamic Proxy for WeddingRepository
        WeddingRepository weddingRepo = (WeddingRepository) Proxy.newProxyInstance(
                WeddingRepository.class.getClassLoader(),
                new Class<?>[]{WeddingRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        Wedding w = (Wedding) args[0];
                        if (w.getId() == null) {
                            w.setId(weddingIdGen.incrementAndGet());
                        }
                        weddingStore.put(w.getId(), w);
                        return w;
                    } else if ("findById".equals(name)) {
                        Long id = (Long) args[0];
                        return Optional.ofNullable(weddingStore.get(id));
                    } else if ("findBySlug".equals(name)) {
                        String slug = (String) args[0];
                        return weddingStore.values().stream().filter(w -> slug.equals(w.getSlug())).findFirst();
                    } else if ("existsBySlug".equals(name)) {
                        String slug = (String) args[0];
                        return weddingStore.values().stream().anyMatch(w -> slug.equals(w.getSlug()));
                    }
                    return null;
                }
        );

        // Dynamic Proxy for CeremonyRepository
        CeremonyRepository ceremonyRepo = (CeremonyRepository) Proxy.newProxyInstance(
                CeremonyRepository.class.getClassLoader(),
                new Class<?>[]{CeremonyRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        Ceremony c = (Ceremony) args[0];
                        if (c.getId() == null) {
                            c.setId(mainCeremonyIdGen.incrementAndGet());
                        }
                        mainCeremonyStore.put(c.getId(), c);
                        return c;
                    } else if ("findByWeddingIdOrderByEventDateAscStartTimeAsc".equals(name)) {
                        Long wid = (Long) args[0];
                        List<Ceremony> list = new ArrayList<>();
                        for (Ceremony c : mainCeremonyStore.values()) {
                            if (wid.equals(c.getWeddingId())) list.add(c);
                        }
                        return list;
                    }
                    return null;
                }
        );

        // Dynamic Proxy for FloorPlanZoneRepository
        FloorPlanZoneRepository zoneRepo = (FloorPlanZoneRepository) Proxy.newProxyInstance(
                FloorPlanZoneRepository.class.getClassLoader(),
                new Class<?>[]{FloorPlanZoneRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        FloorPlanZone z = (FloorPlanZone) args[0];
                        if (z.getId() == null) {
                            z.setId(zoneIdGen.incrementAndGet());
                        }
                        zoneStore.put(z.getId(), z);
                        return z;
                    } else if ("findByWeddingId".equals(name)) {
                        Long wid = (Long) args[0];
                        List<FloorPlanZone> list = new ArrayList<>();
                        for (FloorPlanZone z : zoneStore.values()) {
                            if (wid.equals(z.getWeddingId())) list.add(z);
                        }
                        return list;
                    }
                    return null;
                }
        );

        // Dynamic Proxy for FloorPlanTileRepository
        FloorPlanTileRepository tileRepo = (FloorPlanTileRepository) Proxy.newProxyInstance(
                FloorPlanTileRepository.class.getClassLoader(),
                new Class<?>[]{FloorPlanTileRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("save".equals(name)) {
                        FloorPlanTile t = (FloorPlanTile) args[0];
                        if (t.getId() == null) {
                            t.setId(tileIdGen.incrementAndGet());
                        }
                        tileStore.put(t.getId(), t);
                        return t;
                    } else if ("findByWeddingIdAndZoneId".equals(name)) {
                        Long wid = (Long) args[0];
                        Long zid = (Long) args[1];
                        List<FloorPlanTile> list = new ArrayList<>();
                        for (FloorPlanTile t : tileStore.values()) {
                            if (wid.equals(t.getWeddingId()) && zid.equals(t.getZoneId())) {
                                list.add(t);
                            }
                        }
                        return list;
                    }
                    return null;
                }
        );

        // Dynamic Proxy for ContributionRepository
        ContributionRepository contribRepo = (ContributionRepository) Proxy.newProxyInstance(
                ContributionRepository.class.getClassLoader(),
                new Class<?>[]{ContributionRepository.class},
                (proxy, method, args) -> null
        );

        // Dynamic Proxy for FlatRepository
        com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository flatRepo = (com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository) Proxy.newProxyInstance(
                com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository.class.getClassLoader(),
                new Class<?>[]{com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository.class},
                (proxy, method, args) -> {
                    if ("findByFlatId".equals(method.getName())) {
                        return java.util.Optional.empty();
                    }
                    return null;
                }
        );

        FloorPlanZoneService zoneService = new FloorPlanZoneService(zoneRepo, tileRepo);
        marriageService = new MarriageService(regRepo, mcRepo, weddingRepo, ceremonyRepo, zoneRepo, tileRepo, contribRepo, flatRepo);
        weddingService = new WeddingService(weddingRepo, regRepo, mcRepo, ceremonyRepo, zoneRepo, zoneService);
    }

    @Test
    @DisplayName("Comprehensive 2.0.0-PROD Lifecycle: Register, Guard, Admin Approve, Share Info, & Microsite Dossier")
    void testEndToEnd200ProdWorkflow() {
        // Step 1: Submit Marriage Registration
        MarriageRegistrationRequest req = MarriageRegistrationRequest.builder()
                .bride(PersonDto.builder().name("Dr. Sneha Reddy").mobileNumber("+919848012345").occupation("Pediatrician").build())
                .groom(PersonDto.builder().name("Rahul Varma").mobileNumber("+919876543210").occupation("Senior Software Architect").build())
                .primaryContactNumber("+919848012345")
                .secondaryContactNumber("+919876543210")
                .weddingDate(LocalDate.of(2026, 12, 18))
                .city("Hyderabad")
                .weddingCardUrl("https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf")
                .coverImageUrl("https://images.unsplash.com/photo-1583939003579-730e3918a45a")
                .coupleStory("We met during our university days in 2018.")
                .targetBhk("2 BHK")
                .functions(List.of(
                        MarriageCeremonyDto.builder()
                                .ceremonyType(CeremonyType.HALDI)
                                .name("Haldi & Mangala Snanam")
                                .isEnabled(true)
                                .eventDate(LocalDate.of(2026, 12, 16))
                                .startTime(LocalTime.of(9, 30))
                                .endTime(LocalTime.of(13, 0))
                                .venueName("The Palm Meadows Lawns")
                                .venueAddress("Plot 12, Financial District, Hyderabad")
                                .venueMapUrl("https://maps.google.com/?q=The+Palm+Meadows+Hyderabad")
                                .dressCode("Yellow Traditional")
                                .notes("Followed by traditional lunch.")
                                .build(),
                        MarriageCeremonyDto.builder()
                                .ceremonyType(CeremonyType.MEHENDI)
                                .name("Mehendi Ceremony")
                                .isEnabled(true)
                                .eventDate(LocalDate.of(2026, 12, 16))
                                .startTime(LocalTime.of(17, 0))
                                .endTime(LocalTime.of(21, 30))
                                .venueName("The Palm Meadows Banquet Hall")
                                .venueAddress("Plot 12, Financial District, Hyderabad")
                                .venueMapUrl("https://maps.google.com/?q=The+Palm+Meadows+Hyderabad")
                                .dressCode("Floral & Pastel Hues")
                                .notes("Live mehendi artists.")
                                .build(),
                        MarriageCeremonyDto.builder()
                                .ceremonyType(CeremonyType.SANGEET)
                                .name("Musical Sangeet")
                                .isEnabled(true)
                                .eventDate(LocalDate.of(2026, 12, 17))
                                .startTime(LocalTime.of(19, 0))
                                .endTime(LocalTime.of(23, 30))
                                .venueName("Grand Ballroom, ITC Kohenur")
                                .venueAddress("HITEC City, Madhapur, Hyderabad")
                                .venueMapUrl("https://maps.google.com/?q=ITC+Kohenur+Hyderabad")
                                .dressCode("Glamorous Indo-Western")
                                .notes("Dance performances.")
                                .build(),
                        MarriageCeremonyDto.builder()
                                .ceremonyType(CeremonyType.MUHURTHAM)
                                .name("Wedding Muhurtham")
                                .isEnabled(true)
                                .eventDate(LocalDate.of(2026, 12, 18))
                                .startTime(LocalTime.of(9, 45))
                                .endTime(LocalTime.of(13, 0))
                                .venueName("N-Convention Centre, Hall A")
                                .venueAddress("Madhapur, Hyderabad")
                                .venueMapUrl("https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad")
                                .dressCode("Pure Silk Traditional Attire")
                                .notes("Sumuhurtham at 10:24 AM sharp.")
                                .build(),
                        MarriageCeremonyDto.builder()
                                .ceremonyType(CeremonyType.RECEPTION)
                                .name("Grand Reception")
                                .isEnabled(true)
                                .eventDate(LocalDate.of(2026, 12, 18))
                                .startTime(LocalTime.of(19, 30))
                                .endTime(LocalTime.of(23, 0))
                                .venueName("N-Convention Centre, Main Arena")
                                .venueAddress("Madhapur, Hyderabad")
                                .venueMapUrl("https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad")
                                .dressCode("Formal Evening Wear")
                                .notes("Dinner and live orchestra.")
                                .build()
                ))
                .build();

        Map<String, Object> registerResult = marriageService.submitRegistration(req, 101L);
        assertNotNull(registerResult);
        assertEquals("PENDING_ADMIN_APPROVAL", registerResult.get("statusEnum"));
        Long regId = (Long) registerResult.get("registrationId");
        assertNotNull(regId);
        assertTrue(registerResult.get("referenceNumber").toString().startsWith("REG-2026-"));
        assertEquals(5, registerResult.get("enabledCeremonyCount"));

        // Step 2: Attempt to get Share Info before approval -> MUST throw 409 ConflictException
        ConflictException confEx = assertThrows(ConflictException.class, () -> marriageService.getShareInfo(regId));
        assertEquals("PENDING_ADMIN_APPROVAL", confEx.getRegistrationStatus());

        // Step 3: Admin Dashboard Stats check
        Map<String, Object> stats = marriageService.getAdminDashboardStats();
        assertEquals(1L, stats.get("totalRegistrations"));
        assertEquals(1L, stats.get("pendingApprovalCount"));

        // Step 4: Admin inspects registration dossier
        Map<String, Object> inspect = marriageService.getRegistrationById(regId);
        assertEquals("Dr. Sneha Reddy", ((Map<?, ?>) inspect.get("bride")).get("name"));
        assertEquals("Rahul Varma", ((Map<?, ?>) inspect.get("groom")).get("name"));
        assertEquals("+919848012345", ((Map<?, ?>) inspect.get("contactDossier")).get("primaryMobile"));
        assertEquals("https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf", ((Map<?, ?>) inspect.get("weddingCard")).get("fileUrl"));

        // Step 5: Admin Approves & Assigns Flat
        ApproveFlatRequest approveReq = ApproveFlatRequest.builder()
                .builderName("My Home Constructions")
                .projectName("My Home Bhooja")
                .unitNumber("Flat 1402")
                .tower("14th Floor")
                .configuration("2 BHK")
                .targetSft(1200)
                .rateSft(4500.0)
                .slug("rahul-sneha")
                .builderReraId("PRM/KA/RERA/1251/310/PR/210312/004018")
                .reraProjectUrl("https://rera.telangana.gov.in/projects/PRM-1251-004018")
                .escrowBank(EscrowBankDto.builder()
                        .bankName("HDFC Bank Ltd")
                        .accountNumber("ESC-HDFC-99201948102")
                        .ifscCode("HDFC0000456")
                        .upiVpa("plottheirfuture.rahul.sneha@hdfcbank")
                        .build())
                .videoStreamUrl("https://cdn.plottheirfuture.in/stream/rahul-sneha/master.m3u8")
                .adminNotes("Verified with builder. Escrow is active.")
                .build();

        Map<String, Object> approveResult = marriageService.approveAndAssignFlat(regId, approveReq, 1L);
        assertNotNull(approveResult);
        assertEquals("SUCCESS", approveResult.get("status"));
        assertEquals("ACTIVE", approveResult.get("statusEnum"));
        assertEquals("rahul-sneha", approveResult.get("slug"));
        assertEquals("https://plottheirfuture.in/weddings/rahul-sneha", approveResult.get("shareableUrl"));

        // Step 6: Couple grabs Share Info after approval -> Now returns 200 OK with templates
        Map<String, Object> shareInfo = marriageService.getShareInfo(regId);
        assertNotNull(shareInfo);
        assertEquals("ACTIVE", shareInfo.get("status"));
        assertEquals("rahul-sneha", shareInfo.get("campaignSlug"));
        assertEquals("https://plottheirfuture.in/weddings/rahul-sneha", shareInfo.get("shareableUrl"));
        assertTrue(shareInfo.get("whatsAppShareTemplate").toString().contains("Dear Family & Friends"));
        assertTrue(shareInfo.get("smsShareTemplate").toString().contains("wedding celebrations & First Home registry link"));

        // Step 7: Public Wedding Microsite - Get Public Wedding Details (Section 5.1)
        Map<String, Object> dossier = weddingService.getPublicWeddingDossier("rahul-sneha");
        assertNotNull(dossier);
        assertEquals("rahul-sneha", dossier.get("slug"));
        assertEquals("ACTIVE", dossier.get("status"));
        assertEquals("Dr. Sneha Reddy", ((Map<?, ?>) dossier.get("bride")).get("name"));
        assertEquals("Pediatrician", ((Map<?, ?>) dossier.get("bride")).get("occupation"));
        assertEquals("Rahul Varma", ((Map<?, ?>) dossier.get("groom")).get("name"));
        assertEquals("Senior Software Architect", ((Map<?, ?>) dossier.get("groom")).get("occupation"));

        Map<?, ?> flat = (Map<?, ?>) dossier.get("flat");
        assertNotNull(flat);
        assertEquals("My Home Constructions", flat.get("builderName"));
        assertEquals("My Home Bhooja", flat.get("projectName"));
        assertEquals("Flat 1402 (14th Floor)", flat.get("unitNumber"));
        assertEquals("2 BHK", flat.get("configuration"));
        assertEquals(1200, flat.get("targetSft"));
        assertEquals(4500.0, flat.get("rateSft"));
        assertEquals(5400000.0, flat.get("totalTargetAmountInr"));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> ceremonySummary = (List<Map<String, Object>>) dossier.get("ceremonySummary");
        assertEquals(5, ceremonySummary.size());
        assertEquals("Haldi & Mangala Snanam", ceremonySummary.get(0).get("name"));
        assertEquals("09:30 AM", ceremonySummary.get(0).get("time"));

        // Step 8: Public Chronological Ceremonies (Section 5.2)
        List<Map<String, Object>> publicCeremonies = weddingService.getChronologicalCeremoniesBySlug("rahul-sneha");
        assertEquals(5, publicCeremonies.size());
        assertEquals("HALDI", publicCeremonies.get(0).get("ceremonyType"));
        assertEquals("The Palm Meadows Lawns", publicCeremonies.get(0).get("venueName"));
        assertEquals("Yellow Traditional", publicCeremonies.get(0).get("dressCode"));

        // Step 9: Interactive Floor Plan Grid (Section 5.3)
        List<Map<String, Object>> zones = weddingService.getFloorPlanZonesBySlug("rahul-sneha");
        assertNotNull(zones);
        assertTrue(zones.size() >= 5);
        assertEquals("Living & Dining Room", zones.get(0).get("name"));

        // Step 10: WhatsApp / Social Share Preview Metadata (Section 5.4)
        Map<String, Object> sharePreview = weddingService.getSharePreview("rahul-sneha");
        assertNotNull(sharePreview);
        assertTrue(sharePreview.get("title").toString().contains("Sneha & Rahul's Wedding Registry"));
        assertTrue(sharePreview.get("title").toString().contains("Flat 1402"));
        assertEquals("https://plottheirfuture.in/weddings/rahul-sneha", sharePreview.get("url"));
        assertEquals("My Home Constructions", sharePreview.get("builder"));
        assertEquals(1200, sharePreview.get("targetSft"));
    }
}
