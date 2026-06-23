// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuditLogEntityImpl _$$AuditLogEntityImplFromJson(Map<String, dynamic> json) =>
    _$AuditLogEntityImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      details: json['details'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$AuditLogEntityImplToJson(
  _$AuditLogEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'userId': instance.userId,
  'userName': instance.userName,
  'action': instance.action,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'details': instance.details,
  'metadata': instance.metadata,
  'timestamp': instance.timestamp.toIso8601String(),
};
