import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/models/product_entity.dart';

import 'business_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return InventoryRepository(auditService, businessId);
});

final productsStreamProvider = StreamProvider.autoDispose<List<ProductEntity>>((
  ref,
) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.watchAllProducts();
});
