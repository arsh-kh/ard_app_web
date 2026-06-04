import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables.dart';

class PaymentRepositoryImpl {
  final AppDatabase _db;

  PaymentRepositoryImpl(this._db);

  /// Returns a live stream of all payments for a given customer, newest first.
  Stream<List<PaymentEntity>> watchPaymentsByCustomer(String customerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  /// Records a payment and reduces the customer's debt balance atomically.
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    DateTime? paymentDate,
  }) async {
    if (amount <= 0) return;
    await _db.transaction(() async {
      final id = const Uuid().v4();

      // 1. Insert the payment record
      await _db.into(_db.payments).insert(PaymentsCompanion.insert(
        id: id,
        customerId: customerId,
        amount: amount,
        paymentDate: Value(paymentDate ?? DateTime.now()),
      ));

      // 2. Reduce customer debt balance
      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();

      if (customer != null) {
        final newDebt = (customer.debtBalance - amount).clamp(0.0, double.infinity);
        await (_db.update(_db.customers)..where((t) => t.id.equals(customerId))).write(
          CustomersCompanion(
            debtBalance: Value(newDebt),
            syncStatus: const Value(SyncStatus.pendingSync),
          ),
        );
      }
    });
  }

  /// Soft-deletes a payment and restores the customer's debt balance.
  Future<void> deletePayment(PaymentEntity payment) async {
    await _db.transaction(() async {
      // 1. Soft delete
      await (_db.update(_db.payments)..where((t) => t.id.equals(payment.id))).write(
        const PaymentsCompanion(
          isDeleted: Value(true),
          syncStatus: Value(SyncStatus.pendingSync),
        ),
      );

      // 2. Restore debt
      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(payment.customerId)))
          .getSingleOrNull();

      if (customer != null) {
        await (_db.update(_db.customers)..where((t) => t.id.equals(payment.customerId))).write(
          CustomersCompanion(
            debtBalance: Value(customer.debtBalance + payment.amount),
            syncStatus: const Value(SyncStatus.pendingSync),
          ),
        );
      }
    });
  }

  /// Returns all payments for a customer as a one-time fetch.
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }
}
