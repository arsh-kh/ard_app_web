// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseEntityImpl _$$PurchaseEntityImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseEntityImpl(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PurchaseEntityImplToJson(
  _$PurchaseEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'totalCost': instance.totalCost,
  'purchaseDate': instance.purchaseDate.toIso8601String(),
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
