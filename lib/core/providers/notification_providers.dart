import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../../data/local_database/database.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'sync', 'stock', 'order'

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
        type: json['type'],
      );
}

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  final AppDatabase db;
  final NotificationService _notificationService = NotificationService();
  static const _prefsKey = 'app_notifications';

  NotificationNotifier(this.db) : super([]) {
    _loadFromPrefs().then((_) {
      _checkSystemAlerts();
    });
  }

  Future<void> _checkSystemAlerts() async {
    // 1. Check Low Stock
    final lowStockItems = await (db.select(db.products)
          ..where((t) => t.isDeleted.equals(false))
          ..where((t) => t.stockQuantity.isSmallerThanValue(50.0)))
        .get();

    if (lowStockItems.isNotEmpty) {
      // Create a notification for low stock, but only if we haven't alerted recently
      final title = 'Low Stock Alert';
      final message = '${lowStockItems.length} items are running low on stock (below 50 units).';
      
      final hasRecentAlert = state.any((n) => 
        n.type == 'stock' && 
        DateTime.now().difference(n.timestamp).inHours < 24
      );

      if (!hasRecentAlert) {
        await addNotification(title: title, message: message, type: 'stock');
      }
    }

    // 2. Check Overdue Debt (simplistic approach: customers with balance > 0)
    final debtCustomers = await (db.select(db.customers)
          ..where((t) => t.isDeleted.equals(false))
          ..where((t) => t.id.isNotValue('walk-in'))
          ..where((t) => t.debtBalance.isBiggerThanValue(0.0)))
        .get();

    if (debtCustomers.isNotEmpty) {
      final title = 'Debt Collection Reminder';
      final message = '${debtCustomers.length} clients have outstanding debt balances.';
      
      final hasRecentAlert = state.any((n) => 
        n.type == 'debt' && 
        DateTime.now().difference(n.timestamp).inHours < 48 // alert every 48 hours max
      );

      if (!hasRecentAlert) {
        await addNotification(title: title, message: message, type: 'debt');
      }
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    if (jsonList.isNotEmpty) {
      state = jsonList.map((j) => AppNotification.fromJson(jsonDecode(j))).toList();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    state = [notification, ...state];
    _saveToPrefs();

    await _notificationService.showNotification(
      id: notification.hashCode,
      title: title,
      body: message,
      payload: type,
    );
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
    _saveToPrefs();
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true)
    ];
    _saveToPrefs();
  }

  void clearAll() {
    state = [];
    _saveToPrefs();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationNotifier(db);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
