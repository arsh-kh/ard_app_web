import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataWipeServiceProvider = Provider<DataWipeService>((ref) {
  return DataWipeService();
});

class DataWipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> wipeAllData({
    required bool wipeUsers,
    required String currentAdminId,
    required String businessId,
  }) async {
    final collections = [
      'customers',
      'products',
      'orders',
      'order_items',
      'payments',
      'returns',
      'return_items',
      'purchases',
      'purchaseItems',
      'purchase_returns',
      'purchase_return_items',
      'audit_logs',
      'counters',
    ];

    for (final path in collections) {
      await _wipeCollection(path, businessId);
    }

    if (wipeUsers) {
      await _wipeUsers(currentAdminId, businessId);
    }
  }

  Future<void> _wipeCollection(String path, String businessId) async {
    bool hasMore = true;
    while (hasMore) {
      final snapshot = await _firestore
          .collection(path)
          .where('businessId', isEqualTo: businessId)
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _wipeUsers(String currentAdminId, String businessId) async {
    bool hasMore = true;
    while (hasMore) {
      final snapshot = await _firestore
          .collection('users')
          .where('businessId', isEqualTo: businessId)
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }
      final batch = _firestore.batch();
      bool anyDeleted = false;
      for (final doc in snapshot.docs) {
        // Never delete the current admin so they don't get locked out
        if (doc.id != currentAdminId) {
          batch.delete(doc.reference);
          anyDeleted = true;
        }
      }
      if (anyDeleted) {
        await batch.commit();
      } else {
        // If the only doc left is the current admin, we are done
        hasMore = false;
      }
    }
  }
}
