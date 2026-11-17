package com.plottheirfuture.plottheirfuture_backend.config;

import com.plottheirfuture.plottheirfuture_backend.entity.Ceremony;
import com.plottheirfuture.plottheirfuture_backend.entity.Contribution;
import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatSection;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanTile;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.Invitation;
import com.plottheirfuture.plottheirfuture_backend.entity.Location;
import com.plottheirfuture.plottheirfuture_backend.entity.PaymentStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.RsvpStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.TaxReceipt;
import com.plottheirfuture.plottheirfuture_backend.entity.TileStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.User;
import com.plottheirfuture.plottheirfuture_backend.entity.WebApp;
import com.plottheirfuture.plottheirfuture_backend.entity.WebAppType;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.entity.WeddingStatus;
import com.plottheirfuture.plottheirfuture_backend.repository.CeremonyRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.ContributionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatSectionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanTileRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.InvitationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.LocationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.TaxReceiptRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.UserRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WebAppRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final LocationRepository locationRepository;
    private final WebAppRepository webAppRepository;
    private final WeddingRepository weddingRepository;
    private final CeremonyRepository ceremonyRepository;
    private final InvitationRepository invitationRepository;
    private final FloorPlanZoneRepository floorPlanZoneRepository;
    private final FloorPlanTileRepository floorPlanTileRepository;
    private final ContributionRepository contributionRepository;
    private final TaxReceiptRepository taxReceiptRepository;
    private final FlatRepository flatRepository;
    private final FlatSectionRepository flatSectionRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        seedLocationsAndUsers();
        seedWebApps();
        seedWeddingsAndCampaignData();
        seedFlatsAndSections();
    }

    private void seedLocationsAndUsers() {
        // Ensure dedicated super admin account always exists in database
        String dedicatedAdminPhone = "+919999999999";
        if (userRepository.findByMobileNumber(dedicatedAdminPhone).isEmpty()) {
            User dedicatedAdmin = User.builder()
                    .name("Super Admin")
                    .password(passwordEncoder.encode("AdminPassword@123"))
                    .mobileNumber(dedicatedAdminPhone)
                    .role("ADMIN")
                    .otp("123456")
                    .roleId(1L)
                    .registered(true)
                    .occupation("Chief Platform Administrator")
                    .build();
            userRepository.save(dedicatedAdmin);
            log.info("Provisioned super admin: {} with password: AdminPassword@123", dedicatedAdminPhone);
        }

        if (userRepository.count() > 1 || locationRepository.count() > 0) {
            log.info("Users/Locations already seeded, skipping dummy data creation.");
            return;
        }

        log.info("Seeding dummy data for Users and Locations...");

        User admin = User.builder()
                .name("Sanvi Reddy")
                .password(passwordEncoder.encode("Admin@123"))
                .mobileNumber("+919848012345")
                .role("ADMIN")
                .otp("123456")
                .roleId(1L)
                .registered(true)
                .occupation("Senior Software Architect")
                .image("https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80")
                .build();
        admin = userRepository.save(admin);

        User couple = User.builder()
                .name("Santosh Varma")
                .password(passwordEncoder.encode("Couple@123"))
                .mobileNumber("+919876543210")
                .role("COUPLE")
                .otp("654321")
                .roleId(2L)
                .registered(true)
                .image("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80")
                .build();
        couple = userRepository.save(couple);

        User guest = User.builder()
                .name("Malli Karjuna")
                .password(passwordEncoder.encode("Guest@123"))
                .mobileNumber("+919988776655")
                .role("GUEST")
                .otp("482910")
                .roleId(3L)
                .registered(false)
                .image("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80")
                .build();
        guest = userRepository.save(guest);

        Location loc1 = locationRepository.save(Location.builder()
                .userId(admin.getId())
                .city("Hyderabad")
                .mandal("Gachibowli")
                .district("Rangareddy")
                .constituency("Serilingampally")
                .pincode("500032")
                .active(true)
                .priority(1)
                .build());

        Location loc2 = locationRepository.save(Location.builder()
                .userId(couple.getId())
                .city("Bengaluru")
                .mandal("Indiranagar")
                .district("Bengaluru Urban")
                .constituency("Shantinagar")
                .pincode("560038")
                .active(true)
                .priority(1)
                .build());

        Location loc3 = locationRepository.save(Location.builder()
                .userId(guest.getId())
                .city("Vijayawada")
                .mandal("Benz Circle")
                .district("Krishna")
                .constituency("Vijayawada East")
                .pincode("520010")
                .active(true)
                .priority(1)
                .build());

        admin.setLocationId(loc1.getId());
        couple.setLocationId(loc2.getId());
        guest.setLocationId(loc3.getId());

        userRepository.saveAll(List.of(admin, couple, guest));
        log.info("Successfully seeded 3 Users and 3 Locations.");
    }

    private void seedWebApps() {
        if (webAppRepository.count() > 0) {
            log.info("WebApp already seeded, skipping dummy data creation.");
            return;
        }

        log.info("Seeding dummy data for WebApp...");

        WebApp mainPortal = WebApp.builder()
                .name("PlotTheirFuture Main Portal")
                .type(WebAppType.website)
                .active(true)
                .primaryColour("#1E3A8A")
                .secondaryColour("#D97706")
                .themeColour("#F8FAFC")
                .heroImages(List.of(
                        "https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1600&q=80",
                        "https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=1600&q=80",
                        "https://images.unsplash.com/photo-1469371670807-013ccf25f16a?auto=format&fit=crop&w=1600&q=80"
                ))
                .build();

        WebApp microsite = WebApp.builder()
                .name("Sanvi & Santosh Wedding Microsite")
                .type(WebAppType.app)
                .active(true)
                .primaryColour("#831843")
                .secondaryColour("#F59E0B")
                .themeColour("#FFFBEB")
                .heroImages(List.of(
                        "https://images.unsplash.com/photo-1583939003579-730e3918a45a?auto=format&fit=crop&w=1600&q=80",
                        "https://images.unsplash.com/photo-1606800052052-a08af7148866?auto=format&fit=crop&w=1600&q=80"
                ))
                .build();

        webAppRepository.saveAll(List.of(mainPortal, microsite));
        log.info("Successfully seeded 2 WebApps with hero images.");
    }

    private void seedWeddingsAndCampaignData() {
        if (weddingRepository.count() > 0) {
            log.info("Weddings already seeded, skipping dummy data creation.");
            return;
        }

        log.info("Seeding Wedding campaigns, ceremonies, roster, floor plan, and contributions...");

        // 1. Wedding Campaign
        Wedding wedding = Wedding.builder()
                .slug("sanvi-santosh")
                .brideName("Sanvi Reddy")
                .groomName("Santosh Varma")
                .targetSft(1200)
                .rateSft(4500.0)
                .videoStreamUrl("https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
                .coverImageUrl("https://images.unsplash.com/photo-1583939003579-730e3918a45a?auto=format&fit=crop&w=1600&q=80")
                .status(WeddingStatus.ACTIVE)
                .builderReraId("PRM/KA/RERA/1251/310/PR/210312/004018")
                .escrowAccountNumber("ESC-HDFC-99201948102")
                .build();
        wedding = weddingRepository.save(wedding);

        // 2. Ceremonies
        Ceremony haldi = ceremonyRepository.save(Ceremony.builder()
                .weddingId(wedding.getId())
                .name("Haldi & Mehendi")
                .eventDate(LocalDate.of(2026, 11, 14))
                .startTime(LocalTime.of(10, 0))
                .endTime(LocalTime.of(14, 0))
                .venueName("The Palm Meadows, Hyderabad")
                .venueMapUrl("https://maps.google.com/?q=Palm+Meadows+Hyderabad")
                .build());

        Ceremony muhurtham = ceremonyRepository.save(Ceremony.builder()
                .weddingId(wedding.getId())
                .name("Wedding Muhurtham")
                .eventDate(LocalDate.of(2026, 11, 15))
                .startTime(LocalTime.of(9, 45))
                .endTime(LocalTime.of(12, 30))
                .venueName("Grand Palace Convention Hall, Hyderabad")
                .venueMapUrl("https://maps.google.com/?q=Grand+Palace+Hyderabad")
                .build());

        Ceremony reception = ceremonyRepository.save(Ceremony.builder()
                .weddingId(wedding.getId())
                .name("Grand Reception")
                .eventDate(LocalDate.of(2026, 11, 15))
                .startTime(LocalTime.of(19, 0))
                .endTime(LocalTime.of(23, 0))
                .venueName("Grand Palace Lawn, Hyderabad")
                .venueMapUrl("https://maps.google.com/?q=Grand+Palace+Hyderabad")
                .build());

        // 3. Guest Invitations Roster
        Invitation inv1 = invitationRepository.save(Invitation.builder()
                .weddingId(wedding.getId())
                .phoneE164("+919988776655")
                .guestName("Malli Karjuna")
                .cohort("FAMILY")
                .ceremonies(List.of("Haldi & Mehendi", "Wedding Muhurtham", "Grand Reception"))
                .refLead("uncle")
                .rsvpStatus(RsvpStatus.ATTENDING)
                .headcount(2)
                .build());

        Invitation inv2 = invitationRepository.save(Invitation.builder()
                .weddingId(wedding.getId())
                .phoneE164("+919123456789")
                .guestName("Rahul Sharma")
                .cohort("COLLEAGUES")
                .ceremonies(List.of("Grand Reception"))
                .refLead("office")
                .rsvpStatus(RsvpStatus.PENDING)
                .headcount(1)
                .build());

        // 4. Floor Plan Zones (1,200 SFT Total)
        FloorPlanZone livingRoom = floorPlanZoneRepository.save(FloorPlanZone.builder()
                .weddingId(wedding.getId())
                .roomName("Living Room")
                .totalSft(400)
                .fundedSft(45)
                .svgElementId("svg_living_room")
                .build());

        FloorPlanZone masterBed = floorPlanZoneRepository.save(FloorPlanZone.builder()
                .weddingId(wedding.getId())
                .roomName("Master Bedroom")
                .totalSft(250)
                .fundedSft(20)
                .svgElementId("svg_master_bed")
                .build());

        FloorPlanZone balcony = floorPlanZoneRepository.save(FloorPlanZone.builder()
                .weddingId(wedding.getId())
                .roomName("Balcony")
                .totalSft(80)
                .fundedSft(15)
                .svgElementId("svg_balcony")
                .build());

        FloorPlanZone kitchen = floorPlanZoneRepository.save(FloorPlanZone.builder()
                .weddingId(wedding.getId())
                .roomName("Kitchen")
                .totalSft(120)
                .fundedSft(10)
                .svgElementId("svg_kitchen")
                .build());

        // 5. Floor Plan Tiles
        FloorPlanTile tile1 = floorPlanTileRepository.save(FloorPlanTile.builder()
                .weddingId(wedding.getId())
                .zoneId(livingRoom.getId())
                .sftSize(5)
                .status(TileStatus.FUNDED)
                .donorId(inv1.getId())
                .build());

        FloorPlanTile tile2 = floorPlanTileRepository.save(FloorPlanTile.builder()
                .weddingId(wedding.getId())
                .zoneId(livingRoom.getId())
                .sftSize(10)
                .status(TileStatus.HOLD)
                .lockedByPhone("+919988776655")
                .lockedUntil(LocalDateTime.now().plusMinutes(10))
                .build());

        FloorPlanTile tile3 = floorPlanTileRepository.save(FloorPlanTile.builder()
                .weddingId(wedding.getId())
                .zoneId(balcony.getId())
                .sftSize(1)
                .status(TileStatus.OPEN)
                .build());

        // 6. Contribution
        Contribution contribution = contributionRepository.save(Contribution.builder()
                .weddingId(wedding.getId())
                .invitationId(inv1.getId())
                .unitsSft(5)
                .amount(22500.0)
                .txnId("TXN_UPI_992019482")
                .bankRef("HDFC0001892837")
                .paymentStatus(PaymentStatus.SUCCESS)
                .isAnonymous(false)
                .blessingMessage("May your new home be filled with endless joy and laughter! - Malli")
                .createdAt(LocalDateTime.now())
                .build());

        // 7. Tax Receipt (Section 56(2)(x))
        taxReceiptRepository.save(TaxReceipt.builder()
                .contributionId(contribution.getId())
                .receiptNo("PTF-SEC-892104")
                .exemptClause("Section 56(2)(x) of Indian Income Tax Act")
                .digitalSignatureHash("9a8fbc83d91e84a92c0182b810948ac019")
                .pdfUrl("https://plottheirfuture.in/receipts/PTF-SEC-892104.pdf")
                .generatedAt(LocalDateTime.now())
                .build());

        log.info("Successfully seeded complete Wedding, Itinerary, Floor Plan, and Escrow data.");
    }

    private void seedFlatsAndSections() {
        if (flatRepository.count() > 0) {
            log.info("Flats already seeded, skipping dummy creation.");
            return;
        }

        log.info("Seeding verified Flats, Dynamic Sections, and Brick Conversion configurations...");

        // 1. Flat 1: Assigned to rahul-sneha
        Flat flat1 = flatRepository.save(Flat.builder()
                .flatId("FLAT-2026-HYD-001")
                .name("My Home Bhooja Luxury 3BHK")
                .description("South-facing vaastu-compliant luxury 3BHK residence overlooking the Gachibowli skyline with Italian marble flooring, panoramic glass balcony, and smart automation.")
                .coverImageUrl("assets/images/apartment_poster.jpg")
                .builtUpAreaSft(1850)
                .carpetAreaSft(1550)
                .bedrooms(3)
                .bathrooms(3)
                .balconies(2)
                .halls(1)
                .kitchens(1)
                .location("Gachibowli, Hyderabad")
                .address("Tower C, Unit 1402, My Home Bhooja, Financial District, Hyderabad")
                .pricePerSft(7200.0)
                .bricksPerSft(10)
                .pricePerBrick(720.0)
                .status(FlatStatus.ASSIGNED)
                .assignedWeddingId(2L)
                .assignedWeddingSlug("rahul-sneha")
                .approvedAt(LocalDateTime.now())
                .approvedByAdminId(1L)
                .build());

        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Master Bedroom").areaSft(350).lengthFt(19.0).widthFt(18.4).pricePerSft(7200.0).totalPrice(2520000.0).giftedSft(45).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Bedroom 2").areaSft(250).lengthFt(16.0).widthFt(15.6).pricePerSft(7200.0).totalPrice(1800000.0).giftedSft(20).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Bedroom 3").areaSft(200).lengthFt(15.0).widthFt(13.3).pricePerSft(7200.0).totalPrice(1440000.0).giftedSft(10).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Hall / Living Room").areaSft(550).lengthFt(25.0).widthFt(22.0).pricePerSft(7200.0).totalPrice(3960000.0).giftedSft(80).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Kitchen & Dining").areaSft(250).lengthFt(18.0).widthFt(13.9).pricePerSft(7200.0).totalPrice(1800000.0).giftedSft(30).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Balcony").areaSft(150).lengthFt(15.0).widthFt(10.0).pricePerSft(7200.0).totalPrice(1080000.0).giftedSft(15).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat1.getId()).sectionName("Bathrooms").areaSft(100).lengthFt(10.0).widthFt(10.0).pricePerSft(7200.0).totalPrice(720000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());

        // 2. Flat 2: Assigned to sanvi-santosh
        Flat flat2 = flatRepository.save(Flat.builder()
                .flatId("FLAT-2026-BLR-002")
                .name("Skyline Meadows 2BHK Residence")
                .description("Contemporary 2BHK home in Bangalore East featuring German modular kitchen, wooden deck balcony, and high ceiling bedrooms.")
                .coverImageUrl("assets/images/apartment_poster.jpg")
                .builtUpAreaSft(1200)
                .carpetAreaSft(980)
                .bedrooms(2)
                .bathrooms(2)
                .balconies(1)
                .halls(1)
                .kitchens(1)
                .location("Whitefield, Bangalore")
                .address("Block B, Unit 402, Skyline Meadows, ITPL Road, Whitefield")
                .pricePerSft(4500.0)
                .bricksPerSft(10)
                .pricePerBrick(450.0)
                .status(FlatStatus.ASSIGNED)
                .assignedWeddingId(1L)
                .assignedWeddingSlug("sanvi-santosh")
                .approvedAt(LocalDateTime.now())
                .approvedByAdminId(1L)
                .build());

        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Master Bedroom").areaSft(300).lengthFt(18.0).widthFt(16.7).pricePerSft(4500.0).totalPrice(1350000.0).giftedSft(120).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Bedroom 2").areaSft(220).lengthFt(15.0).widthFt(14.7).pricePerSft(4500.0).totalPrice(990000.0).giftedSft(70).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Hall / Living Room").areaSft(400).lengthFt(22.0).widthFt(18.2).pricePerSft(4500.0).totalPrice(1800000.0).giftedSft(180).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Modular Kitchen").areaSft(140).lengthFt(14.0).widthFt(10.0).pricePerSft(4500.0).totalPrice(630000.0).giftedSft(35).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Sunrise Balcony").areaSft(80).lengthFt(10.0).widthFt(8.0).pricePerSft(4500.0).totalPrice(360000.0).giftedSft(15).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat2.getId()).sectionName("Bathrooms").areaSft(60).lengthFt(10.0).widthFt(6.0).pricePerSft(4500.0).totalPrice(270000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());

        // 3. Flat 3: APPROVED (Ready to assign!)
        Flat flat3 = flatRepository.save(Flat.builder()
                .flatId("FLAT-2026-HYD-003")
                .name("The Presidential 4BHK Sky Villa")
                .description("Ultra-luxury 4BHK sky residence in Jubilee Hills with private elevator foyer, 360-degree terrace garden, home theatre room, and servant quarters.")
                .coverImageUrl("assets/images/apartment_poster.jpg")
                .builtUpAreaSft(2400)
                .carpetAreaSft(2050)
                .bedrooms(4)
                .bathrooms(4)
                .balconies(3)
                .halls(2)
                .kitchens(1)
                .location("Jubilee Hills, Hyderabad")
                .address("Sky Villa 19, Road No 36, Jubilee Hills, Hyderabad")
                .pricePerSft(8500.0)
                .bricksPerSft(10)
                .pricePerBrick(850.0)
                .status(FlatStatus.APPROVED)
                .approvedAt(LocalDateTime.now())
                .approvedByAdminId(1L)
                .build());

        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Master Suite").areaSft(500).lengthFt(25.0).widthFt(20.0).pricePerSft(8500.0).totalPrice(4250000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Bedroom 2").areaSft(350).lengthFt(20.0).widthFt(17.5).pricePerSft(8500.0).totalPrice(2975000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Bedroom 3").areaSft(300).lengthFt(18.0).widthFt(16.7).pricePerSft(8500.0).totalPrice(2550000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Bedroom 4 / Study").areaSft(250).lengthFt(16.0).widthFt(15.6).pricePerSft(8500.0).totalPrice(2125000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Grand Living Hall").areaSft(600).lengthFt(30.0).widthFt(20.0).pricePerSft(8500.0).totalPrice(5100000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Chef's Kitchen").areaSft(200).lengthFt(16.0).widthFt(12.5).pricePerSft(8500.0).totalPrice(1700000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Panoramic Balcony").areaSft(120).lengthFt(15.0).widthFt(8.0).pricePerSft(8500.0).totalPrice(1020000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat3.getId()).sectionName("Pooja Room").areaSft(80).lengthFt(10.0).widthFt(8.0).pricePerSft(8500.0).totalPrice(680000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());

        // 4. Flat 4: PENDING_APPROVAL
        Flat flat4 = flatRepository.save(Flat.builder()
                .flatId("FLAT-2026-HYD-004")
                .name("Serene Heights 2BHK Smart Home")
                .description("Smart IoT-enabled 2BHK apartment in Kondapur near Cyber Towers with energy-efficient heat management and acoustic soundproofing.")
                .coverImageUrl("assets/images/apartment_poster.jpg")
                .builtUpAreaSft(1100)
                .carpetAreaSft(900)
                .bedrooms(2)
                .bathrooms(2)
                .balconies(1)
                .halls(1)
                .kitchens(1)
                .location("Kondapur, Hyderabad")
                .address("Tower A, Unit 604, Serene Heights, Kondapur")
                .pricePerSft(5200.0)
                .bricksPerSft(10)
                .pricePerBrick(520.0)
                .status(FlatStatus.PENDING_APPROVAL)
                .build());

        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Master Bedroom").areaSft(280).lengthFt(17.0).widthFt(16.5).pricePerSft(5200.0).totalPrice(1456000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Bedroom 2").areaSft(200).lengthFt(15.0).widthFt(13.3).pricePerSft(5200.0).totalPrice(1040000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Hall / Living Room").areaSft(380).lengthFt(22.0).widthFt(17.3).pricePerSft(5200.0).totalPrice(1976000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Kitchen").areaSft(140).lengthFt(14.0).widthFt(10.0).pricePerSft(5200.0).totalPrice(728000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Balcony").areaSft(60).lengthFt(10.0).widthFt(6.0).pricePerSft(5200.0).totalPrice(312000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());
        flatSectionRepository.save(FlatSection.builder().flatId(flat4.getId()).sectionName("Bathrooms").areaSft(40).lengthFt(8.0).widthFt(5.0).pricePerSft(5200.0).totalPrice(208000.0).giftedSft(0).sectionImageUrl("assets/images/apartment_poster.jpg").build());

        log.info("Successfully seeded 4 Flats with complete section area breakdowns.");
    }
}
