import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_entity.freezed.dart';
part 'audit_log_entity.g.dart';

@freezed
class AuditLogEntity with _$AuditLogEntity {
  const factory AuditLogEntity({
    required String id,
    required String userId,
    required String userName,
    required String action,
    required String entityType,
    required String entityId,
    String? details,
    required DateTime timestamp,
  }) = _AuditLogEntity;

  factory AuditLogEntity.fromJson(Map<String, dynamic> json) => _$AuditLogEntityFromJson(json);
}
