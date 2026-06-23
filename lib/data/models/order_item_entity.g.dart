// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderItemEntityImpl _$$OrderItemEntityImplFromJson(
  Map<String, dynamic> json,
) => _$OrderItemEntityImpl(
  id: json['id'] as String,
  businessId: json['businessId'] as String?,
  orderId: json['orderId'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  returnedQuantity: (json['returnedQuantity'] as num?)?.toDouble() ?? 0.0,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  buyPrice: (json['buyPrice'] as num?)?.toDouble() ?? 0.0,
  createdBy: json['createdBy'] as String?,
  updatedBy: json['updatedBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$OrderItemEntityImplToJson(
  _$OrderItemEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'orderId': instance.orderId,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'returnedQuantity': instance.returnedQuantity,
  'unitPrice': instance.unitPrice,
  'buyPrice': instance.buyPrice,
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
