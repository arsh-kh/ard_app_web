class ReturnEntity {
  final String id;
  final String orderId;
  final String customerId;
  final DateTime returnDate;
  final double totalRefund;
  final String? notes;
  final String? createdBy;

  const ReturnEntity({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.returnDate,
    required this.totalRefund,
    this.notes,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'returnDate': returnDate.toIso8601String(),
        'totalRefund': totalRefund,
        if (notes != null) 'notes': notes,
        if (createdBy != null) 'createdBy': createdBy,
      };

  factory ReturnEntity.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return ReturnEntity(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      returnDate: parseDate(json['returnDate']),
      totalRefund: (json['totalRefund'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }
}
