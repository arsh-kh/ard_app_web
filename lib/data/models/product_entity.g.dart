// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductEntityImpl _$$ProductEntityImplFromJson(Map<String, dynamic> json) =>
    _$ProductEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      stockQuantity: (json['stockQuantity'] as num).toDouble(),
      unitType: json['unitType'] as String,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      imageUrl: json['imageUrl'] as String?,
      supplierName: json['supplierName'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProductEntityImplToJson(_$ProductEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'stockQuantity': instance.stockQuantity,
      'unitType': instance.unitType,
      'buyPrice': instance.buyPrice,
      'sellPrice': instance.sellPrice,
      'lowStockThreshold': instance.lowStockThreshold,
      'barcode': instance.barcode,
      'imageUrl': instance.imageUrl,
      'supplierName': instance.supplierName,
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
