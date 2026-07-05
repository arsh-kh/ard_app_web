import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_entity.dart';
import 'order_providers.dart';
import 'inventory_providers.dart';
import 'customer_providers.dart';

// 1. Margin Analytics Data Structures
class ProductMarginData {
  final ProductEntity product;
  final double marginAmount;
  final double marginPercentage;

  ProductMarginData({
    required this.product,
    required this.marginAmount,
    required this.marginPercentage,
  });
}

final productMarginsProvider = FutureProvider<List<ProductMarginData>>((
  ref,
) async {
  final inventoryRepo = ref.read(inventoryRepositoryProvider);
  final products = await inventoryRepo.getAllProducts();

  final list = products.map((p) {
    final margin = p.sellPrice - p.buyPrice;
    final percentage = p.sellPrice > 0 ? (margin / p.sellPrice) * 100 : 0.0;
    return ProductMarginData(
      product: p,
      marginAmount: margin,
      marginPercentage: percentage,
    );
  }).toList();

  // Sort by highest margin percentage
  list.sort((a, b) => b.marginPercentage.compareTo(a.marginPercentage));
  return list;
});

// 2. Top Customers Data Structures
class CustomerSalesData {
  final CustomerEntity customer;
  final double totalSales;
  final int orderCount;

  CustomerSalesData({
    required this.customer,
    required this.totalSales,
    required this.orderCount,
  });
}

final topCustomersProvider = FutureProvider<List<CustomerSalesData>>((
  ref,
) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);

  // Fetch all delivered orders
  final allOrders = await orderRepo.getAllOrders();
  final orders = allOrders.toList();

  final allCustomers = await customerRepo.getAllCustomers();
  final customers = allCustomers.toList();

  final Map<String, List<OrderEntity>> ordersByCustomer = {};
  for (final order in orders) {
    ordersByCustomer.putIfAbsent(order.customerId, () => []).add(order);
  }

  final list = customers.map((c) {
    final cOrders = ordersByCustomer[c.id] ?? [];
    final sales = cOrders.fold(
      0.0,
      (sum, o) => sum + (o.totalAmount - o.totalReturnedAmount),
    );
    return CustomerSalesData(
      customer: c,
      totalSales: sales,
      orderCount: cOrders.length,
    );
  }).toList();

  // Sort by highest sales
  list.sort((a, b) => b.totalSales.compareTo(a.totalSales));
  return list;
});

// 3. Debt Aging Data Structures
class DebtAgingData {
  final double recentDebt; // 0-15 days
  final double dueDebt; // 16-30 days
  final double overdueDebt; // 31+ days
  final double totalDebt;

  DebtAgingData({
    required this.recentDebt,
    required this.dueDebt,
    required this.overdueDebt,
    required this.totalDebt,
  });
}

final debtAgingProvider = FutureProvider<DebtAgingData>((ref) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);

  final allCustomers = await customerRepo.getAllCustomers();
  final customers = allCustomers.where((c) => c.debtBalance > 0).toList();
  final allOrders = await orderRepo.getAllOrders();
  final deliveredOrders = allOrders

      .toList();
  final Map<String, List<OrderEntity>> ordersByCustomer = {};
  for (final o in deliveredOrders) {
    ordersByCustomer.putIfAbsent(o.customerId, () => []).add(o);
  }

  double recent = 0.0;
  double due = 0.0;
  double overdue = 0.0;
  double total = 0.0;

  final now = DateTime.now();

  for (final customer in customers) {
    total += customer.debtBalance;

    // Find last order date of this customer
    final cOrders = ordersByCustomer[customer.id] ?? [];
    cOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    final lastOrder = cOrders.isNotEmpty ? cOrders.first : null;

    if (lastOrder != null) {
      final days = now.difference(lastOrder.orderDate).inDays;
      if (days <= 15) {
        recent += customer.debtBalance;
      } else if (days <= 30) {
        due += customer.debtBalance;
      } else {
        overdue += customer.debtBalance;
      }
    } else {
      // If no order is found but there is debt, classify it as overdue
      overdue += customer.debtBalance;
    }
  }

  return DebtAgingData(
    recentDebt: recent,
    dueDebt: due,
    overdueDebt: overdue,
    totalDebt: total,
  );
});
