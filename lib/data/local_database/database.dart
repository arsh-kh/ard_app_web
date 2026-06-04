import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Products,
  Categories,
  Customers,
  Orders,
  OrderItems,
  Payments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Add phone column to customers table
        await migrator.addColumn(customers, customers.phone);
      }
      if (from < 3) {
        await migrator.createTable(payments);
      }
      if (from < 4) {
        try {
          await migrator.addColumn(products, products.imageUrl);
        } catch (_) {}
        try {
          await migrator.addColumn(customers, customers.imageUrl);
        } catch (_) {}
        try {
          await migrator.addColumn(users, users.imageUrl);
        } catch (_) {}
      }
      if (from < 5) {
        // Add proper passwordHash column — replaces pw: prefix in phone field.
        // Data migration (pw:<hash> → passwordHash) is handled LAZILY at login
        // time in auth_provider.dart — no risky SQL needed here.
        try {
          await migrator.addColumn(users, users.passwordHash);
        } catch (_) {}
      }
      if (from < 6) {
        try {
          await migrator.addColumn(orders, orders.orderNumber);
        } catch (_) {}
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ard_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
