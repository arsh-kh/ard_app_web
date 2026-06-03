import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

class CustomerRepositoryImpl  {
  final AppDatabase _db;

  CustomerRepositoryImpl(this._db);

  
  Stream<List<CustomerEntity>> watchAllCustomers() {
    return (_db.select(_db.customers)
          ..where((t) => t.isDeleted.equals(false))
          ..where((t) => t.id.isNotValue('walk-in')))
        .watch();
  }

  
  Future<List<CustomerEntity>> getAllCustomers() {
    return (_db.select(_db.customers)
          ..where((t) => t.isDeleted.equals(false))
          ..where((t) => t.id.isNotValue('walk-in')))
        .get();
  }

  
  Stream<CustomerEntity?> watchCustomer(String id) {
    return (_db.select(_db.customers)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  
  Future<CustomerEntity?> getCustomer(String id) {
    return (_db.select(_db.customers)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  
  Future<void> addCustomer(CustomersCompanion customer) async {
    await _db.into(_db.customers).insert(customer);
  }

  
  Future<void> updateCustomer(CustomersCompanion customer) async {
    await _db.update(_db.customers).replace(customer);
  }

  
  Future<void> deleteCustomer(String id) async {
    await _db.transaction(() async {
      // Soft delete customer
      await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
        const CustomersCompanion(
          isDeleted: Value(true),
          syncStatus: Value(SyncStatus.pendingSync),
        ),
      );

      // Soft delete all their payments
      await (_db.update(_db.payments)..where((t) => t.customerId.equals(id))).write(
        const PaymentsCompanion(
          isDeleted: Value(true),
          syncStatus: Value(SyncStatus.pendingSync),
        ),
      );

      // Soft delete all their orders
      await (_db.update(_db.orders)..where((t) => t.customerId.equals(id))).write(
        const OrdersCompanion(
          isDeleted: Value(true),
          syncStatus: Value(SyncStatus.pendingSync),
        ),
      );
    });
  }

  // --- Payments ---

  Future<void> addPayment(PaymentsCompanion payment) async {
    await _db.transaction(() async {
      await _db.into(_db.payments).insert(payment);
      if (payment.customerId.present && payment.amount.present) {
        final customerId = payment.customerId.value;
        final customer = await (_db.select(_db.customers)..where((t) => t.id.equals(customerId))).getSingleOrNull();
        if (customer != null) {
          final newDebt = customer.debtBalance - payment.amount.value;
          await (_db.update(_db.customers)..where((t) => t.id.equals(customerId))).write(
            CustomersCompanion(
              debtBalance: Value(newDebt < 0 ? 0 : newDebt),
              syncStatus: const Value(SyncStatus.pendingSync),
            )
          );
        }
      }
    });
  }

  Stream<List<PaymentEntity>> watchAllPayments() {
    return (_db.select(_db.payments)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  Future<List<PaymentEntity>> getPaymentsForCustomer(String customerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  Stream<List<PaymentEntity>> watchPaymentsForCustomer(String customerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }
}
