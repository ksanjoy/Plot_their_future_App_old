import 'package:flutter/foundation.dart';
import '../models/marriage_submission_model.dart';
import '../state/wedding_registry_service.dart';

class LocalMarriageStorageService {
  static final LocalMarriageStorageService instance = LocalMarriageStorageService._internal();

  LocalMarriageStorageService._internal() {
    // Fresh start: initialized empty so user can start with a clean slate
  }

  void seedInitialSubmissionsForTest() {
    _submissions.clear();
    _seedInitialSubmissions();
  }

  void clearAllRegistrations() {
    _submissions.clear();
  }

  final List<MarriageSubmission> _submissions = [];

  void _seedInitialSubmissions() {
    // 1. Seed Pre-Approved Wedding (Sanvi & Santosh)
    final sanviSantosh = MarriageSubmission(
      id: '1',
      referenceNumber: '#REG-2026-BLR-0001',
      status: 'APPROVED',
      submittedAt: DateTime(2026, 10, 15, 10, 30),
      userId: 1,
      bride: const BrideModel(
        name: 'Sanvi Reddy',
        mobileNumber: '+919848012345',
        email: 'sanvi.reddy@example.com',
        occupation: 'Software Engineer',
      ),
      groom: const GroomModel(
        name: 'Santosh Varma',
        mobileNumber: '+919848099999',
        email: 'santosh.varma@example.com',
        occupation: 'Product Designer',
      ),
      primaryContactNumber: '+919848012345',
      secondaryContactNumber: '+919848099999',
      weddingDate: DateTime(2026, 11, 15),
      city: 'Bangalore',
      coupleStory: 'We met in Bangalore in 2021. Instead of boxed gifts, our families decided to help us lay the bricks for our first home.',
      weddingCardUrl: 'assets/images/app_logo_header.png',
      coverImageUrl: 'assets/images/couple_portrait.jpg',
      targetBhk: '2 BHK',
      preferredArea: 'Whitefield, Bangalore',
      slug: 'sanvi-santosh',
      shareableUrl: 'https://plottheirfuture.in/weddings/sanvi-santosh',
      qrCodeUrl: 'https://cdn.plottheirfuture.in/qrcodes/sanvi-santosh.png',
      videoStreamUrl: 'https://cdn.plottheirfuture.in/stream/sanvi-santosh/master.m3u8',
      assignedFlat: const AssignedFlatModel(
        builderName: 'Prestige Group',
        projectName: 'Prestige Lakeside Habitat',
        tower: 'Tower 4 (Lotus)',
        unitNumber: 'Flat 402 (4th Floor)',
        configuration: '2 BHK',
        targetSft: 1200,
        rateSft: 4500.0,
        totalTargetAmountInr: 5400000.0,
        builderReraId: 'PRM/KA/RERA/1251/310/PR/210312/004018',
        reraProjectUrl: 'https://rera.karnataka.gov.in',
        escrowBank: EscrowBankModel(
          bankName: 'HDFC Bank Ltd',
          branchName: 'Whitefield Branch',
          accountHolder: 'PLOT THEIR FUTURE ESCROW - SANVI SANTOSH',
          accountNumber: 'ESC-HDFC-99201948102',
          ifscCode: 'HDFC0000456',
          upiVpa: 'plottheirfuture.sanvi.santosh@hdfcbank',
        ),
      ),
      functions: [
        CeremonyFunctionModel(
          ceremonyType: 'HALDI',
          name: 'Haldi & Mangala Snanam',
          isEnabled: true,
          eventDate: DateTime(2026, 11, 14),
          startTime: '10:00:00',
          endTime: '13:00:00',
          venueName: 'The Palm Meadows Clubhouse',
          venueAddress: 'Whitefield Main Road, Bangalore 560066',
          venueMapUrl: 'https://maps.google.com/?q=Palm+Meadows+Bangalore',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
          dressCode: 'Haldi Yellow Traditional',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'MUHURTHAM',
          name: 'Wedding Muhurtham',
          isEnabled: true,
          eventDate: DateTime(2026, 11, 15),
          startTime: '09:45:00',
          endTime: '12:30:00',
          venueName: 'Skyline Meadows Convention Hall',
          venueAddress: 'Silicon Valley Boulevard, Bangalore 560103',
          venueMapUrl: 'https://maps.google.com/?q=Skyline+Meadows+Bangalore',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552',
          dressCode: 'Kanjeevaram Silk & Traditional Dhoti',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'RECEPTION',
          name: 'Grand Wedding Reception',
          isEnabled: true,
          eventDate: DateTime(2026, 11, 15),
          startTime: '19:00:00',
          endTime: '23:00:00',
          venueName: 'Grand Ballroom, The Leela Palace',
          venueAddress: 'Old Airport Road, Bangalore 560008',
          venueMapUrl: 'https://maps.google.com/?q=The+Leela+Palace+Bangalore',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622',
          dressCode: 'Formal Evening Wear / Black Tie',
        ),
      ],
    );
    _submissions.add(sanviSantosh);

    // 2. Seed Pending Submission (Rahul & Sneha) ready for Admin Review & Flat Assignment
    final rahulSneha = MarriageSubmission(
      id: '104',
      referenceNumber: '#REG-2026-HYD-0104',
      status: 'PENDING_ADMIN_APPROVAL',
      submittedAt: DateTime(2026, 11, 12, 14, 20),
      userId: 101,
      bride: const BrideModel(
        name: 'Dr. Sneha Reddy',
        mobileNumber: '+919876543210',
        email: 'sneha.reddy@example.com',
        occupation: 'Pediatrician',
      ),
      groom: const GroomModel(
        name: 'Rahul Varma',
        mobileNumber: '+919848012345',
        email: 'rahul.varma@example.com',
        occupation: 'Senior Software Architect',
      ),
      primaryContactNumber: '+919848012345',
      secondaryContactNumber: '+919876543210',
      weddingDate: DateTime(2026, 12, 18),
      city: 'Hyderabad',
      coupleStory: 'We met during our university days in 2018. Over shared coffees and long architectural conversations, our dreams converged. As we step into our married life, your gift of a square foot lays the very foundation of our first home.',
      weddingCardUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552',
      coverImageUrl: 'https://images.unsplash.com/photo-1583939003579-730e3918a45a',
      targetBhk: '2 BHK',
      preferredArea: 'Gachibowli / Financial District, Hyderabad',
      functions: [
        CeremonyFunctionModel(
          ceremonyType: 'HALDI',
          name: 'Haldi & Mangala Snanam',
          isEnabled: true,
          eventDate: DateTime(2026, 12, 16),
          startTime: '09:30:00',
          endTime: '13:00:00',
          venueName: 'The Palm Meadows Lawns',
          venueAddress: 'Plot 12, Financial District, Nanakramguda, Hyderabad 500032',
          venueMapUrl: 'https://maps.google.com/?q=The+Palm+Meadows+Hyderabad',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
          dressCode: 'Yellow Traditional / Kurta & Kanjeevaram',
          notes: 'Followed by traditional lunch feast.',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'MEHENDI',
          name: 'Mehendi Ceremony',
          isEnabled: true,
          eventDate: DateTime(2026, 12, 16),
          startTime: '17:00:00',
          endTime: '21:30:00',
          venueName: 'The Palm Meadows Banquet Hall',
          venueAddress: 'Plot 12, Financial District, Nanakramguda, Hyderabad 500032',
          venueMapUrl: 'https://maps.google.com/?q=The+Palm+Meadows+Hyderabad',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd',
          dressCode: 'Floral & Pastel Hues',
          notes: 'Live mehendi artists and musical night.',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'SANGEET',
          name: 'Musical Sangeet & Cocktails',
          isEnabled: true,
          eventDate: DateTime(2026, 12, 17),
          startTime: '19:00:00',
          endTime: '23:30:00',
          venueName: 'Grand Ballroom, ITC Kohenur',
          venueAddress: 'HITEC City, Madhapur, Hyderabad 500081',
          venueMapUrl: 'https://maps.google.com/?q=ITC+Kohenur+Hyderabad',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1545232979-fbf67554904c',
          dressCode: 'Glamorous Indo-Western / Tuxedos & Lehengas',
          notes: 'Dance performances by family & friends.',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'MUHURTHAM',
          name: 'Wedding Muhurtham',
          isEnabled: true,
          eventDate: DateTime(2026, 12, 18),
          startTime: '09:45:00',
          endTime: '13:00:00',
          venueName: 'N-Convention Centre, Hall A',
          venueAddress: 'Lane Opp Cultural Centre, Madhapur, Hyderabad 500081',
          venueMapUrl: 'https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552',
          dressCode: 'Pure Silk Traditional Attire (Dhoti / Pattu Saree)',
          notes: 'Sumuhurtham at 10:24 AM sharp. Followed by traditional Andhra Vindu.',
        ),
        CeremonyFunctionModel(
          ceremonyType: 'RECEPTION',
          name: 'Grand Wedding Reception',
          isEnabled: true,
          eventDate: DateTime(2026, 12, 18),
          startTime: '19:30:00',
          endTime: '23:00:00',
          venueName: 'N-Convention Centre, Main Arena',
          venueAddress: 'Lane Opp Cultural Centre, Madhapur, Hyderabad 500081',
          venueMapUrl: 'https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad',
          ceremonyImageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622',
          dressCode: 'Formal Evening Wear / Black Tie',
          notes: 'Dinner and live orchestra.',
        ),
      ],
    );
    _submissions.add(rahulSneha);
  }

