// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      passwordHash: json['passwordHash'] as String?,
      role: json['role'] as String,
      status: json['status'] as String?,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'email': instance.email,
      'phone': instance.phone,
      'passwordHash': instance.passwordHash,
      'role': instance.role,
      'status': instance.status,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
