import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  return InventoryRepository(auditService);
});

