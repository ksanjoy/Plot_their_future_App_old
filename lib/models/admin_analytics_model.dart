class SectionWiseBreakdown {
  final String sectionName;
  final int totalSft;
  final int giftedSft;
  final double amountGifted;

  const SectionWiseBreakdown({
    required this.sectionName,
    required this.totalSft,
    required this.giftedSft,
    required this.amountGifted,
  });

  factory SectionWiseBreakdown.fromJson(Map<String, dynamic> json) {
    return SectionWiseBreakdown(
      sectionName: json['sectionName']?.toString() ?? 'Section',
      totalSft: json['totalSft'] is int ? json['totalSft'] as int : int.tryParse(json['totalSft']?.toString() ?? '0') ?? 0,
      giftedSft: json['giftedSft'] is int ? json['giftedSft'] as int : int.tryParse(json['giftedSft']?.toString() ?? '0') ?? 0,
      amountGifted: (json['amountGifted'] is num) ? (json['amountGifted'] as num).toDouble() : double.tryParse(json['amountGifted']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class FlatWiseProgress {
  final String flatId;
  final String name;
  final String status;
  final int totalSft;
  final int giftedSft;
  final int remainingSft;
  final double progressPercent;

  const FlatWiseProgress({
    required this.flatId,
    required this.name,
    required this.status,
    required this.totalSft,
    required this.giftedSft,
    required this.remainingSft,
    required this.progressPercent,
  });

  factory FlatWiseProgress.fromJson(Map<String, dynamic> json) {
    return FlatWiseProgress(
      flatId: json['flatId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      totalSft: json['totalSft'] is int ? json['totalSft'] as int : int.tryParse(json['totalSft']?.toString() ?? '0') ?? 0,
      giftedSft: json['giftedSft'] is int ? json['giftedSft'] as int : int.tryParse(json['giftedSft']?.toString() ?? '0') ?? 0,
      remainingSft: json['remainingSft'] is int ? json['remainingSft'] as int : int.tryParse(json['remainingSft']?.toString() ?? '0') ?? 0,
      progressPercent: (json['progressPercent'] is num) ? (json['progressPercent'] as num).toDouble() : double.tryParse(json['progressPercent']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AdminAnalyticsModel {
  final int totalRegisteredFlats;
  final int approvedFlats;
  final int pendingApprovalFlats;
  final int assignedFlats;
  final int draftFlats;
  final int totalWeddings;
  final int totalBuiltUpAreaSft;
  final int totalGiftedSqFt;
  final int totalRemainingSqFt;
  final double totalGiftAmount;
  final int totalBrickEquivalentGifted;
  final List<SectionWiseBreakdown> sectionWiseBreakdown;
  final List<FlatWiseProgress> flatWiseProgress;

  const AdminAnalyticsModel({
    required this.totalRegisteredFlats,
    required this.approvedFlats,
    required this.pendingApprovalFlats,
    required this.assignedFlats,
    required this.draftFlats,
    required this.totalWeddings,
    required this.totalBuiltUpAreaSft,
    required this.totalGiftedSqFt,
    required this.totalRemainingSqFt,
    required this.totalGiftAmount,
    required this.totalBrickEquivalentGifted,
    this.sectionWiseBreakdown = const [],
    this.flatWiseProgress = const [],
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sectionWiseBreakdown'] as List<dynamic>? ?? [];
    final sections = rawSections
        .map((s) => SectionWiseBreakdown.fromJson(s as Map<String, dynamic>))
        .toList();

    final rawFlats = json['flatWiseProgress'] as List<dynamic>? ?? [];
    final flats = rawFlats
        .map((f) => FlatWiseProgress.fromJson(f as Map<String, dynamic>))
        .toList();

    return AdminAnalyticsModel(
      totalRegisteredFlats: json['totalRegisteredFlats'] is int ? json['totalRegisteredFlats'] as int : int.tryParse(json['totalRegisteredFlats']?.toString() ?? '0') ?? 0,
      approvedFlats: json['approvedFlats'] is int ? json['approvedFlats'] as int : int.tryParse(json['approvedFlats']?.toString() ?? '0') ?? 0,
      pendingApprovalFlats: json['pendingApprovalFlats'] is int ? json['pendingApprovalFlats'] as int : int.tryParse(json['pendingApprovalFlats']?.toString() ?? '0') ?? 0,
      assignedFlats: json['assignedFlats'] is int ? json['assignedFlats'] as int : int.tryParse(json['assignedFlats']?.toString() ?? '0') ?? 0,
      draftFlats: json['draftFlats'] is int ? json['draftFlats'] as int : int.tryParse(json['draftFlats']?.toString() ?? '0') ?? 0,
      totalWeddings: json['totalWeddings'] is int ? json['totalWeddings'] as int : int.tryParse(json['totalWeddings']?.toString() ?? '0') ?? 0,
      totalBuiltUpAreaSft: json['totalBuiltUpAreaSft'] is int ? json['totalBuiltUpAreaSft'] as int : int.tryParse(json['totalBuiltUpAreaSft']?.toString() ?? '0') ?? 0,
      totalGiftedSqFt: json['totalGiftedSqFt'] is int ? json['totalGiftedSqFt'] as int : int.tryParse(json['totalGiftedSqFt']?.toString() ?? '0') ?? 0,
      totalRemainingSqFt: json['totalRemainingSqFt'] is int ? json['totalRemainingSqFt'] as int : int.tryParse(json['totalRemainingSqFt']?.toString() ?? '0') ?? 0,
      totalGiftAmount: (json['totalGiftAmount'] is num) ? (json['totalGiftAmount'] as num).toDouble() : double.tryParse(json['totalGiftAmount']?.toString() ?? '0') ?? 0.0,
      totalBrickEquivalentGifted: json['totalBrickEquivalentGifted'] is int ? json['totalBrickEquivalentGifted'] as int : int.tryParse(json['totalBrickEquivalentGifted']?.toString() ?? '0') ?? 0,
      sectionWiseBreakdown: sections,
      flatWiseProgress: flats,
    );
  }
}
