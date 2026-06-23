import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/payment_entity.dart';
import 'order_providers.dart';
import 'payment_providers.dart';
import 'inventory_providers.dart';
import 'customer_providers.dart';
import 'return_providers.dart';
import 'locale_provider.dart';
import 'purchase_providers.dart';
import '../utils/app_translations.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/purchase_entity.dart';

class DashboardMetrics {
  final int thisWeekOrders;
  final int lastWeekOrders;
  final double thisWeekRevenue;
  final double thisWeekExpenses;
  final double thisWeekProfit;
  final double lastWeekProfit;
  final List<FlSpot> weeklyRevenueChart;
  final double maxWeeklyRevenue;

  DashboardMetrics({
    required this.thisWeekOrders,
    required this.lastWeekOrders,
    required this.thisWeekRevenue,
    required this.thisWeekExpenses,
    required this.thisWeekProfit,
    required this.lastWeekProfit,
    required this.weeklyRevenueChart,
    required this.maxWeeklyRevenue,
  });
}

class RecentActivityItem {
  final String orderId; // or payment id
  final String customerName;
  final double totalAmount;
  final DateTime date;
  final bool isPayment;
  final String? status;
  final int? orderNumber;

  RecentActivityItem({
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.date,
    this.isPayment = false,
    this.status,
    this.orderNumber,
  });
}

class ProductPerformance {
  final String productName;
  final double quantitySold;
  final double revenue;
  final double profit;
  ProductPerformance(
    this.productName,
    this.quantitySold,
    this.revenue,
    this.profit,
  );
}

class CustomerPerformance {
  final String customerName;
  final int orderCount;
  final double totalSpent;
  CustomerPerformance(this.customerName, this.orderCount, this.totalSpent);
}

class ReportData {
  final double revenue;
  final double cogs;
  final double profit;
  final int ordersCount;
  final double totalReturns;
  final int returnCount;
  final List<ProductPerformance> topProducts;
  final List<CustomerPerformance> topCustomers;

  ReportData({
    required this.revenue,
    required this.cogs,
    required this.profit,
    required this.ordersCount,
    required this.totalReturns,
    required this.returnCount,
    required this.topProducts,
    required this.topCustomers,
  });
}

final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) async* {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final purchaseRepo = ref.watch(purchaseRepositoryProvider);

  final ordersStream = orderRepo.watchAllOrders();
  final purchasesStream = purchaseRepo.watchAllPurchases();

  await for (final combo in CombineLatestStream.combine2(
    ordersStream,
    purchasesStream,
    (List<OrderEntity> orders, List<PurchaseEntity> purchases) => {
      'orders': orders,
      'purchases': purchases,
    },
  )) {
    final orders = combo['orders'] as List<OrderEntity>;
    final purchases = combo['purchases'] as List<PurchaseEntity>;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final thisWeekStart = todayStart.subtract(const Duration(days: 6));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    int thisWeekOrd = 0;
    int lastWeekOrd = 0;
    double thisWeekRev = 0;
    double thisWeekExp = 0;
    double lastWeekProf =
        0; // Keeping old profit calc for last week comparison for now

    final List<double> dailyRevenues = List.filled(7, 0.0);

    for (final o in orders) {
      if (o.status == 'cancelled') continue;

      final isThisWeek =
          o.orderDate.isAfter(thisWeekStart) ||
          o.orderDate.isAtSameMomentAs(thisWeekStart);
      final isLastWeek =
          o.orderDate.isAfter(lastWeekStart) &&
          o.orderDate.isBefore(thisWeekStart);

      if (isThisWeek || isLastWeek) {
        final netRevenue = o.totalAmount - o.totalReturnedAmount;

        if (isThisWeek) {
          thisWeekOrd++;
          thisWeekRev += netRevenue;

          final daysAgo = todayStart
              .difference(
                DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day),
              )
              .inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            dailyRevenues[6 - daysAgo] += netRevenue;
          }
        } else if (isLastWeek) {
          lastWeekOrd++;
          // simplified last week profit for comparison
          lastWeekProf += netRevenue;
        }
      }
    }

    for (final p in purchases) {
      if (p.status == 'cancelled') continue;

      final isThisWeek =
          p.purchaseDate.isAfter(thisWeekStart) ||
          p.purchaseDate.isAtSameMomentAs(thisWeekStart);
      final isLastWeek =
          p.purchaseDate.isAfter(lastWeekStart) &&
          p.purchaseDate.isBefore(thisWeekStart);

      if (isThisWeek) {
        thisWeekExp += (p.totalAmount - p.totalReturnedAmount);
      } else if (isLastWeek) {
        lastWeekProf -= (p.totalAmount - p.totalReturnedAmount);
      }
    }

    final thisWeekProf = thisWeekRev - thisWeekExp;

    final List<FlSpot> spots = [];
    double maxRev = 0;
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyRevenues[i]));
      if (dailyRevenues[i] > maxRev) maxRev = dailyRevenues[i];
    }

    yield DashboardMetrics(
      thisWeekOrders: thisWeekOrd,
      lastWeekOrders: lastWeekOrd,
      thisWeekRevenue: thisWeekRev,
      thisWeekExpenses: thisWeekExp,
      thisWeekProfit: thisWeekProf,
      lastWeekProfit: lastWeekProf,
      weeklyRevenueChart: spots,
      maxWeeklyRevenue: maxRev,
    );
  }
});

