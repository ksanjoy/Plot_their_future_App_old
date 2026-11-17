class TaxReceiptModel {
  final int id;
  final int contributionId;
  final String receiptNo;
  final String exemptClause;
  final String digitalSignatureHash;
  final String pdfUrl;
  final DateTime generatedAt;

  const TaxReceiptModel({
    required this.id,
    required this.contributionId,
    required this.receiptNo,
    required this.exemptClause,
    required this.digitalSignatureHash,
    required this.pdfUrl,
    required this.generatedAt,
  });

  factory TaxReceiptModel.fromJson(Map<String, dynamic> json) {
    return TaxReceiptModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      contributionId: json['contributionId'] is int
          ? json['contributionId']
          : int.tryParse(json['contributionId'].toString()) ?? 1,
      receiptNo: json['receiptNo'] as String? ?? 'PTF-SEC-1928471-001001',
      exemptClause: json['exemptClause'] as String? ?? 'Section 56(2)(x) of Indian Income Tax Act',
      digitalSignatureHash: json['digitalSignatureHash'] as String? ?? '9a8fbc83d91e84a92c0182b810948ac019',
      pdfUrl: json['pdfUrl'] as String? ?? 'https://plottheirfuture.in/receipts/PTF-SEC-892104.pdf',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contributionId': contributionId,
    'receiptNo': receiptNo,
    'exemptClause': exemptClause,
    'digitalSignatureHash': digitalSignatureHash,
    'pdfUrl': pdfUrl,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

