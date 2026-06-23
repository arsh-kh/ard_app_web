import 'package:cloud_firestore/cloud_firestore.dart';

class DataSanitizer {
  static Map<String, dynamic> sanitize(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final doubleFields = [
      'amount',
      'totalAmount',
      'debtBalance',
      'buyPrice',
      'sellPrice',
      'unitPrice',
      'unitCost',
      'totalCost',
      'stockQuantity',
      'quantity',
      'discount',
      'totalReturnedAmount',
      'returnedQuantity',
      'totalRefund',
      'returnedQty',
      'actualDeduction',
      'debtBefore',
      'debtAfter',
      'totalCogs',
      'latitude',
      'longitude',
    ];
    final intFields = ['orderNumber', 'purchaseNumber', 'paymentNumber'];
    final dateFields = [
      'createdAt',
      'updatedAt',
      'date',
      'timestamp',
      'orderDate',
      'paymentDate',
      'purchaseDate',
    ];

    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is int) {
        if (dateFields.contains(key)) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(
            value,
          ).toIso8601String();
        } else if (doubleFields.contains(key)) {
          sanitized[key] = value.toDouble();
        }
      } else if (value is double) {
        if (intFields.contains(key)) {
          sanitized[key] = value.toInt();
        }
      } else if (value is String) {
        if (dateFields.contains(key)) {
          final parsedInt = int.tryParse(value);
          if (parsedInt != null) {
            sanitized[key] = DateTime.fromMillisecondsSinceEpoch(
              parsedInt,
            ).toIso8601String();
          }
        } else if (doubleFields.contains(key)) {
          sanitized[key] = double.tryParse(value) ?? 0.0;
        } else if (intFields.contains(key)) {
          sanitized[key] = int.tryParse(value) ?? 0;
        }
      }
    });
    return sanitized;
  }
}