final recentActivityProvider = StreamProvider<List<RecentActivityItem>>((ref) {
  final langCode = ref.watch(localeProvider).languageCode;
  final orderRepo = ref.watch(orderRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);

  final ordersStream = orderRepo.watchAllOrders();
  final paymentsStream = paymentRepo.watchAllPayments();
  final customersStream = customerRepo.watchAllCustomers();

  return CombineLatestStream.combine3(
    ordersStream,
    paymentsStream,
    customersStream,
    (
      List<OrderEntity> orders,
      List<PaymentEntity> payments,
      List<CustomerEntity> customers,
    ) {
      final List<RecentActivityItem> combined = [];
      final customerMap = {for (var c in customers) c.id: c.businessName};

      for (final order in orders) {
        final isWalkIn =
            order.customerId == 'walk-in' ||
            order.customerId == 'walk-in-customer-id';
        combined.add(
          RecentActivityItem(
            orderId: order.id,
            customerName: isWalkIn
                ? Tr.t('auto_WalkInCustomer', langCode)
                : customerMap[order.customerId] ??
                      Tr.t('unknownCustomer', langCode),
            totalAmount: order.totalAmount,
            date: order.orderDate,
            isPayment: false,
            status: order.status,
            orderNumber: order.orderNumber,
          ),
        );
      }

      for (final payment in payments) {
        final isWalkIn =
            payment.customerId == 'walk-in' ||
            payment.customerId == 'walk-in-customer-id';
        // Hide duplicate payments for walk-in customers since their orders are always fully paid simultaneously
        if (isWalkIn) continue;

        combined.add(
          RecentActivityItem(
            orderId: payment.id,
            customerName:
                customerMap[payment.customerId] ??
                Tr.t('unknownCustomer', langCode),
            totalAmount: payment.amount,
            date: payment.paymentDate,
            isPayment: true,
          ),
        );
      }

      // Sort by newest first
      combined.sort((a, b) => b.date.compareTo(a.date));
      return combined.take(5).toList();
    },
  );
});

final topDebtorsProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final customerRepo = ref.watch(customerRepositoryProvider);
  return customerRepo.watchAllCustomers().map((customers) {
    final debtors = customers
        .where((c) => c.id != 'walk-in' && c.debtBalance > 0)
        .toList();
    debtors.sort((a, b) => b.debtBalance.compareTo(a.debtBalance));
    return debtors.take(3).toList();
  });
});

final lowStockProvider = StreamProvider<List<ProductEntity>>((ref) {
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  return inventoryRepo.watchAllProducts().map((products) {
    final lowStock = products.where((p) {
      final lowStockLimit = p.lowStockThreshold ?? 30.0;
      return p.stockQuantity <= lowStockLimit;
    }).toList();
    lowStock.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    return lowStock.take(5).toList();
  });
});

