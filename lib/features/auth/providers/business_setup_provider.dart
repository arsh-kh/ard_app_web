import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/providers/auth_provider.dart';

final businessSetupProvider = AsyncNotifierProvider<BusinessSetupNotifier, void>(() {
  return BusinessSetupNotifier();
});

class BusinessSetupNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createBusiness(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception("User not authenticated.");

      final businessRepo = ref.read(businessRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final business = await businessRepo.createBusiness(name, user.id);
      
      // Update user doc with new business ID and admin role
      await userRepo.updateUserBusinessAndRole(user.id, business.id, 'admin', 'active');
      
      // Refresh auth provider to pull latest user claims
      await ref.read(authProvider.notifier).refreshSession();
    });
  }

  Future<void> joinBusiness(String inviteCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception("User not authenticated.");

      final businessRepo = ref.read(businessRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final business = await businessRepo.getBusinessByInviteCode(inviteCode);
      if (business == null) throw Exception("Invalid Invite Code. Business not found.");

      // Update user doc with new business ID, employee role, pending status
      await userRepo.updateUserBusinessAndRole(user.id, business.id, 'employee', 'pending');
      
      // Refresh auth provider to pull latest user claims
      await ref.read(authProvider.notifier).refreshSession();
    });
  }
}
