import 'package:cloud_firestore/cloud_firestore.dart';

class SequenceService {
  SequenceService._();

  /// Gets the next sequential number for a given entity type (e.g., 'orders', 'purchases').
  /// This runs inside an atomic transaction to ensure no duplicates.
  static Future<int> getNextSequence(String sequenceName, {required String businessId}) async {
    final firestore = FirebaseFirestore.instance;
    final docId = '${businessId}_$sequenceName';
    final counterRef = firestore.collection('counters').doc(docId);

    return await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        // Initialize at 1
        transaction.set(counterRef, {'count': 1, 'businessId': businessId});
        return 1;
      }

      final int currentCount = (snapshot.data()?['count'] as int?) ?? 0;
      final int nextCount = currentCount + 1;

      transaction.update(counterRef, {'count': nextCount});
      return nextCount;
    });
  }
}