Future<ReportData> fetchReportData(
  WidgetRef ref,
  DateTime start,
  DateTime end,
  String langCode,
) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final inventoryRepo = ref.read(inventoryRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);
  final returnRepo = ref.read(returnRepositoryProvider);
  final purchaseRepo = ref.read(purchaseRepositoryProvider);

  final allOrders = await orderRepo.getAllOrders();
  final allProducts = await inventoryRepo.getAllProducts();
  final allCustomers = await customerRepo.getAllCustomers();
  final allReturns = await returnRepo.getAllReturns();
  final allPurchases = await purchaseRepo.getAllPurchases();

  final orders = allOrders
      .where(
        (o) =>
            o.status != 'cancelled' &&
            o.orderDate.isAfter(start) &&
            o.orderDate.isBefore(end),
      )
      .toList();

  final returnsInPeriod = allReturns
      .where((r) => r.returnDate.isAfter(start) && r.returnDate.isBefore(end))
      .toList();

  double totalReturns = 0;
  for (final r in returnsInPeriod) {
    totalReturns += r.totalRefund;
  }

  final purchasesInPeriod = allPurchases
      .where(
        (p) =>
            p.status != 'cancelled' &&
            p.purchaseDate.isAfter(start) &&
            p.purchaseDate.isBefore(end),
      )
      .toList();

  double actualPurchases = 0;
  for (final p in purchasesInPeriod) {
    actualPurchases += (p.totalAmount - p.totalReturnedAmount);
  }

  double revenue = 0;
  double cogs = 0;
  final int ordersCount = orders.length;

  final Map<String, double> productQty = {};
  final Map<String, double> productRev = {};
  final Map<String, double> productProf = {};

  final Map<String, int> customerOrderCount = {};
  final Map<String, double> customerSpent = {};

  final orderIds = orders.map((o) => o.id).toList();
  final items = await orderRepo.getOrderItemsForOrders(orderIds);
  final Map<String, List<OrderItemEntity>> itemsByOrderId = {};
  for (final item in items) {
    itemsByOrderId.putIfAbsent(item.orderId, () => []).add(item);
  }

  for (final o in orders) {
    revenue += o.totalAmount;

    customerOrderCount[o.customerId] =
        (customerOrderCount[o.customerId] ?? 0) + 1;
    customerSpent[o.customerId] =
        (customerSpent[o.customerId] ?? 0) + o.totalAmount;

    final oItems = itemsByOrderId[o.id] ?? [];
    double rawTotal = 0.0;
    for (final item in oItems) {
      rawTotal += item.unitPrice * item.quantity;
    }
    final discountRatio = rawTotal > 0 ? o.totalAmount / rawTotal : 1.0;

    for (final item in oItems) {
      final p = allProducts.firstWhere(
        (prod) => prod.id == item.productId,
        orElse: () => ProductEntity(
          id: '',
          name: Tr.t('unknownProduct', langCode),
          categoryId: '',
          buyPrice: 0,
          sellPrice: 0,
          stockQuantity: 0,
          unitType: '',
        ),
      );

      final costPrice = item.buyPrice > 0 ? item.buyPrice : p.buyPrice;

      // Fix: deduct returned items from COGS and product revenue
      final actualQty = (item.quantity - item.returnedQuantity).clamp(
        0.0,
        double.infinity,
      );
      final cost = costPrice * actualQty;
      final rev = (item.unitPrice * actualQty) * discountRatio;
      final prof = rev - cost;

      productQty[item.productId] =
          (productQty[item.productId] ?? 0) + actualQty;
      productRev[item.productId] = (productRev[item.productId] ?? 0) + rev;
      productProf[item.productId] = (productProf[item.productId] ?? 0) + prof;
    }
  }

  cogs = actualPurchases;
  final profit = revenue - cogs - totalReturns;

  final topProducts = productQty.keys.map((pId) {
    final p = allProducts.firstWhere(
      (prod) => prod.id == pId,
      orElse: () => ProductEntity(
        id: '',
        name: Tr.t('unknownProduct', langCode),
        categoryId: '',
        buyPrice: 0,
        sellPrice: 0,
        stockQuantity: 0,
        unitType: '',
      ),
    );
    return ProductPerformance(
      p.name,
      productQty[pId]!,
      productRev[pId]!,
      productProf[pId]!,
    );
  }).toList();
  topProducts.sort((a, b) => b.profit.compareTo(a.profit));

  final topCustomers = customerSpent.keys.map((cId) {
    final c = allCustomers.firstWhere(
      (cust) => cust.id == cId,
      orElse: () => CustomerEntity(
        id: '',
        businessName: Tr.t('unknownCustomer', langCode),
        debtBalance: 0,
        createdAt: DateTime.now(),
      ),
    );
    return CustomerPerformance(
      c.businessName,
      customerOrderCount[cId]!,
      customerSpent[cId]!,
    );
  }).toList();
  topCustomers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

  return ReportData(
    revenue: revenue,
    cogs: cogs,
    profit: profit,
    ordersCount: ordersCount,
    totalReturns: totalReturns,
    returnCount: returnsInPeriod.length,
    topProducts: topProducts.take(5).toList(),
    topCustomers: topCustomers.take(5).toList(),
  );
}
