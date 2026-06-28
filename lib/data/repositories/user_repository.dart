import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/audit_service.dart';
import '../models/user_entity.dart';
import '../../core/providers/business_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return UserRepository(ref.read(auditServiceProvider), businessId);
});

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  UserRepository(this._auditService, this.businessId);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return DataSanitizer.sanitize(data);
  }

  Stream<List<UserEntity>> watchAllUsers() {
    return _firestore
        .collection('users')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return;
    if (doc.data()?['businessId'] != businessId) return;

    await _firestore.collection('users').doc(userId).update({'status': status});
    await _auditService.logAction(
      action: 'STATUS_CHANGED',
      entityType: 'User',
      entityId: userId,
      details: 'Updated user status to $status',
      metadata: {'newStatus': status, 'userId': userId},
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return;
    if (doc.data()?['businessId'] != businessId) return;

    await _firestore.collection('users').doc(userId).update({'role': role});
    await _auditService.logAction(
      action: 'ROLE_CHANGED',
      entityType: 'User',
      entityId: userId,
      details: 'Updated user role to $role',
      metadata: {'newRole': role, 'userId': userId},
    );
  }

  Future<void> deleteUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return;
    if (doc.data()?['businessId'] != businessId) return;

    await _firestore.collection('users').doc(userId).delete();
    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'User',
      entityId: userId,
      details: 'Deleted user account',
      metadata: {'userId': userId},
    );
  }

  Future<void> updateUserBusinessAndRole(
    String userId,
    String newBusinessId,
    String role,
    String status,
  ) async {
    // This allows a new user to join or create a business
    await _firestore.collection('users').doc(userId).update({
      'businessId': newBusinessId,
      'role': role,
      'status': status,
    });
  }
}
