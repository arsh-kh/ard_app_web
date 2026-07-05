// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentEntityImpl _$$PaymentEntityImplFromJson(Map<String, dynamic> json) =>
    _$PaymentEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      orderId: json['orderId'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PaymentEntityImplToJson(_$PaymentEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'customerId': instance.customerId,
      'amount': instance.amount,
      'paymentDate': instance.paymentDate.toIso8601String(),
      'orderId': instance.orderId,
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
