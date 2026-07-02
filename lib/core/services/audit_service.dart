import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/audit_log_entity.dart';
import '../../core/providers/business_provider.dart';
import '../providers/auth_provider.dart';

final auditServiceProvider = Provider<AuditService>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return AuditService(
    FirebaseFirestore.instance,
    ref.read(authProvider).user?.id,
    ref.read(authProvider).user?.name,
    businessId,
  );
});

class AuditService {
  final FirebaseFirestore _firestore;
  final String? _currentUserId;
  final String? _currentUserName;
  final String? _businessId;

  AuditService(
    this._firestore,
    this._currentUserId,
    this._currentUserName,
    this._businessId,
  );

  Future<void> logAction({
    required String action,
    required String entityType,
    required String entityId,
    String? details,
    Map<String, dynamic>? metadata,
    String? overrideBusinessId,
  }) async {
    // If we have no logged in user, maybe system action or error?
    final userId = _currentUserId ?? 'SYSTEM';
    final userName = _currentUserName ?? 'System Process';

    final businessIdToUse = overrideBusinessId ?? _businessId;

    final id = const Uuid().v4();
    final log = AuditLogEntity(
      id: id,
      businessId: businessIdToUse,
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      metadata: metadata,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.collection('audit_logs').doc(id).set(log.toJson());
    } catch (e) {
      // Intentionally not failing the main operation if audit fails
      debugPrint('Error logging audit action: $e');
    }
  }
}
