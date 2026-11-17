class FloorPlanTile {
  final int id;
  final int weddingId;
  final int zoneId;
  final int sftSize;
  final String status; // 'OPEN', 'HOLD', 'FUNDED'
  final DateTime? lockedUntil;
  final String? lockedByPhone;
  final int? donorId;
  final int version;

  const FloorPlanTile({
    required this.id,
    required this.weddingId,
    required this.zoneId,
    required this.sftSize,
    required this.status,
    this.lockedUntil,
    this.lockedByPhone,
    this.donorId,
    this.version = 0,
  });

  bool get isOpen => status == 'OPEN';
  bool get isHold => status == 'HOLD';
  bool get isFunded => status == 'FUNDED';

  bool get isLockedActive {
    if (!isHold || lockedUntil == null) return false;
    return lockedUntil!.isAfter(DateTime.now());
  }

  factory FloorPlanTile.fromJson(Map<String, dynamic> json) {
    return FloorPlanTile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      weddingId: json['weddingId'] is int ? json['weddingId'] : int.tryParse(json['weddingId'].toString()) ?? 1,
      zoneId: json['zoneId'] is int ? json['zoneId'] : int.tryParse(json['zoneId'].toString()) ?? 1,
      sftSize: json['sftSize'] is int ? json['sftSize'] : int.tryParse(json['sftSize'].toString()) ?? 5,
      status: json['status'] as String? ?? 'OPEN',
      lockedUntil: json['lockedUntil'] != null ? DateTime.tryParse(json['lockedUntil'].toString()) : null,
      lockedByPhone: json['lockedByPhone'] as String?,
      donorId: json['donorId'] as int?,
      version: json['version'] is int ? json['version'] : int.tryParse(json['version'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weddingId': weddingId,
    'zoneId': zoneId,
    'sftSize': sftSize,
    'status': status,
    if (lockedUntil != null) 'lockedUntil': lockedUntil!.toIso8601String(),
    if (lockedByPhone != null) 'lockedByPhone': lockedByPhone,
    if (donorId != null) 'donorId': donorId,
    'version': version,
  };
}

