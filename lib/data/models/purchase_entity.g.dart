// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseEntityImpl _$$PurchaseEntityImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      purchaseNumber: (json['purchaseNumber'] as num?)?.toInt(),
      supplierId: json['supplierId'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      hasReturn: json['hasReturn'] as bool? ?? false,
      totalReturnedAmount:
          (json['totalReturnedAmount'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$PurchaseEntityImplToJson(
  _$PurchaseEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'purchaseNumber': instance.purchaseNumber,
  'supplierId': instance.supplierId,
  'totalAmount': instance.totalAmount,
  'discount': instance.discount,
  'deliveryFee': instance.deliveryFee,
  'purchaseDate': instance.purchaseDate.toIso8601String(),
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'hasReturn': instance.hasReturn,
  'totalReturnedAmount': instance.totalReturnedAmount,
};
