import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local_database/database.dart';

class DashboardMetrics {
  final int thisWeekOrders;
  final int lastWeekOrders;
  final double thisWeekProfit;
  final double lastWeekProfit;
  final List<FlSpot> weeklyRevenueChart;
  final double maxWeeklyRevenue;

  DashboardMetrics({
    required this.thisWeekOrders,
    required this.lastWeekOrders,
    required this.thisWeekProfit,
    required this.lastWeekProfit,
    required this.weeklyRevenueChart,
    required this.maxWeeklyRevenue,
  });
}

class RecentActivityItem {
  final String orderId;
  final String customerName;
  final double totalAmount;
  final DateTime date;

  RecentActivityItem({
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.date,
  });
}

class ReportData {
  final double revenue;
  final double cogs;
  final double profit;
  final int ordersCount;

  ReportData({
    required this.revenue,
    required this.cogs,
    required this.profit,
    required this.ordersCount,
  });
}

final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) async* {
  final db = ref.watch(databaseProvider);
  
  final ordersStream = db.select(db.orders).watch();

  await for (final orders in ordersStream) {
    // We need to calculate profit. For accurate COGS, we should ideally have stored it. 
    // Since we didn't, we will use the CURRENT buyPrice from the Products table.
    final products = await db.select(db.products).get();
    final Map<String, double> productCosts = { for (var p in products) p.id : p.buyPrice };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Week definitions: This week = last 7 days. Last week = 7-14 days ago.
    final thisWeekStart = todayStart.subtract(const Duration(days: 6));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    int thisWeekOrd = 0;
    int lastWeekOrd = 0;
    double thisWeekProf = 0;
    double lastWeekProf = 0;
    
    List<double> dailyRevenues = List.filled(7, 0.0);

    for (final o in orders) {
      if (o.status == 'cancelled' || o.isDeleted) continue;
      
      final isThisWeek = o.orderDate.isAfter(thisWeekStart) || o.orderDate.isAtSameMomentAs(thisWeekStart);
      final isLastWeek = o.orderDate.isAfter(lastWeekStart) && o.orderDate.isBefore(thisWeekStart);

      if (isThisWeek || isLastWeek) {
        // Calculate Profit for this order
        final items = await (db.select(db.orderItems)..where((t) => t.orderId.equals(o.id))).get();
        double orderCogs = 0;
        for (var item in items) {
          final cost = productCosts[item.productId] ?? 0.0;
          orderCogs += item.quantity * cost;
        }
        final orderProfit = o.totalAmount - orderCogs;

        if (isThisWeek) {
          thisWeekOrd++;
          thisWeekProf += orderProfit;
          
          final daysAgo = todayStart.difference(DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day)).inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            dailyRevenues[6 - daysAgo] += o.totalAmount;
          }
        } else if (isLastWeek) {
          lastWeekOrd++;
          lastWeekProf += orderProfit;
        }
      }
    }

    List<FlSpot> spots = [];
    double maxRev = 0;
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyRevenues[i]));
      if (dailyRevenues[i] > maxRev) maxRev = dailyRevenues[i];
    }

    yield DashboardMetrics(
      thisWeekOrders: thisWeekOrd,
      lastWeekOrders: lastWeekOrd,
      thisWeekProfit: thisWeekProf,
      lastWeekProfit: lastWeekProf,
      weeklyRevenueChart: spots,
      maxWeeklyRevenue: maxRev,
    );
  }
});

final recentActivityProvider = StreamProvider<List<RecentActivityItem>>((ref) async* {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.orders).join([
    drift.leftOuterJoin(db.customers, db.customers.id.equalsExp(db.orders.customerId)),
  ])
    ..where(db.orders.isDeleted.equals(false))
    ..orderBy([drift.OrderingTerm.desc(db.orders.orderDate)])
    ..limit(5);

  final stream = query.watch();
  
  await for (final rows in stream) {
    yield rows.map((row) {
      final order = row.readTable(db.orders);
      final customer = row.readTableOrNull(db.customers);
      return RecentActivityItem(
        orderId: order.id,
        customerName: customer?.businessName ?? 'Unknown Client',
        totalAmount: order.totalAmount,
        date: order.orderDate,
      );
    }).toList();
  }
});

final topDebtorsProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)
        ..where((t) => t.isDeleted.equals(false))
        ..where((t) => t.id.isNotValue('walk-in'))
        ..where((t) => t.debtBalance.isBiggerThanValue(0.0))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.debtBalance)])
        ..limit(3))
      .watch();
});

final lowStockProvider = StreamProvider<List<ProductEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)
        ..where((t) => t.isDeleted.equals(false))
        ..where((t) => t.stockQuantity.isSmallerThanValue(50.0))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.stockQuantity)])
        ..limit(5))
      .watch();
});

// Used for fetching accurate report data on demand
Future<ReportData> fetchReportData(AppDatabase db, DateTime start, DateTime end) async {
  final products = await db.select(db.products).get();
  final Map<String, double> productCosts = { for (var p in products) p.id : p.buyPrice };

  final orders = await (db.select(db.orders)
        ..where((t) => t.isDeleted.equals(false))
        ..where((t) => t.status.isNotValue('cancelled'))
        ..where((t) => t.orderDate.isBetweenValues(start, end)))
      .get();

  double revenue = 0;
  double cogs = 0;

  for (final o in orders) {
    revenue += o.totalAmount;
    final items = await (db.select(db.orderItems)..where((t) => t.orderId.equals(o.id))).get();
    for (var item in items) {
      final cost = productCosts[item.productId] ?? 0.0;
      cogs += item.quantity * cost;
    }
  }

  return ReportData(
    revenue: revenue,
    cogs: cogs,
    profit: revenue - cogs,
    ordersCount: orders.length,
  );
}
