class PurchaseReturnEntity {
  final String id;
  final String? businessId;
  final String purchaseId;
  final String? supplierId;
  final DateTime returnDate;
  final double totalRefund;
  final String? notes;
  final String? createdBy;

  const PurchaseReturnEntity({
    required this.id,
    this.businessId,
    required this.purchaseId,
    this.supplierId,
    required this.returnDate,
    required this.totalRefund,
    this.notes,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (businessId != null) 'businessId': businessId,
    'purchaseId': purchaseId,
    'supplierId': supplierId,
    'returnDate': returnDate.toIso8601String(),
    'totalRefund': totalRefund,
    if (notes != null) 'notes': notes,
    if (createdBy != null) 'createdBy': createdBy,
  };

  factory PurchaseReturnEntity.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return PurchaseReturnEntity(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String?,
      purchaseId: json['purchaseId'] as String? ?? '',
      supplierId: json['supplierId'] as String?,
      returnDate: parseDate(json['returnDate']),
      totalRefund: (json['totalRefund'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }
}
