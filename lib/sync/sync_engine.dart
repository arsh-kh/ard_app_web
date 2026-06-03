import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../data/local_database/database.dart';
import '../data/local_database/tables.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref.watch(databaseProvider));
});

class SyncEngine {
  final AppDatabase _db;
  // Note: FirebaseFirestore.instance requires `flutterfire configure` and Firebase.initializeApp() to be run first.
  // We use a lazy getter so the app doesn't crash on startup if Firebase isn't initialized yet.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncEngine(this._db);

  /// Starts monitoring network state to trigger automatic syncing.
  void startMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection) {
        // Double check actual internet access, not just local network
        final hasInternet = await InternetConnection().hasInternetAccess;
        if (hasInternet) {
          triggerSync();
        }
      }
    });
  }

  void stopMonitoring() {
    _connectivitySubscription?.cancel();
  }

  /// Triggers a sync of all local pending changes to Firebase.
  /// Returns the total number of items successfully synced.
  Future<int> triggerSync() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int syncedCount = 0;

    try {
      syncedCount += await _syncTable(
        tableName: 'products',
        pendingItemsFetcher: () => (_db.select(_db.products)..where((t) => t.syncStatus.equals(SyncStatus.pendingSync.index))).get(),
        updater: (id, status) => (_db.update(_db.products)..where((t) => t.id.equals(id))).write(ProductsCompanion(syncStatus: Value(status))),
        toJson: (item) => (item as ProductEntity).toJson(),
      );

      syncedCount += await _syncTable(
        tableName: 'customers',
        pendingItemsFetcher: () => (_db.select(_db.customers)..where((t) => t.syncStatus.equals(SyncStatus.pendingSync.index))).get(),
        updater: (id, status) => (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(CustomersCompanion(syncStatus: Value(status))),
        toJson: (item) => (item as CustomerEntity).toJson(),
      );

      syncedCount += await _syncTable(
        tableName: 'orders',
        pendingItemsFetcher: () => (_db.select(_db.orders)..where((t) => t.syncStatus.equals(SyncStatus.pendingSync.index))).get(),
        updater: (id, status) => (_db.update(_db.orders)..where((t) => t.id.equals(id))).write(OrdersCompanion(syncStatus: Value(status))),
        toJson: (item) => (item as OrderEntity).toJson(),
      );

      syncedCount += await _syncTable(
        tableName: 'order_items',
        pendingItemsFetcher: () => (_db.select(_db.orderItems)..where((t) => t.syncStatus.equals(SyncStatus.pendingSync.index))).get(),
        updater: (id, status) => (_db.update(_db.orderItems)..where((t) => t.id.equals(id))).write(OrderItemsCompanion(syncStatus: Value(status))),
        toJson: (item) => (item as OrderItemEntity).toJson(),
      );

    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
    return syncedCount;
  }

  Future<int> _syncTable({
    required String tableName,
    required Future<List<dynamic>> Function() pendingItemsFetcher,
    required Future<void> Function(String id, SyncStatus status) updater,
    required Map<String, dynamic> Function(dynamic item) toJson,
  }) async {
    final pendingItems = await pendingItemsFetcher();
    int successCount = 0;

    for (final item in pendingItems) {
      try {
        await updater(item.id, SyncStatus.syncing);

        final collection = _firestore.collection(tableName);
        
        if (item.isDeleted) {
          await collection.doc(item.id).delete();
        } else {
          // Push to firestore
          final dataMap = toJson(item);
          dataMap.remove('syncStatus'); 
          
          await collection.doc(item.id).set(dataMap, SetOptions(merge: true));
        }
        
        await updater(item.id, SyncStatus.synced);
        successCount++;
      } catch (e) {
        await updater(item.id, SyncStatus.failed);
      }
    }
    return successCount;
  }
}
