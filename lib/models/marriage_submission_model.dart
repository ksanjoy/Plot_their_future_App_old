import 'package:intl/intl.dart';

class BrideModel {
  final String name;
  final String mobileNumber;
  final String? email;
  final String? occupation;

  const BrideModel({
    required this.name,
    required this.mobileNumber,
    this.email,
    this.occupation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobileNumber': mobileNumber,
        'email': email,
        'occupation': occupation,
      };

  factory BrideModel.fromJson(Map<String, dynamic> json) => BrideModel(
        name: json['name'] ?? '',
        mobileNumber: json['mobileNumber'] ?? '',
        email: json['email'],
        occupation: json['occupation'],
      );
}

class GroomModel {
  final String name;
  final String mobileNumber;
  final String? email;
  final String? occupation;

  const GroomModel({
    required this.name,
    required this.mobileNumber,
    this.email,
    this.occupation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobileNumber': mobileNumber,
        'email': email,
        'occupation': occupation,
      };

  factory GroomModel.fromJson(Map<String, dynamic> json) => GroomModel(
        name: json['name'] ?? '',
        mobileNumber: json['mobileNumber'] ?? '',
        email: json['email'],
        occupation: json['occupation'],
      );
}

class CeremonyFunctionModel {
  final String ceremonyType; // HALDI, MEHENDI, SANGEET, ENGAGEMENT, PELLIKUTHURU, PELLIKODUKU, MUHURTHAM, RECEPTION, CUSTOM
  final String name;
  final bool isEnabled;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String venueName;
  final String venueAddress;
  final String? venueMapUrl;
  final String? ceremonyImageUrl;
  final String? dressCode;
  final String? notes;

  const CeremonyFunctionModel({
    required this.ceremonyType,
    required this.name,
    required this.isEnabled,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.venueName,
    required this.venueAddress,
    this.venueMapUrl,
    this.ceremonyImageUrl,
    this.dressCode,
    this.notes,
  });

