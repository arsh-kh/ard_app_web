import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/purchase_return_repository.dart';
import '../../core/providers/business_provider.dart';

final purchaseReturnRepositoryProvider = Provider<PurchaseReturnRepository>((
  ref,
) {
  final auditService = ref.watch(auditServiceProvider);
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return PurchaseReturnRepository(auditService, businessId);
});
