import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/models/customer_entity.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  return CustomerRepository(auditService);
});

final dashboardCustomersProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchCustomers();
});

