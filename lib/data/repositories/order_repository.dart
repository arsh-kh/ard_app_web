import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/order_entity.dart';
import '../models/order_item_entity.dart';


class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  OrderRepository(this._auditService);

  Stream<List<OrderEntity>> watchAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderEntity.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Stream<List<OrderEntity>> watchOrdersByCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderEntity.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<List<OrderEntity>> getOrdersByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => OrderEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Stream<OrderEntity?> watchOrder(String id) {
    return _firestore.collection('orders').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderEntity.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  Future<OrderEntity?> getOrder(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists) return null;
    return OrderEntity.fromJson({'id': doc.id, ...doc.data()!});
  }

  Stream<List<OrderItemEntity>> watchOrderItems(String orderId) {
    return _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderItemEntity.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    final snapshot = await _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();
    return snapshot.docs
        .map((doc) => OrderItemEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> createOrder(OrderEntity order, List<OrderItemEntity> items) async {
    final batch = _firestore.batch();
    
    // Auto-increment order number is tricky in NoSQL. 
    // Using a counter document or timestamp as fallback.
    // For simplicity, we just use timestamp seconds if we don't have a transaction counter.
    final orderNum = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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

    if (finalOrder.status == 'delivered') {
      final custRef = _firestore.collection('customers').doc(finalOrder.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(finalOrder.totalAmount)});
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'CREATED',
      entityType: 'Order',
      entityId: finalOrder.id,
      details: 'Created order #${finalOrder.orderNumber} for ${finalOrder.totalAmount}',
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

    final custRef = _firestore.collection('customers').doc(order.customerId);
    batch.update(custRef, {'debtBalance': FieldValue.increment(order.totalAmount)});

    await batch.commit();

    await _auditService.logAction(
      action: 'DELIVERED',
      entityType: 'Order',
      entityId: orderId,
      details: 'Marked order #${order.orderNumber} as delivered',
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
      details: 'Changed status to $newStatus',
    );
  }

  Future<void> deleteOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final batch = _firestore.batch();

    // Instead of isDeleted, we might actually delete from Firestore, or soft delete.
    // For now, let's delete to keep it clean.
    batch.delete(_firestore.collection('orders').doc(orderId));

    final itemsSnapshot = await _firestore.collection('order_items').where('orderId', isEqualTo: orderId).get();
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    if (order.status == 'delivered') {
      final items = itemsSnapshot.docs.map((doc) => OrderItemEntity.fromJson({'id': doc.id, ...doc.data()})).toList();
      for (final item in items) {
        final prodRef = _firestore.collection('products').doc(item.productId);
        batch.update(prodRef, {'stockQuantity': FieldValue.increment(item.quantity)});
      }

      final custRef = _firestore.collection('customers').doc(order.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(-order.totalAmount)});
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Order',
      entityId: orderId,
      details: 'Deleted order #${order.orderNumber}',
    );
  }
  Future<List<OrderEntity>> getAllOrders() async {
    final snapshot = await _firestore.collection('orders').orderBy('orderDate', descending: true).get();
    return snapshot.docs.map((doc) => OrderEntity.fromJson({'id': doc.id, ...doc.data()})).toList();
  }
}
