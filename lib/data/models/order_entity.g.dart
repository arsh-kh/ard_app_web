// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderEntityImpl _$$OrderEntityImplFromJson(Map<String, dynamic> json) =>
    _$OrderEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      orderNumber: (json['orderNumber'] as num?)?.toInt(),
      customerId: json['customerId'] as String,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalCogs: (json['totalCogs'] as num?)?.toDouble() ?? 0.0,
      hasReturn: json['hasReturn'] as bool? ?? false,
      totalReturnedAmount:
          (json['totalReturnedAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: DateTime.parse(json['orderDate'] as String),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$OrderEntityImplToJson(_$OrderEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'orderNumber': instance.orderNumber,
      'customerId': instance.customerId,
      'status': instance.status,
      'totalAmount': instance.totalAmount,
      'discount': instance.discount,
      'totalCogs': instance.totalCogs,
      'hasReturn': instance.hasReturn,
      'totalReturnedAmount': instance.totalReturnedAmount,
      'orderDate': instance.orderDate.toIso8601String(),
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
