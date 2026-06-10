class ReturnItemEntity {
  final String id;
  final String returnId;
  final String productId;
  /// Snapshot of the product name at return time — safe even if product is later deleted.
  final String productName;
  final String unitType;
  final double unitPrice;
  final double returnedQty;

  const ReturnItemEntity({
    required this.id,
    required this.returnId,
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.unitPrice,
    required this.returnedQty,
  });

  double get lineRefund => unitPrice * returnedQty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'returnId': returnId,
        'productId': productId,
        'productName': productName,
        'unitType': unitType,
        'unitPrice': unitPrice,
        'returnedQty': returnedQty,
      };

  factory ReturnItemEntity.fromJson(Map<String, dynamic> json) {
    return ReturnItemEntity(
      id: json['id'] as String? ?? '',
      returnId: json['returnId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unitType: json['unitType'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      returnedQty: (json['returnedQty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
