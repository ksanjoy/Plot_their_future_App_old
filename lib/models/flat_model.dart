// ignore_for_file: constant_identifier_names

enum FlatStatus {
  DRAFT,
  PENDING_APPROVAL,
  APPROVED,
  ASSIGNED,
  COMPLETED;

  static FlatStatus fromString(String? val) {
    if (val == null) return FlatStatus.DRAFT;
    switch (val.toUpperCase().trim()) {
      case 'PENDING_APPROVAL':
        return FlatStatus.PENDING_APPROVAL;
      case 'APPROVED':
        return FlatStatus.APPROVED;
      case 'ASSIGNED':
        return FlatStatus.ASSIGNED;
      case 'COMPLETED':
        return FlatStatus.COMPLETED;
      default:
        return FlatStatus.DRAFT;
    }
  }

  String get label {
    switch (this) {
      case FlatStatus.DRAFT:
        return 'Draft';
      case FlatStatus.PENDING_APPROVAL:
        return 'Pending Approval';
      case FlatStatus.APPROVED:
        return 'Approved';
      case FlatStatus.ASSIGNED:
        return 'Assigned';
      case FlatStatus.COMPLETED:
        return 'Completed';
    }
  }
}

class FlatSectionModel {
  final int? id;
  final int flatId;
  final String sectionName;
  final String sectionImageUrl;
  final String? description;
  final int areaSft;
  final double? lengthFt;
  final double? widthFt;
  final double pricePerSft;
  final double totalPrice;
  final int giftedSft;
  final int remainingSft;
  final int brickEquivalent;
  final double giftProgressPercent;
  final String? svgElementId;

  const FlatSectionModel({
    this.id,
    required this.flatId,
    required this.sectionName,
    this.sectionImageUrl = 'assets/images/apartment_poster.jpg',
    this.description,
    required this.areaSft,
    this.lengthFt,
    this.widthFt,
    required this.pricePerSft,
    required this.totalPrice,
    this.giftedSft = 0,
    this.remainingSft = 0,
    this.brickEquivalent = 0,
    this.giftProgressPercent = 0.0,
    this.svgElementId,
  });

  factory FlatSectionModel.fromJson(Map<String, dynamic> json) {
    final area = json['areaSft'] is int ? json['areaSft'] as int : int.tryParse(json['areaSft']?.toString() ?? '0') ?? 0;
    final gifted = json['giftedSft'] is int ? json['giftedSft'] as int : int.tryParse(json['giftedSft']?.toString() ?? '0') ?? 0;
    final price = (json['pricePerSft'] is num) ? (json['pricePerSft'] as num).toDouble() : double.tryParse(json['pricePerSft']?.toString() ?? '4500') ?? 4500.0;
    final total = (json['totalPrice'] is num) ? (json['totalPrice'] as num).toDouble() : (area * price);
    final remaining = json['remainingSft'] is int ? json['remainingSft'] as int : (area - gifted);
    final bricks = json['brickEquivalent'] is int ? json['brickEquivalent'] as int : (area * 10);
    final progress = (json['giftProgressPercent'] is num) ? (json['giftProgressPercent'] as num).toDouble() : (area > 0 ? (gifted / area) * 100 : 0.0);

    return FlatSectionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      flatId: json['flatId'] is int ? json['flatId'] as int : int.tryParse(json['flatId']?.toString() ?? '0') ?? 0,
      sectionName: json['sectionName']?.toString() ?? 'Section',
      sectionImageUrl: json['sectionImageUrl']?.toString() ?? 'assets/images/apartment_poster.jpg',
      description: json['description']?.toString(),
      areaSft: area,
      lengthFt: (json['lengthFt'] is num) ? (json['lengthFt'] as num).toDouble() : double.tryParse(json['lengthFt']?.toString() ?? ''),
      widthFt: (json['widthFt'] is num) ? (json['widthFt'] as num).toDouble() : double.tryParse(json['widthFt']?.toString() ?? ''),
      pricePerSft: price,
      totalPrice: total,
      giftedSft: gifted,
      remainingSft: remaining < 0 ? 0 : remaining,
      brickEquivalent: bricks,
      giftProgressPercent: progress,
      svgElementId: json['svgElementId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flatId': flatId,
      'sectionName': sectionName,
      'sectionImageUrl': sectionImageUrl,
      'description': description,
      'areaSft': areaSft,
      'lengthFt': lengthFt,
      'widthFt': widthFt,
      'pricePerSft': pricePerSft,
      'totalPrice': totalPrice,
      'giftedSft': giftedSft,
      'svgElementId': svgElementId,
    };
  }
}

class FlatModel {
  final int id;
  final String flatId;
  final String name;
  final String? description;
  final String coverImageUrl;
  final List<String> galleryImages;
  final int builtUpAreaSft;
  final int carpetAreaSft;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int halls;
  final int kitchens;
  final String location;
  final String address;
  final double pricePerSft;
  final int bricksPerSft;
  final double pricePerBrick;
  final FlatStatus status;
  final int? assignedWeddingId;
  final String? assignedWeddingSlug;
  final String? rejectionReason;
  final List<FlatSectionModel> sections;
  final int totalSectionArea;
  final bool areaMatches;
  final int totalGiftedSft;
  final int totalRemainingSft;
  final double totalTargetAmount;
  final double totalGiftedAmount;
  final int totalBricksEquivalent;

