import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/payment_entity.dart';

import 'business_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return PaymentRepository(auditService, businessId);
});

final allPaymentsStreamProvider =
    StreamProvider.autoDispose<List<PaymentEntity>>((ref) {
      return ref.watch(paymentRepositoryProvider).watchAllPayments();
    });
