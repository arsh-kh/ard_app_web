import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_database/database.dart';
import '../../data/local_database/repositories/inventory_repository_impl.dart';

final inventoryRepositoryProvider = Provider<InventoryRepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryRepositoryImpl(db);
});
