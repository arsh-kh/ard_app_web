import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/audit_service.dart';
import '../models/order_entity.dart';
import '../models/order_item_entity.dart';
import '../models/payment_entity.dart';
import '../../core/services/sequence_service.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  OrderRepository(this._auditService, this.businessId);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return DataSanitizer.sanitize(data);
  }

  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Stream<List<OrderEntity>> watchAllOrders() {
    if (businessId.isEmpty) return Stream.value([]);
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
    if (businessId.isEmpty) return Stream.value([]);
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
    if (businessId.isEmpty) return [];
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
    if (businessId.isEmpty) return [];
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
    if (businessId.isEmpty) return Stream.value([]);
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
    if (businessId.isEmpty) return [];
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
    if (businessId.isEmpty) return Stream.value(null);
    return _firestore.collection('orders').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      if (data['businessId'] != businessId) return null;
      return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...data}));
    });
  }

  Future<OrderEntity?> getOrder(String id) async {
    if (businessId.isEmpty) return null;
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data() as Map<String, dynamic>;
    if (data['businessId'] != businessId) return null;
    return OrderEntity.fromJson(_sanitizeData({'id': doc.id, ...data}));
  }

  Stream<List<OrderItemEntity>> watchOrderItems(String orderId) {
    if (businessId.isEmpty) return Stream.value([]);
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
    if (businessId.isEmpty) return [];
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
    if (businessId.isEmpty || orderIds.isEmpty) return [];
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
    _checkBusinessId();
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

      // Update stock
      final prodRef = _firestore.collection('products').doc(item.productId);
      final prodDoc = await prodRef.get();
      if (prodDoc.exists) {
        batch.update(prodRef, {
          'stockQuantity': FieldValue.increment(-item.quantity),
        });
      }
    }

    if (!finalOrder.customerId.startsWith('walk-in-')) {
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
      },
    );
  }

  Future<void> createOrderWithPayment(
    OrderEntity order,
    List<OrderItemEntity> items,
    PaymentEntity payment,
  ) async {
    _checkBusinessId();
    final batch = _firestore.batch();

    // 1. Generate Order
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

      // Update stock
      final prodRef = _firestore.collection('products').doc(item.productId);
      final prodDoc = await prodRef.get();
      if (prodDoc.exists) {
        batch.update(prodRef, {
          'stockQuantity': FieldValue.increment(-item.quantity),
        });
      }
    }

    // Customer Debt Logic
    // If it's a walk-in, we don't track debt.
    if (!finalOrder.customerId.startsWith('walk-in-')) {
      final custRef = _firestore
          .collection('customers')
          .doc(finalOrder.customerId);
      final custDoc = await custRef.get();
      if (custDoc.exists) {
        // Increment for order, Decrement for payment. 
        // We'll just do it in one atomic step (the net difference).
        final netChange = finalOrder.totalAmount - payment.amount;
        if (netChange != 0) {
          batch.update(custRef, {
            'debtBalance': FieldValue.increment(netChange),
          });
        }
      }
    }

    // 2. Generate Payment
    final paymentRef = _firestore.collection('payments').doc(payment.id);
    final finalPayment = payment.copyWith(
      businessId: businessId,
      orderId: finalOrder.id,
    );
    batch.set(paymentRef, finalPayment.toJson());

    // Commit all together
    await batch.commit();

    // Log Audits
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
      action: 'CREATED_WITH_PAYMENT',
      entityType: 'Order',
      entityId: finalOrder.id,
      details:
          'Sold ${items.length} product(s) to $customerName for ${finalOrder.totalAmount} IQD. Payment of ${finalPayment.amount} IQD collected immediately. (Order #${finalOrder.orderNumber})',
      metadata: {
        'orderNumber': finalOrder.orderNumber,
        'totalAmount': finalOrder.totalAmount,
        'paymentAmount': finalPayment.amount,
        'customerId': finalOrder.customerId,
        'customerName': customerName,
        'itemsCount': items.length,
      },
    );
  }



  Future<void> deleteOrder(String orderId) async {
    _checkBusinessId();
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

    // Also delete any explicitly linked payments to fix double-credit ledger bug
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .get();
        
    double totalDeletedPayments = 0.0;
    for (final pDoc in paymentsSnapshot.docs) {
      final pData = pDoc.data() as Map<String, dynamic>?;
      totalDeletedPayments += (pData?['amount'] as num?)?.toDouble() ?? 0.0;
      batch.delete(pDoc.reference);
    }

    // Restore stock and reduce debt.
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
        final rData = rDoc.data() as Map<String, dynamic>?;
        totalDeductedByReturns += (rData?['actualDeduction'] as num?)?.toDouble() ?? 0.0;
      }

      // The net debt revert must also account for any deleted upfront payments.
      // If we delete the payment, we must add its value back to the debt.
      final netDebtRevert = order.totalAmount - totalDeductedByReturns - totalDeletedPayments;

      if (netDebtRevert != 0) {
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
      },
    );
  }
}
