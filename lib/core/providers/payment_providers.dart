import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_database/database.dart';
import '../../data/local_database/repositories/payment_repository_impl.dart';

final paymentRepositoryProvider = Provider<PaymentRepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentRepositoryImpl(db);
});
