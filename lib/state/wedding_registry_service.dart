import 'package:flutter/material.dart';
import '../models/lead_registration_model.dart';
import '../screens/home_screen.dart';

class WeddingRegistryDetails {
  final String slug;
  final String coupleName;
  final String location;
  final String venue;
  final DateTime date;
  final String bhkType;
  final String referenceId;
  final int totalSqFt;
  final int fundedSqFt;
  final String imagePath;
  final String quote;

  const WeddingRegistryDetails({
    required this.slug,
    required this.coupleName,
    required this.location,
    required this.venue,
    required this.date,
    required this.bhkType,
    required this.referenceId,
    required this.totalSqFt,
    required this.fundedSqFt,
    required this.imagePath,
    required this.quote,
  });

  String get shareUrl => 'https://plottheirfuture.in/w/$slug?ref=${Uri.encodeComponent(referenceId)}';
  String get deepLinkUri => 'plottheirfuture://w/$slug?ref=${Uri.encodeComponent(referenceId)}';

  String get shareMessage => '''🏡 Plot Their Future • Wedding Gift Registry
We are thrilled to invite you to celebrate the marriage of $coupleName!

Instead of boxed gifts, join hands with us to gift a square foot of their first home!

📍 Location: $location ($venue)
📅 Wedding Date: ${formatDate(date)}
🎯 Target: $bhkType Down Payment Registry ($fundedSqFt / $totalSqFt SFT Funded)

👉 Tap to open the Wedding Registry, Itinerary & RSVP:
$shareUrl''';

  static String formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class WeddingRegistryRepository {
  static final List<WeddingRegistryDetails> _weddings = [
    WeddingRegistryDetails(
      slug: 'sanvi-santosh',
      coupleName: 'Sanvi Rao & Santosh Kumar',
      location: 'Silicon Valley, Bangalore',
      venue: 'Skyline Meadows Clubhouse',
      date: DateTime(2026, 11, 15, 5, 45),
      bhkType: '2 BHK Registry',
      referenceId: '#PTF-2026-0420',
      totalSqFt: 1200,
      fundedSqFt: 420,
      imagePath: 'assets/images/couple_portrait.jpg',
      quote: 'Building our first home with the love and blessings of family.',
    ),
    WeddingRegistryDetails(
      slug: 'rahul-sneha',
      coupleName: 'Rahul Reddy & Sneha Varma',
      location: 'Gachibowli, Hyderabad',
      venue: 'N-Convention Centre',
      date: DateTime(2026, 12, 12, 8, 30),
      bhkType: '3 BHK Registry',
      referenceId: '#PTF-2026-9812',
      totalSqFt: 1850,
      fundedSqFt: 280,
      imagePath: 'assets/images/qr_banner.jpg',
      quote: 'Laying the foundation of generational memories together.',
    ),
    WeddingRegistryDetails(
      slug: 'vikram-ananya',
      coupleName: 'Vikram & Ananya',
      location: 'Madhapur, Hyderabad',
      venue: 'Lakeview Grand Hall',
      date: DateTime(2027, 1, 18, 10, 15),
      bhkType: '2 BHK Registry',
      referenceId: '#PTF-2027-1102',
      totalSqFt: 1200,
      fundedSqFt: 110,
      imagePath: 'assets/images/hero_banner.jpg',
      quote: 'A home built square foot by square foot with blessings.',
    ),
  ];

  static List<WeddingRegistryDetails> get allWeddings => List.unmodifiable(_weddings);

  static void registerNewWeddingDirect(WeddingRegistryDetails wedding) {
    _weddings.removeWhere((w) => w.slug == wedding.slug);
    _weddings.insert(0, wedding);
  }

  static WeddingRegistryDetails registerNewWedding(LeadRegistrationModel lead) {
    final newWedding = WeddingRegistryDetails(
      slug: lead.slug,
      coupleName: lead.coupleName,
      location: lead.cityLocation,
      venue: lead.venueName ?? 'Convention Centre',
      date: lead.eventDate,
      bhkType: '${lead.targetBhk} Registry',
      referenceId: lead.requestId,
      totalSqFt: lead.targetBhk.contains('3') ? 1850 : 1200,
      fundedSqFt: 0,
      imagePath: 'assets/images/qr_banner.jpg',
      quote: 'Thank you for gifting square feet toward our first home down payment.',
    );

    // Insert at front
    _weddings.removeWhere((w) => w.slug == newWedding.slug);
    _weddings.insert(0, newWedding);
    return newWedding;
  }

  static WeddingRegistryDetails? findBySlugOrUrl(String input) {
    if (input.trim().isEmpty) return null;
    final clean = input.trim();

    // Check if it's a full URL
    Uri? uri = Uri.tryParse(clean);
    String targetSlug = clean;
    if (uri != null) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'w' && uri.pathSegments.length > 1) {
        targetSlug = uri.pathSegments[1];
      } else if (uri.host == 'w' && uri.pathSegments.isNotEmpty) {
        targetSlug = uri.pathSegments.first;
      }
    }

    targetSlug = targetSlug
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    for (final w in _weddings) {
      if (w.slug == targetSlug ||
          w.referenceId.toLowerCase() == clean.toLowerCase() ||
          w.coupleName.toLowerCase().contains(clean.toLowerCase())) {
        return w;
      }
    }

    // Default to first if slug matches partially
    for (final w in _weddings) {
      if (targetSlug.contains(w.slug) || w.slug.contains(targetSlug)) {
        return w;
      }
    }

    return null;
  }

  static void openWedding(BuildContext context, WeddingRegistryDetails wedding) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          customWedding: wedding,
        ),
      ),
    );
  }
}
