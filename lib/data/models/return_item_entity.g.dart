// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReturnItemEntityImpl _$$ReturnItemEntityImplFromJson(
  Map<String, dynamic> json,
) => _$ReturnItemEntityImpl(
  id: json['id'] as String,
  businessId: json['businessId'] as String?,
  returnId: json['returnId'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  unitType: json['unitType'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  returnedQty: (json['returnedQty'] as num).toDouble(),
);

Map<String, dynamic> _$$ReturnItemEntityImplToJson(
  _$ReturnItemEntityImpl instance,
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
