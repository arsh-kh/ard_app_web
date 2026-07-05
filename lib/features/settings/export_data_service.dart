import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/purchase_entity.dart';
import '../../data/models/payment_entity.dart';
import '../../data/models/audit_log_entity.dart';

class ExportDataService {
  // Existing CSV Exports
  static Future<void> exportCustomers(List<CustomerEntity> customers) async {
    final List<List<dynamic>> rows = [];
    rows.add(['ID', 'Name', 'Phone', 'Address', 'Debt Balance', 'Created At']);

    for (var c in customers) {
      rows.add([
        c.id,
        c.businessName,
        c.phone ?? '',
        c.address ?? '',
        c.debtBalance,
        c.createdAt.toString(),
      ]);
    }

    await _generateAndShareCsv('customers_export', rows);
  }

  static Future<void> exportInventory(List<ProductEntity> products) async {
    final List<List<dynamic>> rows = [];
    rows.add(['ID', 'Name', 'Buy Price', 'Sell Price', 'Stock', 'Unit']);

    for (var p in products) {
      rows.add([
        p.id,
        p.name,
        p.buyPrice,
        p.sellPrice,
        p.stockQuantity,
        p.unitType,
      ]);
    }

    await _generateAndShareCsv('inventory_export', rows);
  }

  static Future<void> exportMonthlySales(List<OrderEntity> orders) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Order ID', 'Date', 'Customer ID', 'Total Amount']);

    for (var o in orders) {
      rows.add([
        o.id,
        o.orderDate.toString(),
        o.customerId,
        o.totalAmount,
      ]);
    }

    await _generateAndShareCsv('monthly_sales_export', rows);
  }

  // New CSV Exports
  static Future<void> exportPurchases(List<PurchaseEntity> purchases) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Purchase ID', 'Date', 'Supplier ID', 'Total Amount']);

    for (var p in purchases) {
      rows.add([
        p.id,
        p.purchaseDate.toString(),
        p.supplierId,
        p.totalAmount,
      ]);
    }

    await _generateAndShareCsv('purchases_export', rows);
  }

  static Future<void> exportCustomerPayments(
    List<PaymentEntity> payments,
  ) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Payment ID', 'Date', 'Customer ID', 'Amount']);

    for (var p in payments) {
      rows.add([p.id, p.paymentDate.toString(), p.customerId, p.amount]);
    }

    await _generateAndShareCsv('customer_payments_export', rows);
  }

  static Future<void> exportAuditLogs(List<AuditLogEntity> logs) async {
    final List<List<dynamic>> rows = [];
    rows.add([
      'Log ID',
      'Created At',
      'User ID',
      'Action',
      'Entity Type',
      'Entity ID',
      'Details',
    ]);

    for (var l in logs) {
      rows.add([
        l.id,
        l.timestamp.toString(),
        l.userId,
        l.action,
        l.entityType,
        l.entityId,
        l.details ?? '',
      ]);
    }

    await _generateAndShareCsv('audit_logs_export', rows);
  }

  // Secure Full Backup (JSON format)
  static Future<void> exportFullBackup(
    Map<String, dynamic> fullDataSnapshot,
  ) async {
    try {
      final jsonString = jsonEncode(fullDataSnapshot);
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final path = '${directory.path}/workspace_backup_$dateStr.json';
      final file = File(path);

      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Here is your secure workspace backup (JSON).');
    } catch (e) {
      debugPrint('Error exporting full backup: $e');
    }
  }

  // Helper
  static Future<void> _generateAndShareCsv(
    String fileName,
    List<List<dynamic>> rows,
  ) async {
    try {
      final String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.csv';
      final file = File(path);

      // Write BOM for Excel UTF-8 compatibility
      await file.writeAsBytes([0xEF, 0xBB, 0xBF]);
      await file.writeAsString(csv, mode: FileMode.append);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Here is the $fileName exported data.');
    } catch (e) {
      debugPrint('Error exporting data: $e');
    }
  }
}
