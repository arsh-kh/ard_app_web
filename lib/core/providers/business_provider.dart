import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import '../../data/models/business_entity.dart';

/// Provides the `businessId` of the currently authenticated user.
/// Returns null if the user is not logged in or hasn't selected/created a business.
final currentBusinessIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.businessId;
});

final currentBusinessEntityProvider =
    StreamProvider.autoDispose<BusinessEntity?>((ref) {
      final businessId = ref.watch(currentBusinessIdProvider);

      if (businessId == null || businessId.isEmpty) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) return null;
            return BusinessEntity.fromJson({
              'id': snapshot.id,
              ...snapshot.data()!,
            });
          });
    });
