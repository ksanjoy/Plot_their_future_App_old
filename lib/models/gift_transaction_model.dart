class GiftTransactionModel {
  final int id;
  final String txnId;
  final String guestName;
  final String guestMobile;
  final String? guestEmail;
  final int weddingId;
  final int? flatId;
  final int? sectionId;
  final String sectionName;
  final int giftedSft;
  final int brickEquivalent;
  final double amountPaid;
  final String paymentStatus;
  final String paymentDate;
  final String? blessingMessage;

  const GiftTransactionModel({
    required this.id,
    required this.txnId,
    required this.guestName,
    required this.guestMobile,
    this.guestEmail,
    required this.weddingId,
    this.flatId,
    this.sectionId,
    required this.sectionName,
    required this.giftedSft,
    required this.brickEquivalent,
    required this.amountPaid,
    required this.paymentStatus,
    required this.paymentDate,
    this.blessingMessage,
  });

  factory GiftTransactionModel.fromJson(Map<String, dynamic> json) {
    return GiftTransactionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      txnId: json['txnId']?.toString() ?? 'TXN-GEN',
      guestName: json['guestName']?.toString() ?? 'Wedding Guest',
      guestMobile: json['guestMobile']?.toString() ?? '',
      guestEmail: json['guestEmail']?.toString(),
      weddingId: json['weddingId'] is int ? json['weddingId'] as int : int.tryParse(json['weddingId']?.toString() ?? '0') ?? 0,
      flatId: json['flatId'] is int ? json['flatId'] as int : int.tryParse(json['flatId']?.toString() ?? ''),
      sectionId: json['sectionId'] is int ? json['sectionId'] as int : int.tryParse(json['sectionId']?.toString() ?? ''),
      sectionName: json['sectionName']?.toString() ?? 'General Sq. Ft.',
      giftedSft: json['giftedSft'] is int ? json['giftedSft'] as int : int.tryParse(json['giftedSft']?.toString() ?? '1') ?? 1,
      brickEquivalent: json['brickEquivalent'] is int ? json['brickEquivalent'] as int : int.tryParse(json['brickEquivalent']?.toString() ?? '10') ?? 10,
      amountPaid: (json['amountPaid'] is num) ? (json['amountPaid'] as num).toDouble() : double.tryParse(json['amountPaid']?.toString() ?? '4500') ?? 4500.0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'SUCCESS',
      paymentDate: json['paymentDate']?.toString() ?? '',
      blessingMessage: json['blessingMessage']?.toString(),
    );
  }
}
