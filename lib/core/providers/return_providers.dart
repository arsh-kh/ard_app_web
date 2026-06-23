import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../../data/repositories/return_repository.dart';

import 'business_provider.dart';

final returnRepositoryProvider = Provider<ReturnRepository>((ref) {
  final auditService = ref.watch(auditServiceProvider);
  final businessId = ref.watch(currentBusinessIdProvider) ?? '';
  return ReturnRepository(auditService, businessId);
});
