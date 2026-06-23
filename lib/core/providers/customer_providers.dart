import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/models/customer_entity.dart';

import 'business_provider.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return CustomerRepository(auditService, businessId);
});

final dashboardCustomersProvider = StreamProvider.autoDispose<List<CustomerEntity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchCustomers();
});

final allCustomersStreamProvider = StreamProvider.autoDispose<List<CustomerEntity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchAllCustomers();
});
