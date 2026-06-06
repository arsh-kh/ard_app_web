import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audit_service.dart';
import '../models/user_entity.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(ref.read(auditServiceProvider));
});

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  UserRepository(this._auditService);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final doubleFields = ['amount', 'totalAmount', 'debtBalance', 'buyPrice', 'sellPrice', 'unitPrice', 'stockQuantity', 'quantity'];
    final intFields = ['orderNumber'];
    final dateFields = ['createdAt', 'updatedAt', 'date', 'timestamp', 'orderDate', 'paymentDate'];

    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is int) {
        if (dateFields.contains(key)) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
        } else if (doubleFields.contains(key)) {
          sanitized[key] = value.toDouble();
        } else if (!intFields.contains(key)) {
          sanitized[key] = value.toString();
        }
      } else if (value is double) {
        if (intFields.contains(key)) {
          sanitized[key] = value.toInt();
        } else if (!doubleFields.contains(key)) {
           sanitized[key] = value.toString();
        }
      } else if (value is String && dateFields.contains(key)) {
        final parsedInt = int.tryParse(value);
        if (parsedInt != null) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(parsedInt).toIso8601String();
        }
      }
    });
    return sanitized;
  }

  Stream<List<UserEntity>> watchAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .toList());
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({'status': status});
    await _auditService.logAction(
      action: 'STATUS_CHANGED',
      entityType: 'User',
      entityId: userId,
      details: 'Updated user status to $status',
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({'role': role});
    await _auditService.logAction(
      action: 'ROLE_CHANGED',
      entityType: 'User',
      entityId: userId,
      details: 'Updated user role to $role',
    );
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'User',
      entityId: userId,
      details: 'Deleted user account',
    );
  }
}
