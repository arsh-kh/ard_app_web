import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/business_entity.dart';
import '../../core/services/audit_service.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(
    FirebaseFirestore.instance,
    ref.read(auditServiceProvider),
  );
});

class BusinessRepository {
  final FirebaseFirestore _firestore;
  final AuditService _auditService;

  BusinessRepository(this._firestore, this._auditService);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<BusinessEntity> createBusiness(
    String name,
    String ownerId, {
    required String recoveryEmail,
  }) async {
    final nameLower = name.trim().toLowerCase();

    // Check if business name already exists (case-insensitive)
    final existingNameSnapshot = await _firestore
        .collection('businesses')
        .where('nameLower', isEqualTo: nameLower)
        .limit(1)
        .get();

    if (existingNameSnapshot.docs.isNotEmpty) {
      throw Exception('businessNameTaken');
    }

    final id = const Uuid().v4();

    // Generate an invite code and ensure it is universally unique
    String inviteCode;
    bool isUnique = false;
    do {
      inviteCode = _generateInviteCode();
      final existingCodeSnapshot = await _firestore
          .collection('businesses')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();
      if (existingCodeSnapshot.docs.isEmpty) {
        isUnique = true;
      }
    } while (!isUnique);

    final business = BusinessEntity(
      id: id,
      name: name.trim(),
      nameLower: nameLower,
      inviteCode: inviteCode,
      ownerId: ownerId,
      recoveryEmail: recoveryEmail,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('businesses').doc(id).set(business.toJson());

    await _auditService.logAction(
      action: 'BUSINESS_CREATED',
      entityType: 'Business',
      entityId: id,
      details: 'Created business $name with code $inviteCode',
    );

    return business;
  }

  Future<BusinessEntity?> getBusinessByInviteCode(String inviteCode) async {
    final snapshot = await _firestore
        .collection('businesses')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return BusinessEntity.fromJson({'id': doc.id, ...doc.data()});
  }
}
