class FloorPlanZone {
  final int id;
  final int weddingId;
  final String roomName;
  final int totalSft;
  final int fundedSft;
  final String svgElementId;

  const FloorPlanZone({
    required this.id,
    required this.weddingId,
    required this.roomName,
    required this.totalSft,
    required this.fundedSft,
    required this.svgElementId,
  });

  factory FloorPlanZone.fromJson(Map<String, dynamic> json) {
    return FloorPlanZone(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      weddingId: json['weddingId'] is int ? json['weddingId'] : int.tryParse(json['weddingId'].toString()) ?? 1,
      roomName: json['roomName'] as String? ?? 'Living Room',
      totalSft: json['totalSft'] is int ? json['totalSft'] : int.tryParse(json['totalSft'].toString()) ?? 400,
      fundedSft: json['fundedSft'] is int ? json['fundedSft'] : int.tryParse(json['fundedSft'].toString()) ?? 0,
      svgElementId: json['svgElementId'] as String? ?? 'svg_living_room',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weddingId': weddingId,
    'roomName': roomName,
    'totalSft': totalSft,
    'fundedSft': fundedSft,
    'svgElementId': svgElementId,
  };
}

