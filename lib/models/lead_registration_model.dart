import 'package:intl/intl.dart';

class LeadRegistrationModel {
  final String requestId;
  final String coupleName;
  final String cityLocation;
  final String? venueName;
  final String phoneNumber;
  final DateTime eventDate;
  final String targetBhk;
  final DateTime createdAt;
  final String status;

  const LeadRegistrationModel({
    required this.requestId,
    required this.coupleName,
    required this.cityLocation,
    this.venueName,
    required this.phoneNumber,
    required this.eventDate,
    this.targetBhk = '2 BHK',
    required this.createdAt,
    this.status = 'Pending Concierge Call (2-Hour SLA)',
  });

  String get slug {
    final clean = coupleName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return clean.isEmpty ? 'wedding-registry' : clean;
  }

  String get shareUrl => 'https://plottheirfuture.in/w/$slug?ref=${Uri.encodeComponent(requestId)}';

  String get deepLinkUri => 'plottheirfuture://w/$slug?ref=${Uri.encodeComponent(requestId)}';

  String get shareMessage {
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(eventDate);
    final venueStr = venueName != null && venueName!.isNotEmpty ? ' ($venueName)' : '';
    return '''🏡 Plot Their Future • Wedding Gift Registry
We are thrilled to invite you to celebrate the marriage of $coupleName!

Instead of boxed appliances, join hands with us to gift a square foot of our first home!

📍 Venue: $cityLocation$venueStr
📅 Wedding Date: $dateStr
🎯 Target: $targetBhk Down Payment Registry

👉 Tap to open the Wedding Registry, Itinerary & RSVP:
$shareUrl''';
  }

  static String generateRequestId() {
    final year = DateTime.now().year;
    final randomDigits = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    return '#PTF-$year-$randomDigits';
  }
}