  // --- CRUD API METHODS (Local Storage Implementation) ---

  Future<MarriageSubmission> submitRegistration(MarriageSubmission submission) async {
    // Generate unique ID & reference number
    final newId = (_submissions.length + 101).toString();
    final year = DateTime.now().year;
    final cityCode = submission.city.trim().length >= 3
        ? submission.city.trim().substring(0, 3).toUpperCase()
        : 'HYD';
    final refNum = '#REG-$year-$cityCode-0$newId';

    final created = submission.copyWith(
      id: newId,
      referenceNumber: refNum,
      status: 'PENDING_ADMIN_APPROVAL',
      submittedAt: DateTime.now(),
    );

    _submissions.insert(0, created);
    debugPrint('[LocalStorage] Saved marriage submission: ${created.coupleTitle} (Ref: ${created.referenceNumber})');
    return created;
  }

  Future<List<MarriageSubmission>> getAllRegistrations({String? status}) async {
    if (status == null || status.isEmpty || status == 'ALL') {
      return List.unmodifiable(_submissions);
    }
    return _submissions.where((s) => s.status.toUpperCase() == status.toUpperCase()).toList();
  }

  Future<List<MarriageSubmission>> getMyRegistrations(int userId) async {
    return _submissions.where((s) => s.userId == userId || s.primaryContactNumber.contains('98480')).toList();
  }