  const FlatModel({
    required this.id,
    required this.flatId,
    required this.name,
    this.description,
    this.coverImageUrl = 'assets/images/apartment_poster.jpg',
    this.galleryImages = const [],
    required this.builtUpAreaSft,
    required this.carpetAreaSft,
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.balconies = 1,
    this.halls = 1,
    this.kitchens = 1,
    this.location = 'Hyderabad',
    this.address = '',
    this.pricePerSft = 4500.0,
    this.bricksPerSft = 10,
    this.pricePerBrick = 450.0,
    this.status = FlatStatus.DRAFT,
    this.assignedWeddingId,
    this.assignedWeddingSlug,
    this.rejectionReason,
    this.sections = const [],
    this.totalSectionArea = 0,
    this.areaMatches = false,
    this.totalGiftedSft = 0,
    this.totalRemainingSft = 0,
    this.totalTargetAmount = 0.0,
    this.totalGiftedAmount = 0.0,
    this.totalBricksEquivalent = 0,
  });

  factory FlatModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final sectionsList = rawSections
        .map((s) => FlatSectionModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final builtUp = json['builtUpAreaSft'] is int ? json['builtUpAreaSft'] as int : int.tryParse(json['builtUpAreaSft']?.toString() ?? '1200') ?? 1200;
    final carpet = json['carpetAreaSft'] is int ? json['carpetAreaSft'] as int : int.tryParse(json['carpetAreaSft']?.toString() ?? '980') ?? 980;
    final price = (json['pricePerSft'] is num) ? (json['pricePerSft'] as num).toDouble() : double.tryParse(json['pricePerSft']?.toString() ?? '4500') ?? 4500.0;
    final bPerSft = json['bricksPerSft'] is int ? json['bricksPerSft'] as int : int.tryParse(json['bricksPerSft']?.toString() ?? '10') ?? 10;
    final pPerBrick = (json['pricePerBrick'] is num) ? (json['pricePerBrick'] as num).toDouble() : (price / bPerSft);

    final rawGallery = json['galleryImages'] as List<dynamic>? ?? [];
    final galleryList = rawGallery.map((e) => e.toString()).toList();

    final totalSecArea = json['totalSectionArea'] is int
        ? json['totalSectionArea'] as int
        : sectionsList.fold<int>(0, (sum, sec) => sum + sec.areaSft);

    final totalGifted = json['totalGiftedSft'] is int
        ? json['totalGiftedSft'] as int
        : sectionsList.fold<int>(0, (sum, sec) => sum + sec.giftedSft);

    final totalRemaining = json['totalRemainingSft'] is int
        ? json['totalRemainingSft'] as int
        : (builtUp - totalGifted);

    return FlatModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      flatId: json['flatId']?.toString() ?? 'FLAT-2026-HYD-001',
      name: json['name']?.toString() ?? 'Premium Residence',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? 'assets/images/apartment_poster.jpg',
      galleryImages: galleryList,
      builtUpAreaSft: builtUp,
      carpetAreaSft: carpet,
      bedrooms: json['bedrooms'] is int ? json['bedrooms'] as int : int.tryParse(json['bedrooms']?.toString() ?? '2') ?? 2,
      bathrooms: json['bathrooms'] is int ? json['bathrooms'] as int : int.tryParse(json['bathrooms']?.toString() ?? '2') ?? 2,
      balconies: json['balconies'] is int ? json['balconies'] as int : int.tryParse(json['balconies']?.toString() ?? '1') ?? 1,
      halls: json['halls'] is int ? json['halls'] as int : int.tryParse(json['halls']?.toString() ?? '1') ?? 1,
      kitchens: json['kitchens'] is int ? json['kitchens'] as int : int.tryParse(json['kitchens']?.toString() ?? '1') ?? 1,
      location: json['location']?.toString() ?? 'Hyderabad',
      address: json['address']?.toString() ?? '',
      pricePerSft: price,
      bricksPerSft: bPerSft,
      pricePerBrick: pPerBrick,
      status: FlatStatus.fromString(json['status']?.toString()),
      assignedWeddingId: json['assignedWeddingId'] is int ? json['assignedWeddingId'] as int : int.tryParse(json['assignedWeddingId']?.toString() ?? ''),
      assignedWeddingSlug: json['assignedWeddingSlug']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      sections: sectionsList,
      totalSectionArea: totalSecArea,
      areaMatches: json['areaMatches'] == true || (totalSecArea == builtUp),
      totalGiftedSft: totalGifted,
      totalRemainingSft: totalRemaining < 0 ? 0 : totalRemaining,
      totalTargetAmount: (json['totalTargetAmount'] is num) ? (json['totalTargetAmount'] as num).toDouble() : (builtUp * price),
      totalGiftedAmount: (json['totalGiftedAmount'] is num) ? (json['totalGiftedAmount'] as num).toDouble() : (totalGifted * price),
      totalBricksEquivalent: json['totalBricksEquivalent'] is int ? json['totalBricksEquivalent'] as int : (builtUp * bPerSft),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flatId': flatId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'galleryImages': galleryImages,
      'builtUpAreaSft': builtUpAreaSft,
      'carpetAreaSft': carpetAreaSft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'balconies': balconies,
      'halls': halls,
      'kitchens': kitchens,
      'location': location,
      'address': address,
      'pricePerSft': pricePerSft,
      'bricksPerSft': bricksPerSft,
      'pricePerBrick': pricePerBrick,
      'status': status.name,
      'assignedWeddingId': assignedWeddingId,
      'assignedWeddingSlug': assignedWeddingSlug,
      'rejectionReason': rejectionReason,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }
}
