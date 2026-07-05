import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/return_entity.dart';
import '../models/return_item_entity.dart';

/// Holds the before/after debt figures for display in the UI.
class DebtCalculation {
  final double debtBefore;
  final double debtAfter;
  final double actualDeduction;

  const DebtCalculation({
    required this.debtBefore,
    required this.debtAfter,
    required this.actualDeduction,
  });
}

class ReturnRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  ReturnRepository(this._auditService, this.businessId);

  /// Reads the customer's current debt balance and computes the real
  /// new balance after applying the refund. Returns a [DebtCalculation]
  /// so the caller can display the exact before/after values.
  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Future<DebtCalculation> previewDebtReduction(
    String customerId,
    double refundAmount,
  ) async {
    final isWalkIn = customerId.startsWith('walk-in-');
    if (isWalkIn || refundAmount <= 0) {
      return const DebtCalculation(
        debtBefore: 0,
        debtAfter: 0,
        actualDeduction: 0,
      );
    }

    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (!doc.exists || doc.data()?['businessId'] != businessId) {
      return const DebtCalculation(
        debtBefore: 0,
        debtAfter: 0,
        actualDeduction: 0,
      );
    }

    final currentDebt = (doc.data()?['debtBalance'] as num?)?.toDouble() ?? 0.0;

    // We always issue full store credit for returns, bringing debt negative if needed.
    final deduction = refundAmount;
    final newDebt = currentDebt - deduction;

    return DebtCalculation(
      debtBefore: currentDebt,
      debtAfter: newDebt,
      actualDeduction: deduction,
    );
  }

  /// Saves the return + items, restores stock, and reduces customer debt
  /// by the exact computed amount (never below 0).
  Future<void> createReturn(
    ReturnEntity returnRecord,
    List<ReturnItemEntity> items,
    DebtCalculation debtCalc,
    Map<String, double> orderItemReturns,
  ) async {
    _checkBusinessId();
    final isWalkIn = returnRecord.customerId.startsWith('walk-in-');

    double finalDebtBefore = debtCalc.debtBefore;
    double finalDebtAfter = debtCalc.debtAfter;

    await _firestore.runTransaction((tx) async {
      // 1. Recalculate debt securely inside transaction
      if (!isWalkIn && debtCalc.actualDeduction > 0) {
        final custRef = _firestore.collection('customers').doc(returnRecord.customerId);
        final custDoc = await tx.get(custRef);
        if (custDoc.exists) {
          final currentDebt = (custDoc.data()?['debtBalance'] as num?)?.toDouble() ?? 0.0;
          finalDebtBefore = currentDebt;
          finalDebtAfter = currentDebt - debtCalc.actualDeduction;
          
          tx.update(custRef, {
            'debtBalance': FieldValue.increment(-debtCalc.actualDeduction),
          });
        }
      }

      // 2. Save the return header
      final returnRef = _firestore.collection('returns').doc(returnRecord.id);
      final returnJson = returnRecord.toJson();
      returnJson['businessId'] = businessId; // Force businessId
      tx.set(returnRef, {
        ...returnJson,
        'debtBefore': finalDebtBefore,
        'debtAfter': finalDebtAfter,
        'actualDeduction': debtCalc.actualDeduction,
      });

      // 3. Save each return line item.
      for (final item in items) {
        final itemRef = _firestore.collection('return_items').doc(item.id);
        final itemJson = item.toJson();
        itemJson['businessId'] = businessId; // Force it
        tx.set(itemRef, itemJson);
      }

      // 4. Update the original order's return tracking fields
      final orderRef = _firestore.collection('orders').doc(returnRecord.orderId);
      final orderDoc = await tx.get(orderRef);
      if (orderDoc.exists) {
        tx.update(orderRef, {
          'hasReturn': true,
          'totalReturnedAmount': FieldValue.increment(returnRecord.totalRefund),
        });

        // 5. Update the specific order items' returned quantities
        for (final entry in orderItemReturns.entries) {
          if (entry.value > 0) {
            final orderItemRef = _firestore.collection('order_items').doc(entry.key);
            final oiDoc = await tx.get(orderItemRef);
            if (oiDoc.exists) {
              tx.update(orderItemRef, {
                'returnedQuantity': FieldValue.increment(entry.value),
              });
            }
          }
        }
      }

      // 6. Restore stock for each returned item
      for (final item in items) {
        if (item.returnedQty <= 0) continue;
        final prodRef = _firestore.collection('products').doc(item.productId);
        final prodDoc = await tx.get(prodRef);
        if (prodDoc.exists) {
          tx.update(prodRef, {
            'stockQuantity': FieldValue.increment(item.returnedQty),
          });
        }
      }
    });

    // 5. Write a detailed audit log entry.
    await _auditService.logAction(
      action: 'RETURN_PROCESSED',
      entityType: 'Return',
      entityId: returnRecord.id,
      details:
          'Return for Order #${returnRecord.orderId.substring(0, 8).toUpperCase()}. '
          'Refund value: ${returnRecord.totalRefund.toStringAsFixed(0)} IQD. '
          'Debt: ${finalDebtBefore.toStringAsFixed(0)} → ${finalDebtAfter.toStringAsFixed(0)} IQD '
          '(deducted ${debtCalc.actualDeduction.toStringAsFixed(0)} IQD). '
          '${items.length} item(s) returned.',
      metadata: {
        'orderId': returnRecord.orderId,
        'customerId': returnRecord.customerId,
        'totalRefund': returnRecord.totalRefund,
        'debtBefore': finalDebtBefore,
        'debtAfter': finalDebtAfter,
        'actualDeduction': debtCalc.actualDeduction,
        'itemsReturned': items.length,
      },
    );
  }

  /// Returns all returns for a given order.
  Future<List<ReturnEntity>> getReturnsForOrder(String orderId) async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('returns')
        .where('businessId', isEqualTo: businessId)
        .where('orderId', isEqualTo: orderId)
        .get();
    final list = snapshot.docs
        .map((doc) => ReturnEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
    return list;
  }

  /// Returns all line items for a given return.
  Future<List<ReturnItemEntity>> getReturnItems(String returnId) async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('return_items')
        .where('businessId', isEqualTo: businessId)
        .where('returnId', isEqualTo: returnId)
        .get();
    return snapshot.docs
        .map((doc) => ReturnItemEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Returns all returns
  Future<List<ReturnEntity>> getAllReturns() async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('returns')
        .where('businessId', isEqualTo: businessId)
        .orderBy('returnDate', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ReturnEntity.fromJson(data);
    }).toList();
  }

  Future<List<ReturnEntity>> getReturnsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('returns')
        .where('businessId', isEqualTo: businessId)
        .where('returnDate', isGreaterThanOrEqualTo: start)
        .where('returnDate', isLessThanOrEqualTo: end)
        .orderBy('returnDate', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ReturnEntity.fromJson(data);
    }).toList();
  }
}
