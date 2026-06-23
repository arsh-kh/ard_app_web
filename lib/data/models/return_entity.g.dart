// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReturnEntityImpl _$$ReturnEntityImplFromJson(Map<String, dynamic> json) =>
    _$ReturnEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as String,
      returnDate: DateTime.parse(json['returnDate'] as String),
      totalRefund: (json['totalRefund'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$$ReturnEntityImplToJson(_$ReturnEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'orderId': instance.orderId,
      'customerId': instance.customerId,
      'returnDate': instance.returnDate.toIso8601String(),
      'totalRefund': instance.totalRefund,
      'notes': instance.notes,
      'createdBy': instance.createdBy,
    };
