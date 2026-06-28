import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/audit_service.dart';
import '../models/order_entity.dart';
import '../models/order_item_entity.dart';
import '../../core/services/sequence_service.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  OrderRepository(this._auditService, this.businessId);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return DataSanitizer.sanitize(data);
  }

  Stream<List<OrderEntity>> watchAllOrders() {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => OrderEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Stream<List<OrderEntity>> watchOrdersByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('orderDate', isGreaterThanOrEqualTo: start)
        .where('orderDate', isLessThanOrEqualTo: end)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => OrderEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Future<List<OrderEntity>> getOrdersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('orderDate', isGreaterThanOrEqualTo: start)
        .where('orderDate', isLessThanOrEqualTo: end)
        .orderBy('orderDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => OrderEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
  }

  Future<List<OrderEntity>> getAllOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .orderBy('orderDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => OrderEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
  }

  Stream<List<OrderEntity>> watchOrdersByCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => OrderEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList();
          list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return list;
        });
  }

  Future<List<OrderEntity>> getOrdersByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => OrderEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
    list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  Stream<OrderEntity?> watchOrder(String id) {
    return _firestore.collection('orders').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['businessId'] != businessId) return null;
      return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...data}));
    });
  }

  Future<OrderEntity?> getOrder(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['businessId'] != businessId) return null;
    return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...data}));
  }

  Stream<List<OrderItemEntity>> watchOrderItems(String orderId) {
    return _firestore
        .collection('order_items')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => OrderItemEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    final snapshot = await _firestore
        .collection('order_items')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .get();
    return snapshot.docs
        .map(
          (doc) => OrderItemEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
  }

  Future<List<OrderItemEntity>> getOrderItemsForOrders(
    List<String> orderIds,
  ) async {
    final List<OrderItemEntity> allItems = [];
    for (var i = 0; i < orderIds.length; i += 30) {
      final chunk = orderIds.sublist(
        i,
        i + 30 > orderIds.length ? orderIds.length : i + 30,
      );
      if (chunk.isEmpty) continue;
      final snapshot = await _firestore
          .collection('order_items')
          .where('businessId', isEqualTo: businessId)
          .where('orderId', whereIn: chunk)
          .get();
      allItems.addAll(
        snapshot.docs
            .map(
              (doc) => OrderItemEntity.fromJson(
                _sanitizeData({'id': doc.id, ...doc.data()}),
              ),
            )
            .toList(),
      );
    }
    return allItems;
  }

  Future<void> createOrder(
    OrderEntity order,
    List<OrderItemEntity> items,
  ) async {
    final batch = _firestore.batch();

    // Use atomic sequence for order number
    final orderNum = await SequenceService.getNextSequence(
      'orders',
      businessId: businessId,
    );
    final finalOrder = order.copyWith(
      orderNumber: orderNum,
      businessId: businessId,
    );

    final orderRef = _firestore.collection('orders').doc(finalOrder.id);
    batch.set(orderRef, finalOrder.toJson());

    for (final item in items) {
      final itemRef = _firestore.collection('order_items').doc(item.id);
      final finalItem = item.copyWith(businessId: businessId);
      batch.set(itemRef, finalItem.toJson());

      // If delivered immediately, update stock
      if (finalOrder.status == 'delivered') {
        final prodRef = _firestore.collection('products').doc(item.productId);
        final prodDoc = await prodRef.get();
        if (prodDoc.exists) {
          batch.update(prodRef, {
            'stockQuantity': FieldValue.increment(-item.quantity),
          });
        }
      }
    }

    if (finalOrder.status == 'delivered' &&
        !finalOrder.customerId.startsWith('walk-in-')) {
      final custRef = _firestore
          .collection('customers')
          .doc(finalOrder.customerId);
      final custDoc = await custRef.get();
      if (custDoc.exists) {
        batch.update(custRef, {
          'debtBalance': FieldValue.increment(finalOrder.totalAmount),
        });
      }
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (!finalOrder.customerId.startsWith('walk-in-')) {
      final custDoc = await _firestore
          .collection('customers')
          .doc(finalOrder.customerId)
          .get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'CREATED',
      entityType: 'Order',
      entityId: finalOrder.id,
      details:
          'Sold ${items.length} product(s) to $customerName for ${finalOrder.totalAmount} IQD. (Order #${finalOrder.orderNumber})',
      metadata: {
        'orderNumber': finalOrder.orderNumber,
        'totalAmount': finalOrder.totalAmount,
        'customerId': finalOrder.customerId,
        'customerName': customerName,
        'itemsCount': items.length,
        'status': finalOrder.status,
      },
    );
  }

  Future<void> markOrderDelivered(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null || order.status == 'delivered') return;

    final items = await getOrderItems(orderId);
    final batch = _firestore.batch();

    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': 'delivered',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final item in items) {
      final prodRef = _firestore.collection('products').doc(item.productId);
      final prodDoc = await prodRef.get();
      if (prodDoc.exists) {
        batch.update(prodRef, {
          'stockQuantity': FieldValue.increment(-item.quantity),
        });
      }
    }

    if (!order.customerId.startsWith('walk-in-')) {
      final custRef = _firestore.collection('customers').doc(order.customerId);
      final custDoc = await custRef.get();
      if (custDoc.exists) {
        batch.update(custRef, {
          'debtBalance': FieldValue.increment(order.totalAmount),
        });
      }
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'DELIVERED',
      entityType: 'Order',
      entityId: orderId,
      details:
          'Marked Order #${order.orderNumber} as Delivered. Stock deducted and debt updated.',
      metadata: {
        'orderNumber': order.orderNumber,
        'totalAmount': order.totalAmount,
        'customerId': order.customerId,
        'itemsCount': items.length,
      },
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
      metadata: {'newStatus': newStatus},
    );
  }

  Future<void> deleteOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final itemsSnapshot = await _firestore
        .collection('order_items')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .get();

    final batch = _firestore.batch();

    batch.delete(_firestore.collection('orders').doc(orderId));
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Also delete orphan returns and return_items
    final returnsSnapshot = await _firestore
        .collection('returns')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .get();
    for (final rDoc in returnsSnapshot.docs) {
      batch.delete(rDoc.reference);
      final returnItemsSnapshot = await _firestore
          .collection('return_items')
          .where('businessId', isEqualTo: businessId)
          .where('returnId', isEqualTo: rDoc.id)
          .get();
      for (final riDoc in returnItemsSnapshot.docs) {
        batch.delete(riDoc.reference);
      }
    }

    // If the order was delivered, restore stock and reduce debt.
    if (order.status == 'delivered') {
      // ── Parse items safely through _sanitizeData ─────────────────────────
      final items = itemsSnapshot.docs
          .map((doc) {
            try {
              return OrderItemEntity.fromJson(
                _sanitizeData({'id': doc.id, ...doc.data()}),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<OrderItemEntity>()
          .toList();

      for (final item in items) {
        try {
          // Guard: only update if the product document still exists.
          final prodDoc = await _firestore
              .collection('products')
              .doc(item.productId)
              .get();
          if (prodDoc.exists) {
            final netQuantityRevert = item.quantity - item.returnedQuantity;
            if (netQuantityRevert > 0) {
              batch.update(prodDoc.reference, {
                'stockQuantity': FieldValue.increment(netQuantityRevert),
              });
            }
          }
        } catch (_) {
          // Product was deleted — skip silently.
        }
      }

      if (!order.customerId.startsWith('walk-in-')) {
        // Fetch all returns for this order to find actual debt deductions
        final returnsSnapshot = await _firestore
            .collection('returns')
            .where('businessId', isEqualTo: businessId)
            .where('orderId', isEqualTo: orderId)
            .get();

        double totalDeductedByReturns = 0.0;
        for (final rDoc in returnsSnapshot.docs) {
          totalDeductedByReturns +=
              (rDoc.data()['actualDeduction'] as num?)?.toDouble() ?? 0.0;
        }

        final netDebtRevert = order.totalAmount - totalDeductedByReturns;

        if (netDebtRevert > 0) {
          final custRef = _firestore
              .collection('customers')
              .doc(order.customerId);
          final custDoc = await custRef.get();
          if (custDoc.exists) {
            batch.update(custRef, {
              'debtBalance': FieldValue.increment(-netDebtRevert),
            });
          }
        }
      }
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Order',
      entityId: orderId,
      details:
          'Deleted Order #${order.orderNumber}. Stock and Debt reverted if it was delivered.',
      metadata: {
        'orderNumber': order.orderNumber,
        'totalAmount': order.totalAmount,
        'customerId': order.customerId,
        'statusBeforeDelete': order.status,
      },
    );
  }
}
