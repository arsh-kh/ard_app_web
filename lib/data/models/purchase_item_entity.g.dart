// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseItemEntityImpl _$$PurchaseItemEntityImplFromJson(
  Map<String, dynamic> json,
) => _$PurchaseItemEntityImpl(
  id: json['id'] as String,
  businessId: json['businessId'] as String?,
  purchaseId: json['purchaseId'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  createdBy: json['createdBy'] as String?,
  updatedBy: json['updatedBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  returnedQuantity: (json['returnedQuantity'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$PurchaseItemEntityImplToJson(
  _$PurchaseItemEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'purchaseId': instance.purchaseId,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'returnedQuantity': instance.returnedQuantity,
};
