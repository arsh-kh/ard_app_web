import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/models/purchase_entity.dart';
import '../../data/models/purchase_item_entity.dart';
import 'auth_provider.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final user = ref.watch(authProvider).user;
  return PurchaseRepository(user?.businessId ?? '');
});

final purchasesProvider = FutureProvider<List<PurchaseEntity>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.getAllPurchases();
});

final purchasesBySupplierProvider =
    FutureProvider.family<List<PurchaseEntity>, String>((
      ref,
      supplierId,
    ) async {
      final repo = ref.watch(purchaseRepositoryProvider);
      return repo.getPurchasesBySupplier(supplierId);
    });

final purchasesBySupplierStreamProvider = StreamProvider.autoDispose
    .family<List<PurchaseEntity>, String>((ref, supplierId) {
      final repo = ref.watch(purchaseRepositoryProvider);
      return repo.watchPurchasesBySupplier(supplierId);
    });

final purchaseItemsProvider =
    FutureProvider.family<List<PurchaseItemEntity>, String>((
      ref,
      purchaseId,
    ) async {
      final repo = ref.watch(purchaseRepositoryProvider);
      return repo.getPurchaseItems(purchaseId);
    });
