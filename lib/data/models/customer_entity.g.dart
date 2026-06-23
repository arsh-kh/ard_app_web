// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerEntityImpl _$$CustomerEntityImplFromJson(Map<String, dynamic> json) =>
    _$CustomerEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      userId: json['userId'] as String?,
      businessName: json['businessName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      debtBalance: (json['debtBalance'] as num).toDouble(),
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

Map<String, dynamic> _$$CustomerEntityImplToJson(
  _$CustomerEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'userId': instance.userId,
  'businessName': instance.businessName,
  'phone': instance.phone,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'debtBalance': instance.debtBalance,
  'imageUrl': instance.imageUrl,
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
