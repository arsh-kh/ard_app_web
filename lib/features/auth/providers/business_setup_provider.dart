import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/providers/auth_provider.dart';


final businessSetupProvider =
    AsyncNotifierProvider<BusinessSetupNotifier, void>(() {
      return BusinessSetupNotifier();
    });

class BusinessSetupNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createBusiness(
    String name, {
    required String recoveryEmail,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception("userNotAuthenticated");

      final businessRepo = ref.read(businessRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final business = await businessRepo.createBusiness(
        name,
        user.id,
        recoveryEmail: recoveryEmail,
        password: password,
      );

      // Update user doc with new business ID and admin role
      await userRepo.updateUserBusinessAndRole(
        user.id,
        business.id,
        'admin',
        'active',
      );

      // Update auth provider state directly for instant UI update
      ref
          .read(authProvider.notifier)
          .updateUser(
            user.copyWith(
              businessId: business.id,
              role: 'admin',
              status: 'active',
            ),
          );
      // Fire and forget refresh to sync with server later
      ref.read(authProvider.notifier).refreshSession().ignore();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> joinBusiness(String inviteCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception("userNotAuthenticated");

      final businessRepo = ref.read(businessRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final business = await businessRepo.getBusinessByInviteCode(inviteCode);
      if (business == null) {
        throw Exception("invalidInviteCode");
      }

      // Update user doc with new business ID, employee role, pending status
      await userRepo.updateUserBusinessAndRole(
        user.id,
        business.id,
        'employee',
        'pending',
      );

      // Update auth provider state directly for instant UI update
      ref
          .read(authProvider.notifier)
          .updateUser(
            user.copyWith(
              businessId: business.id,
              role: 'employee',
              status: 'pending',
            ),
          );
      // Fire and forget refresh to sync with server later
      ref.read(authProvider.notifier).refreshSession().ignore();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> restoreBusiness(String recoveryEmail, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception("userNotAuthenticated");

      final businessRepo = ref.read(businessRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final business = await businessRepo.restoreBusiness(recoveryEmail, password);

      // Update user doc with restored business ID and admin role (restoring implies owner access)
      await userRepo.updateUserBusinessAndRole(
        user.id,
        business.id,
        'admin',
        'active',
      );

      // Update auth provider state directly for instant UI update
      ref
          .read(authProvider.notifier)
          .updateUser(
            user.copyWith(
              businessId: business.id,
              role: 'admin',
              status: 'active',
            ),
          );
      ref.read(authProvider.notifier).refreshSession().ignore();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> resetBusinessPassword(String recoveryEmail) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final businessRepo = ref.read(businessRepositoryProvider);
      await businessRepo.resetBusinessPasswordByRecoveryEmail(recoveryEmail);
    });
    if (state.hasError) throw state.error!;
  }
}
