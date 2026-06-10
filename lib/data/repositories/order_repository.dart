import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/order_entity.dart';
import '../models/order_item_entity.dart';


class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  OrderRepository(this._auditService);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final doubleFields = ['amount', 'totalAmount', 'debtBalance', 'buyPrice', 'sellPrice', 'unitPrice', 'stockQuantity', 'quantity', 'discount', 'totalReturnedAmount', 'returnedQuantity', 'totalRefund', 'returnedQty', 'actualDeduction', 'debtBefore', 'debtAfter'];
    final intFields = ['orderNumber'];
    final dateFields = ['createdAt', 'updatedAt', 'date', 'timestamp', 'orderDate', 'paymentDate'];

    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is int) {
        if (dateFields.contains(key)) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
        } else if (doubleFields.contains(key)) {
          sanitized[key] = value.toDouble();
        } else if (!intFields.contains(key)) {
          sanitized[key] = value.toString();
        }
      } else if (value is double) {
        if (intFields.contains(key)) {
          sanitized[key] = value.toInt();
        } else if (!doubleFields.contains(key)) {
           sanitized[key] = value.toString();
        }
      } else if (value is String && dateFields.contains(key)) {
        final parsedInt = int.tryParse(value);
        if (parsedInt != null) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(parsedInt).toIso8601String();
        }
      }
    });
    return sanitized;
  }

  Stream<List<OrderEntity>> watchAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .toList());
  }

  Stream<List<OrderEntity>> watchOrdersByCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .toList());
  }

  Future<List<OrderEntity>> getOrdersByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
        .toList();
  }

  Stream<OrderEntity?> watchOrder(String id) {
    return _firestore.collection('orders').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()!}));
    });
  }

  Future<OrderEntity?> getOrder(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists) return null;
    return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()!}));
  }

  Stream<List<OrderItemEntity>> watchOrderItems(String orderId) {
    return _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderItemEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .toList());
  }

  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    final snapshot = await _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();
    return snapshot.docs
        .map((doc) => OrderItemEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
        .toList();
  }

  Future<List<OrderItemEntity>> getOrderItemsForOrders(List<String> orderIds) async {
    final List<OrderItemEntity> allItems = [];
    for (var i = 0; i < orderIds.length; i += 30) {
      final chunk = orderIds.sublist(i, i + 30 > orderIds.length ? orderIds.length : i + 30);
      if (chunk.isEmpty) continue;
      final snapshot = await _firestore
          .collection('order_items')
          .where('orderId', whereIn: chunk)
          .get();
      allItems.addAll(snapshot.docs
          .map((doc) => OrderItemEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
          .toList());
    }
    return allItems;
  }

  Future<void> createOrder(OrderEntity order, List<OrderItemEntity> items) async {
    final batch = _firestore.batch();
    
    // Use document count + 1 for auto-incrementing order number
    final countSnapshot = await _firestore.collection('orders').count().get();
    final orderNum = (countSnapshot.count ?? 0) + 1;
    final finalOrder = order.copyWith(orderNumber: orderNum);

    final orderRef = _firestore.collection('orders').doc(finalOrder.id);
    batch.set(orderRef, finalOrder.toJson());

    for (final item in items) {
      final itemRef = _firestore.collection('order_items').doc(item.id);
      batch.set(itemRef, item.toJson());

      // If delivered immediately, update stock
      if (finalOrder.status == 'delivered') {
        final prodRef = _firestore.collection('products').doc(item.productId);
        // Using FieldValue.increment to decrease stock
        batch.update(prodRef, {'stockQuantity': FieldValue.increment(-item.quantity)});
      }
    }

    if (finalOrder.status == 'delivered' && finalOrder.customerId != 'walk-in' && finalOrder.customerId != 'walk-in-customer-id') {
      final custRef = _firestore.collection('customers').doc(finalOrder.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(finalOrder.totalAmount)});
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (finalOrder.customerId != 'walk-in' && finalOrder.customerId != 'walk-in-customer-id') {
      final custDoc = await _firestore.collection('customers').doc(finalOrder.customerId).get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'CREATED',
      entityType: 'Order',
      entityId: finalOrder.id,
      details: 'Sold ${items.length} product(s) to $customerName for ${finalOrder.totalAmount} IQD. (Order #${finalOrder.orderNumber})',
    );
  }

  Future<void> markOrderDelivered(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null || order.status == 'delivered') return;

    final items = await getOrderItems(orderId);
    final batch = _firestore.batch();

    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {'status': 'delivered', 'updatedAt': FieldValue.serverTimestamp()});

    for (final item in items) {
      final prodRef = _firestore.collection('products').doc(item.productId);
      batch.update(prodRef, {'stockQuantity': FieldValue.increment(-item.quantity)});
    }

    if (order.customerId != 'walk-in' && order.customerId != 'walk-in-customer-id') {
      final custRef = _firestore.collection('customers').doc(order.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(order.totalAmount)});
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'DELIVERED',
      entityType: 'Order',
      entityId: orderId,
      details: 'Marked Order #${order.orderNumber} as Delivered. Stock deducted and debt updated.',
    );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'STATUS_UPDATED',
      entityType: 'Order',
      entityId: orderId,
      details: 'Changed Order status to $newStatus',
    );
  }

  Future<void> deleteOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final itemsSnapshot = await _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();

    final batch = _firestore.batch();

    batch.delete(_firestore.collection('orders').doc(orderId));
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // If the order was delivered, restore stock and reduce debt.
    if (order.status == 'delivered') {
      // ── Parse items safely through _sanitizeData ─────────────────────────
      final items = itemsSnapshot.docs.map((doc) {
        try {
          return OrderItemEntity.fromJson(
              _sanitizeData({'id': doc.id, ...doc.data()}));
        } catch (_) {
          return null;
        }
      }).whereType<OrderItemEntity>().toList();

      for (final item in items) {
        try {
          // Guard: only update if the product document still exists.
          final prodDoc = await _firestore
              .collection('products')
              .doc(item.productId)
              .get();
          if (prodDoc.exists) {
            batch.update(prodDoc.reference,
                {'stockQuantity': FieldValue.increment(item.quantity)});
          }
        } catch (_) {
          // Product was deleted — skip silently.
        }
      }

      if (order.customerId != 'walk-in' &&
          order.customerId != 'walk-in-customer-id') {
        final custRef =
            _firestore.collection('customers').doc(order.customerId);
        batch.update(
            custRef, {'debtBalance': FieldValue.increment(-order.totalAmount)});
      }
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Order',
      entityId: orderId,
      details:
          'Deleted Order #${order.orderNumber}. Stock and Debt reverted if it was delivered.',
    );
  }
  Future<List<OrderEntity>> getAllOrders() async {
    final snapshot = await _firestore.collection('orders').orderBy('orderDate', descending: true).get();
    return snapshot.docs.map((doc) => OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList();
  }
}
