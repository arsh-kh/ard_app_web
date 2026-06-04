import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

class OrderRepositoryImpl  {
  final AppDatabase _db;

  OrderRepositoryImpl(this._db);

  
  Stream<List<OrderEntity>> watchAllOrders() {
    return (_db.select(_db.orders)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .watch();
  }

  
  Stream<List<OrderEntity>> watchOrdersByCustomer(String customerId) {
    return (_db.select(_db.orders)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .watch();
  }

  
  Future<List<OrderEntity>> getOrdersByCustomer(String customerId) {
    return (_db.select(_db.orders)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .get();
  }

  
  Stream<OrderEntity?> watchOrder(String id) {
    return (_db.select(_db.orders)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  
  Future<OrderEntity?> getOrder(String id) {
    return (_db.select(_db.orders)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  
  Stream<List<OrderItemEntity>> watchOrderItems(String orderId) {
    return (_db.select(_db.orderItems)
          ..where((t) => t.orderId.equals(orderId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  
  Future<List<OrderItemEntity>> getOrderItems(String orderId) {
    return (_db.select(_db.orderItems)
          ..where((t) => t.orderId.equals(orderId))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  
  Future<void> createOrder(OrdersCompanion order, List<OrderItemsCompanion> items) async {
    await _db.transaction(() async {
      final maxOrderRow = await (_db.select(_db.orders)
            ..orderBy([(t) => OrderingTerm.desc(t.orderNumber)])
            ..limit(1))
          .getSingleOrNull();
      
      final nextNum = (maxOrderRow?.orderNumber ?? 0) + 1;
      final finalOrder = order.copyWith(orderNumber: Value(nextNum));

      await _db.into(_db.orders).insert(finalOrder);
      for (final item in items) {
        await _db.into(_db.orderItems).insert(item);
        
        // Transactionally deduct stock if order is delivered immediately
        if (order.status.present && order.status.value == 'delivered') {
          final product = await (_db.select(_db.products)
                ..where((t) => t.id.equals(item.productId.value)))
              .getSingleOrNull();

          if (product != null) {
            final newQty = product.stockQuantity - item.quantity.value;
            await (_db.update(_db.products)
                  ..where((t) => t.id.equals(item.productId.value)))
                .write(ProductsCompanion(
                  stockQuantity: Value(newQty >= 0 ? newQty : 0.0),
                  syncStatus: const Value(SyncStatus.pendingSync),
                ));
          }
        }
      }
      
      // Update customer debt if delivered
      if (order.status.present && order.status.value == 'delivered' && order.customerId.present) {
          final customer = await (_db.select(_db.customers)..where((t) => t.id.equals(order.customerId.value))).getSingleOrNull();
          if (customer != null && order.totalAmount.present) {
              final newDebt = customer.debtBalance + order.totalAmount.value;
              await (_db.update(_db.customers)..where((t) => t.id.equals(customer.id))).write(
                  CustomersCompanion(
                      debtBalance: Value(newDebt),
                      syncStatus: const Value(SyncStatus.pendingSync),
                  ),
              );
          }
      }
    });
  }

  Future<void> markOrderDelivered(String orderId) async {
    await _db.transaction(() async {
      // 1. Get order details
      final order = await (_db.select(_db.orders)
            ..where((t) => t.id.equals(orderId)))
          .getSingleOrNull();
          
      if (order == null) return;

      // 2. Get all items in this order
      final items = await (_db.select(_db.orderItems)
            ..where((t) => t.orderId.equals(orderId))
            ..where((t) => t.isDeleted.equals(false)))
          .get();

      // 3. Reduce stock of each product
      for (final item in items) {
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .getSingleOrNull();

        if (product != null) {
          final newQty = product.stockQuantity - item.quantity;
          await (_db.update(_db.products)
                ..where((t) => t.id.equals(item.productId)))
              .write(ProductsCompanion(
                stockQuantity: Value(newQty >= 0 ? newQty : 0.0),
                syncStatus: const Value(SyncStatus.pendingSync),
              ));
        }
      }
      
      // 4. Update customer debt
      final customer = await (_db.select(_db.customers)..where((t) => t.id.equals(order.customerId))).getSingleOrNull();
      if (customer != null) {
          final newDebt = customer.debtBalance + order.totalAmount;
          await (_db.update(_db.customers)..where((t) => t.id.equals(customer.id))).write(
              CustomersCompanion(
                  debtBalance: Value(newDebt),
                  syncStatus: const Value(SyncStatus.pendingSync),
              ),
          );
      }

      // 5. Update order status to delivered
      await (_db.update(_db.orders)
            ..where((t) => t.id.equals(orderId)))
          .write(const OrdersCompanion(
            status: Value('delivered'),
            syncStatus: Value(SyncStatus.pendingSync),
          ));
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await (_db.update(_db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: Value(newStatus),
        syncStatus: const Value(SyncStatus.pendingSync),
      ),
    );
  }

  Future<void> deleteOrder(String orderId) async {
    await _db.transaction(() async {
      // 1. Get the order
      final order = await (_db.select(_db.orders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
      if (order == null) return;

      // 2. Soft delete the order
      await (_db.update(_db.orders)..where((t) => t.id.equals(orderId))).write(
        const OrdersCompanion(
          isDeleted: Value(true),
          syncStatus: Value(SyncStatus.pendingSync),
        ),
      );

      // 3. If delivered, restore stock and reduce debt
      if (order.status == 'delivered') {
        // Restore stock
        final items = await (_db.select(_db.orderItems)..where((t) => t.orderId.equals(orderId))).get();
        for (final item in items) {
          final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
          if (product != null) {
            await (_db.update(_db.products)..where((t) => t.id.equals(product.id))).write(
              ProductsCompanion(
                stockQuantity: Value(product.stockQuantity + item.quantity),
                syncStatus: const Value(SyncStatus.pendingSync),
              ),
            );
          }
        }

        // Reduce debt
        final customer = await (_db.select(_db.customers)..where((t) => t.id.equals(order.customerId))).getSingleOrNull();
        if (customer != null) {
          final newDebt = customer.debtBalance - order.totalAmount;
          await (_db.update(_db.customers)..where((t) => t.id.equals(customer.id))).write(
            CustomersCompanion(
              debtBalance: Value(newDebt < 0 ? 0 : newDebt),
              syncStatus: const Value(SyncStatus.pendingSync),
            ),
          );
        }
      }
    });
  }
}
