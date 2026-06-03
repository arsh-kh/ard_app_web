import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/local_database/database.dart';
import '../../data/local_database/repositories/order_repository_impl.dart';
import '../../domain/enums.dart';

final orderRepositoryProvider = Provider<OrderRepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return OrderRepositoryImpl(db);
});

final pendingOrdersCountProvider = StreamProvider<int>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchAllOrders().map(
        (orders) => orders.where((o) => o.status == OrderStatus.pending.value).length,
      );
});

final dashboardProfitProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.orderItems).join([
    innerJoin(db.orders, db.orders.id.equalsExp(db.orderItems.orderId)),
    innerJoin(db.products, db.products.id.equalsExp(db.orderItems.productId)),
  ])
    ..where(db.orders.status.equals(OrderStatus.delivered.value))
    ..where(db.orders.isDeleted.equals(false))
    ..where(db.orderItems.isDeleted.equals(false));

  return query.watch().map((rows) {
    double totalProfit = 0.0;
    for (final row in rows) {
      final item = row.readTable(db.orderItems);
      final product = row.readTable(db.products);
      final profitPerItem = item.quantity * (item.unitPrice - product.buyPrice);
      totalProfit += profitPerItem;
    }
    return totalProfit;
  });
});
