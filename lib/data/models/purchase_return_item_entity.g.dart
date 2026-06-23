// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_return_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseReturnItemEntityImpl _$$PurchaseReturnItemEntityImplFromJson(
  Map<String, dynamic> json,
) => _$PurchaseReturnItemEntityImpl(
  id: json['id'] as String,
  businessId: json['businessId'] as String?,
  returnId: json['returnId'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  unitType: json['unitType'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  returnedQty: (json['returnedQty'] as num).toDouble(),
);

Map<String, dynamic> _$$PurchaseReturnItemEntityImplToJson(
  _$PurchaseReturnItemEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'returnId': instance.returnId,
  'productId': instance.productId,
  'productName': instance.productName,
  'unitType': instance.unitType,
  'unitPrice': instance.unitPrice,
  'returnedQty': instance.returnedQty,
};