  Future<MarriageSubmission?> getRegistrationById(String id) async {
    try {
      return _submissions.firstWhere((s) => s.id == id || s.referenceNumber.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<MarriageSubmission?> getRegistrationBySlug(String slug) async {
    final clean = slug.toLowerCase().trim();
    try {
      return _submissions.firstWhere(
        (s) => (s.slug != null && s.slug!.toLowerCase() == clean) ||
            s.referenceNumber.toLowerCase() == clean ||
            s.coupleTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').contains(clean),
      );
    } catch (_) {
      return null;
    }
  }

  Future<MarriageSubmission> approveAndAssignFlat({
    required String id,
    required AssignedFlatModel flat,
    required String slug,
    String? videoStreamUrl,
    MarriageSubmission? fallbackSubmission,
  }) async {
    final cleanId = id.trim().toLowerCase().replaceAll('#', '');
    int index = _submissions.indexWhere(
      (s) => s.id.trim().toLowerCase() == cleanId ||
             s.referenceNumber.trim().toLowerCase() == cleanId ||
             s.referenceNumber.trim().toLowerCase().replaceAll('#', '') == cleanId,
    );

    final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final shareUrl = 'https://plottheirfuture.in/weddings/$cleanSlug';
    final qrCodeUrl = 'https://cdn.plottheirfuture.in/qrcodes/$cleanSlug.png';

    if (index != -1) {
      final existing = _submissions[index];
      final approved = existing.copyWith(
        status: 'APPROVED',
        slug: cleanSlug,
        assignedFlat: flat,
        shareableUrl: shareUrl,
        qrCodeUrl: qrCodeUrl,
        videoStreamUrl: videoStreamUrl ?? existing.videoStreamUrl,
      );
      _submissions[index] = approved;
      debugPrint('[LocalStorage] Approved marriage submission: ${approved.coupleTitle} -> Slug: $cleanSlug');
      _syncWithWeddingRegistryRepository(approved);
      return approved;
    }

    if (fallbackSubmission != null) {
      final approved = fallbackSubmission.copyWith(
        status: 'APPROVED',
        slug: cleanSlug,
        assignedFlat: flat,
        shareableUrl: shareUrl,
        qrCodeUrl: qrCodeUrl,
        videoStreamUrl: videoStreamUrl ?? fallbackSubmission.videoStreamUrl,
      );
      _submissions.insert(0, approved);
      debugPrint('[LocalStorage] Upserted approved submission: ${approved.coupleTitle} (Ref: ${approved.referenceNumber})');
      _syncWithWeddingRegistryRepository(approved);
      return approved;
    }

    // Graceful fallback: construct new approved record instead of throwing
    final created = MarriageSubmission(
      id: id,
      referenceNumber: id.startsWith('#') ? id : '#$id',
      status: 'APPROVED',
      submittedAt: DateTime.now(),
      userId: 1,
      bride: const BrideModel(name: 'Bride', mobileNumber: '', email: ''),
      groom: const GroomModel(name: 'Groom', mobileNumber: '', email: ''),
      primaryContactNumber: '',
      secondaryContactNumber: '',
      weddingDate: DateTime.now().add(const Duration(days: 60)),
      city: 'Hyderabad',
      coupleStory: '',
      weddingCardUrl: '',
      functions: const [],
      targetBhk: flat.configuration,
      assignedFlat: flat,
      slug: cleanSlug,
      shareableUrl: shareUrl,
      qrCodeUrl: qrCodeUrl,
      videoStreamUrl: videoStreamUrl,
    );
    _submissions.insert(0, created);
    _syncWithWeddingRegistryRepository(created);
    return created;
  }

  Future<MarriageSubmission> rejectSubmission({
    required String id,
    required String reason,
    MarriageSubmission? fallbackSubmission,
  }) async {
    final cleanId = id.trim().toLowerCase().replaceAll('#', '');
    int index = _submissions.indexWhere(
      (s) => s.id.trim().toLowerCase() == cleanId ||
             s.referenceNumber.trim().toLowerCase() == cleanId ||
             s.referenceNumber.trim().toLowerCase().replaceAll('#', '') == cleanId,
    );

    if (index != -1) {
      final rejected = _submissions[index].copyWith(
        status: 'REJECTED',
        rejectionReason: reason,
      );
      _submissions[index] = rejected;
      return rejected;
    }

    if (fallbackSubmission != null) {
      final rejected = fallbackSubmission.copyWith(
        status: 'REJECTED',
        rejectionReason: reason,
      );
      _submissions.insert(0, rejected);
      return rejected;
    }

    final placeholder = MarriageSubmission(
      id: id,
      referenceNumber: id.startsWith('#') ? id : '#$id',
      status: 'REJECTED',
      rejectionReason: reason,
      submittedAt: DateTime.now(),
      userId: 1,
      bride: const BrideModel(name: 'Bride', mobileNumber: '', email: ''),
      groom: const GroomModel(name: 'Groom', mobileNumber: '', email: ''),
      primaryContactNumber: '',
      secondaryContactNumber: '',
      weddingDate: DateTime.now().add(const Duration(days: 60)),
      city: 'Hyderabad',
      coupleStory: '',
      weddingCardUrl: '',
      functions: const [],
      targetBhk: '2 BHK',
    );
    _submissions.insert(0, placeholder);
    return placeholder;
  }

  void _syncWithWeddingRegistryRepository(MarriageSubmission submission) {
    if (submission.slug == null || submission.assignedFlat == null) return;

    final weddingDetails = WeddingRegistryDetails(
      slug: submission.slug!,
      coupleName: '${submission.bride.name} & ${submission.groom.name}',
      location: '${submission.city} (${submission.assignedFlat!.projectName})',
      venue: submission.enabledFunctions.isNotEmpty ? submission.enabledFunctions.first.venueName : submission.city,
      date: submission.weddingDate,
      bhkType: '${submission.assignedFlat!.configuration} Registry',
      referenceId: submission.referenceNumber,
      totalSqFt: submission.assignedFlat!.targetSft,
      fundedSqFt: 0,
      imagePath: submission.coverImageUrl ?? 'assets/images/couple_portrait.jpg',
      quote: submission.coupleStory.isNotEmpty ? submission.coupleStory : 'Building our first home with love and blessings.',
    );

    // Insert or update in WeddingRegistryRepository
    WeddingRegistryRepository.registerNewWeddingDirect(weddingDetails);
  }
}
