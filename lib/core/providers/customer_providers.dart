import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_database/database.dart';
import '../../data/local_database/repositories/customer_repository_impl.dart';

final customerRepositoryProvider = Provider<CustomerRepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepositoryImpl(db);
});

final dashboardCustomersProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchAllCustomers();
});