  CeremonyFunctionModel copyWith({
    String? ceremonyType,
    String? name,
    bool? isEnabled,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? venueName,
    String? venueAddress,
    String? venueMapUrl,
    String? ceremonyImageUrl,
    String? dressCode,
    String? notes,
  }) {
    return CeremonyFunctionModel(
      ceremonyType: ceremonyType ?? this.ceremonyType,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      venueMapUrl: venueMapUrl ?? this.venueMapUrl,
      ceremonyImageUrl: ceremonyImageUrl ?? this.ceremonyImageUrl,
      dressCode: dressCode ?? this.dressCode,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'ceremonyType': ceremonyType,
        'name': name,
        'isEnabled': isEnabled,
        'eventDate': DateFormat('yyyy-MM-dd').format(eventDate),
        'startTime': startTime,
        'endTime': endTime,
        'venueName': venueName,
        'venueAddress': venueAddress,
        'venueMapUrl': venueMapUrl,
        'ceremonyImageUrl': ceremonyImageUrl,
        'dressCode': dressCode,
        'notes': notes,
      };

  factory CeremonyFunctionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final rawDate = json['eventDate'] ?? json['event_date'];
      parsedDate = rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawEnabled = json['isEnabled'] ?? json['is_enabled'] ?? json['enabled'];
    final bool parsedEnabled = rawEnabled == true || rawEnabled == 1 || rawEnabled == 'true';

    final rawStartTime = json['startTime'] ?? json['start_time'];
    String parsedStart = '10:00:00';
    if (rawStartTime != null && rawStartTime.toString().isNotEmpty) {
      parsedStart = rawStartTime.toString();
    } else if (json['timeSlot'] != null && json['timeSlot'].toString().contains('-')) {
      parsedStart = json['timeSlot'].toString().split('-').first.trim();
    }

    final rawEndTime = json['endTime'] ?? json['end_time'];
    String parsedEnd = '13:00:00';
    if (rawEndTime != null && rawEndTime.toString().isNotEmpty) {
      parsedEnd = rawEndTime.toString();
    } else if (json['timeSlot'] != null && json['timeSlot'].toString().contains('-')) {
      parsedEnd = json['timeSlot'].toString().split('-').last.trim();
    }

    return CeremonyFunctionModel(
      ceremonyType: json['ceremonyType']?.toString() ?? json['ceremony_type']?.toString() ?? 'CUSTOM',
      name: json['name']?.toString() ?? '',
      isEnabled: rawEnabled != null ? parsedEnabled : true,
      eventDate: parsedDate,
      startTime: parsedStart,
      endTime: parsedEnd,
      venueName: json['venueName']?.toString() ?? json['venue_name']?.toString() ?? '',
      venueAddress: json['venueAddress']?.toString() ?? json['venue_address']?.toString() ?? '',
      venueMapUrl: json['venueMapUrl']?.toString() ?? json['venue_map_url']?.toString(),
      ceremonyImageUrl: json['ceremonyImageUrl']?.toString() ?? json['ceremony_image_url']?.toString(),
      dressCode: json['dressCode']?.toString() ?? json['dress_code']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class EscrowBankModel {
  final String bankName;
  final String? branchName;
  final String accountHolder;
  final String accountNumber;
  final String ifscCode;
  final String? upiVpa;

  const EscrowBankModel({
    required this.bankName,
    this.branchName,
    required this.accountHolder,
    required this.accountNumber,
    required this.ifscCode,
    this.upiVpa,
  });

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'branchName': branchName,
        'accountHolder': accountHolder,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'upiVpa': upiVpa,
      };

  factory EscrowBankModel.fromJson(Map<String, dynamic> json) => EscrowBankModel(
        bankName: json['bankName'] ?? 'HDFC Bank Ltd',
        branchName: json['branchName'],
        accountHolder: json['accountHolder'] ?? 'PlotTheirFuture Escrow Account',
        accountNumber: json['accountNumber'] ?? 'ESC-HDFC-99201948102',
        ifscCode: json['ifscCode'] ?? 'HDFC0000456',
        upiVpa: json['upiVpa'],
      );
}

class AssignedFlatModel {
  final String builderName;
  final String projectName;
  final String tower;
  final String unitNumber;
  final String configuration; // 2 BHK, 3 BHK, 4 BHK
  final int targetSft;
  final double rateSft;
  final double totalTargetAmountInr;
  final String builderReraId;
  final String? reraProjectUrl;
  final EscrowBankModel escrowBank;

  const AssignedFlatModel({
    required this.builderName,
    required this.projectName,
    required this.tower,
    required this.unitNumber,
    required this.configuration,
    required this.targetSft,
    required this.rateSft,
    required this.totalTargetAmountInr,
    required this.builderReraId,
    this.reraProjectUrl,
    required this.escrowBank,
  });

  Map<String, dynamic> toJson() => {
        'builderName': builderName,
        'projectName': projectName,
        'tower': tower,
        'unitNumber': unitNumber,
        'configuration': configuration,
        'targetSft': targetSft,
        'rateSft': rateSft,
        'totalTargetAmountInr': totalTargetAmountInr,
        'builderReraId': builderReraId,
        'reraProjectUrl': reraProjectUrl,
        'escrowBank': escrowBank.toJson(),
      };

  factory AssignedFlatModel.fromJson(Map<String, dynamic> json) => AssignedFlatModel(
        builderName: json['builderName'] ?? '',
        projectName: json['projectName'] ?? '',
        tower: json['tower'] ?? '',
        unitNumber: json['unitNumber'] ?? '',
        configuration: json['configuration'] ?? '2 BHK',
        targetSft: json['targetSft'] ?? 1200,
        rateSft: (json['rateSft'] as num?)?.toDouble() ?? 4500.0,
        totalTargetAmountInr: (json['totalTargetAmountInr'] as num?)?.toDouble() ?? 5400000.0,
        builderReraId: json['builderReraId'] ?? '',
        reraProjectUrl: json['reraProjectUrl'],
        escrowBank: json['escrowBank'] != null
            ? EscrowBankModel.fromJson(json['escrowBank'])
            : const EscrowBankModel(
                bankName: 'HDFC Bank Ltd',
                accountHolder: 'PlotTheirFuture Escrow Account',
                accountNumber: 'ESC-HDFC-99201948102',
                ifscCode: 'HDFC0000456',
              ),
      );
}

class MarriageSubmission {
  final String id;
  final String referenceNumber;
  final String status; // PENDING_ADMIN_APPROVAL, APPROVED, ACTIVE, REJECTED
  final DateTime submittedAt;
  final int userId;
  final BrideModel bride;
  final GroomModel groom;
  final String primaryContactNumber;
  final String secondaryContactNumber;
  final DateTime weddingDate;
  final String city;
  final String coupleStory;
  final String weddingCardUrl;
  final String? weddingCardThumbnailUrl;
  final String? coverImageUrl;
  final String targetBhk;
  final String preferredArea;
  final List<CeremonyFunctionModel> functions;
  final AssignedFlatModel? assignedFlat;
  final String? slug;
  final String? shareableUrl;
  final String? qrCodeUrl;
  final String? videoStreamUrl;
  final String? invitationVideoUrl;
  final String? rejectionReason;
  final int? weddingId;

  const MarriageSubmission({
    required this.id,
    required this.referenceNumber,
    required this.status,
    required this.submittedAt,
    required this.userId,
    required this.bride,
    required this.groom,
    required this.primaryContactNumber,
    required this.secondaryContactNumber,
    required this.weddingDate,
    required this.city,
    required this.coupleStory,
    required this.weddingCardUrl,
    this.weddingCardThumbnailUrl,
    this.coverImageUrl,
    this.targetBhk = '2 BHK',
    this.preferredArea = 'Hyderabad',
    required this.functions,
    this.assignedFlat,
    this.slug,
    this.shareableUrl,
    this.qrCodeUrl,
    this.videoStreamUrl,
    this.invitationVideoUrl,
    this.rejectionReason,
    this.weddingId,
  });

  String get coupleTitle => '${groom.name.split(" ").first} & ${bride.name.split(" ").first}';

  bool get isApproved => status == 'APPROVED' || status == 'ACTIVE';

  List<CeremonyFunctionModel> get enabledFunctions => functions.where((f) => f.isEnabled).toList();

  MarriageSubmission copyWith({
    String? id,
    String? referenceNumber,
    String? status,
    DateTime? submittedAt,
    int? userId,
    BrideModel? bride,
    GroomModel? groom,
    String? primaryContactNumber,
    String? secondaryContactNumber,
    DateTime? weddingDate,
    String? city,
    String? coupleStory,
    String? weddingCardUrl,
    String? weddingCardThumbnailUrl,
    String? coverImageUrl,
    String? targetBhk,
    String? preferredArea,
    List<CeremonyFunctionModel>? functions,
    AssignedFlatModel? assignedFlat,
    String? slug,
    String? shareableUrl,
    String? qrCodeUrl,
    String? videoStreamUrl,
    String? invitationVideoUrl,
    String? rejectionReason,
  }) {
    return MarriageSubmission(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      userId: userId ?? this.userId,
      bride: bride ?? this.bride,
      groom: groom ?? this.groom,
      primaryContactNumber: primaryContactNumber ?? this.primaryContactNumber,
      secondaryContactNumber: secondaryContactNumber ?? this.secondaryContactNumber,
      weddingDate: weddingDate ?? this.weddingDate,
      city: city ?? this.city,
      coupleStory: coupleStory ?? this.coupleStory,
      weddingCardUrl: weddingCardUrl ?? this.weddingCardUrl,
      weddingCardThumbnailUrl: weddingCardThumbnailUrl ?? this.weddingCardThumbnailUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      targetBhk: targetBhk ?? this.targetBhk,
      preferredArea: preferredArea ?? this.preferredArea,
      functions: functions ?? this.functions,
      assignedFlat: assignedFlat ?? this.assignedFlat,
      slug: slug ?? this.slug,
      shareableUrl: shareableUrl ?? this.shareableUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      videoStreamUrl: videoStreamUrl ?? this.videoStreamUrl,
      invitationVideoUrl: invitationVideoUrl ?? this.invitationVideoUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      weddingId: weddingId ?? this.weddingId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
        'userId': userId,
        'bride': bride.toJson(),
        'groom': groom.toJson(),
        'primaryContactNumber': primaryContactNumber,
        'secondaryContactNumber': secondaryContactNumber,
        'weddingDate': DateFormat('yyyy-MM-dd').format(weddingDate),
        'city': city,
        'coupleStory': coupleStory,
        'weddingCardUrl': weddingCardUrl,
        'weddingCardThumbnailUrl': weddingCardThumbnailUrl,
        'coverImageUrl': coverImageUrl,
        'targetBhk': targetBhk,
        'preferredArea': preferredArea,
        'functions': functions.map((f) => f.toJson()).toList(),
        'assignedFlat': assignedFlat?.toJson(),
        'slug': slug,
        'shareableUrl': shareableUrl,
        'qrCodeUrl': qrCodeUrl,
        'videoStreamUrl': videoStreamUrl ?? invitationVideoUrl,
        'invitationVideoUrl': invitationVideoUrl ?? videoStreamUrl,
        'rejectionReason': rejectionReason,
        'weddingId': weddingId ?? 5,
        'wedding_id': weddingId ?? 5,
      };

  factory MarriageSubmission.fromJson(Map<String, dynamic> json) {
    DateTime parsedSubmittedAt;
    try {
      parsedSubmittedAt = DateTime.parse(json['submittedAt']);
    } catch (_) {
      parsedSubmittedAt = DateTime.now();
    }

    DateTime parsedWeddingDate;
    try {
      parsedWeddingDate = DateTime.parse(json['weddingDate']);
    } catch (_) {
      parsedWeddingDate = DateTime.now().add(const Duration(days: 45));
    }

    return MarriageSubmission(
      id: json['id']?.toString() ?? '0',
      referenceNumber: json['referenceNumber'] ?? '',
      status: json['status'] ?? 'PENDING_ADMIN_APPROVAL',
      submittedAt: parsedSubmittedAt,
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '1') ?? 1,
      bride: json['bride'] != null ? BrideModel.fromJson(json['bride']) : const BrideModel(name: '', mobileNumber: ''),
      groom: json['groom'] != null ? GroomModel.fromJson(json['groom']) : const GroomModel(name: '', mobileNumber: ''),
      primaryContactNumber: json['primaryContactNumber'] ?? '',
      secondaryContactNumber: json['secondaryContactNumber'] ?? '',
      weddingDate: parsedWeddingDate,
      city: json['city'] ?? 'Hyderabad',
      coupleStory: json['coupleStory'] ?? '',
      weddingCardUrl: json['weddingCardUrl']?.toString() ??
          json['wedding_card_url']?.toString() ??
          (json['weddingCard'] is Map ? json['weddingCard']['fileUrl']?.toString() : null) ??
          '',
      weddingCardThumbnailUrl: json['weddingCardThumbnailUrl']?.toString() ??
          json['wedding_card_thumbnail_url']?.toString() ??
          (json['weddingCard'] is Map ? json['weddingCard']['thumbnailUrl']?.toString() : null),
      coverImageUrl: json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      targetBhk: json['targetBhk']?.toString() ?? json['target_bhk']?.toString() ?? json['preferredBhk']?.toString() ?? '2 BHK',
      preferredArea: json['preferredArea']?.toString() ?? json['preferred_area']?.toString() ?? 'Hyderabad',
      functions: (json['functions'] as List<dynamic>?)
              ?.map((item) => CeremonyFunctionModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      assignedFlat: json['assignedFlat'] != null ? AssignedFlatModel.fromJson(json['assignedFlat']) : null,
      slug: json['slug']?.toString(),
      shareableUrl: json['shareableUrl']?.toString() ?? json['shareable_url']?.toString(),
      qrCodeUrl: json['qrCodeUrl']?.toString() ?? json['qr_code_url']?.toString(),
      videoStreamUrl: json['videoStreamUrl']?.toString() ??
          json['video_stream_url']?.toString() ??
          json['invitationVideoUrl']?.toString() ??
          json['invitation_video_url']?.toString(),
      invitationVideoUrl: json['invitationVideoUrl']?.toString() ??
          json['invitation_video_url']?.toString() ??
          json['videoStreamUrl']?.toString() ??
          json['video_stream_url']?.toString(),
      rejectionReason: json['rejectionReason'],
      weddingId: (json['weddingId'] is num)
          ? (json['weddingId'] as num).toInt()
          : (json['wedding_id'] is num)
              ? (json['wedding_id'] as num).toInt()
              : int.tryParse(json['weddingId']?.toString() ?? json['wedding_id']?.toString() ?? '') ?? 5,
    );
  }
}

