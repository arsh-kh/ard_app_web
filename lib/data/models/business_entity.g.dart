// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessEntityImpl _$$BusinessEntityImplFromJson(Map<String, dynamic> json) =>
    _$BusinessEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameLower: json['nameLower'] as String,
      inviteCode: json['inviteCode'] as String,
      ownerId: json['ownerId'] as String,
      recoveryEmail: json['recoveryEmail'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$BusinessEntityImplToJson(
  _$BusinessEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nameLower': instance.nameLower,
  'inviteCode': instance.inviteCode,
  'ownerId': instance.ownerId,
  'recoveryEmail': instance.recoveryEmail,
  'createdAt': instance.createdAt?.toIso8601String(),
};
