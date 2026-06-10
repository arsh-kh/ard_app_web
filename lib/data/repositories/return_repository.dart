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

  ReturnRepository(this._auditService);

  /// Reads the customer's current debt balance and computes the real
  /// new balance after applying the refund. Returns a [DebtCalculation]
  /// so the caller can display the exact before/after values.
  Future<DebtCalculation> previewDebtReduction(
      String customerId, double refundAmount) async {
    final isWalkIn =
        customerId == 'walk-in' || customerId == 'walk-in-customer-id';
    if (isWalkIn || refundAmount <= 0) {
      return const DebtCalculation(
          debtBefore: 0, debtAfter: 0, actualDeduction: 0);
    }

    final doc =
        await _firestore.collection('customers').doc(customerId).get();
    final currentDebt =
        (doc.data()?['debtBalance'] as num?)?.toDouble() ?? 0.0;
    // Can only deduct what the customer actually owes.
    final deduction = refundAmount > currentDebt ? currentDebt : refundAmount;
    final newDebt = (currentDebt - deduction).clamp(0.0, double.infinity);

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
    final batch = _firestore.batch();

    // 1. Save the return header (store actual deduction for the audit trail).
    final returnRef =
        _firestore.collection('returns').doc(returnRecord.id);
    batch.set(returnRef, {
      ...returnRecord.toJson(),
      'debtBefore': debtCalc.debtBefore,
      'debtAfter': debtCalc.debtAfter,
      'actualDeduction': debtCalc.actualDeduction,
    });

    // 2. Save each return line item.
    for (final item in items) {
      final itemRef = _firestore.collection('return_items').doc(item.id);
      batch.set(itemRef, item.toJson());
    }

    // 3. Set the EXACT new debt balance (floored at 0, never negative).
    final isWalkIn = returnRecord.customerId == 'walk-in' ||
        returnRecord.customerId == 'walk-in-customer-id';
    if (!isWalkIn && debtCalc.actualDeduction > 0) {
      final custRef =
          _firestore.collection('customers').doc(returnRecord.customerId);
      batch.update(custRef, {'debtBalance': debtCalc.debtAfter});
    }

    // 4. Update the original order's return tracking fields
    final orderRef = _firestore.collection('orders').doc(returnRecord.orderId);
    batch.update(orderRef, {
      'hasReturn': true,
      'totalReturnedAmount': FieldValue.increment(returnRecord.totalRefund),
    });

    // 5. Update the specific order items' returned quantities
    orderItemReturns.forEach((orderItemId, qty) {
      if (qty > 0) {
        final orderItemRef = _firestore.collection('order_items').doc(orderItemId);
        batch.update(orderItemRef, {
          'returnedQuantity': FieldValue.increment(qty),
        });
      }
    });

    await batch.commit();

    // 4. Restore stock for each returned item (outside batch to allow guards).
    for (final item in items) {
      if (item.returnedQty <= 0) continue;
      try {
        final prodDoc = await _firestore
            .collection('products')
            .doc(item.productId)
            .get();
        if (prodDoc.exists) {
          await _firestore
              .collection('products')
              .doc(item.productId)
              .update(
                  {'stockQuantity': FieldValue.increment(item.returnedQty)});
        }
      } catch (_) {
        // Product was deleted — skip stock restore for this item.
      }
    }

    // 5. Write a detailed audit log entry.
    await _auditService.logAction(
      action: 'RETURN_PROCESSED',
      entityType: 'Return',
      entityId: returnRecord.id,
      details:
          'Return for Order #${returnRecord.orderId.substring(0, 8).toUpperCase()}. '
          'Refund value: ${returnRecord.totalRefund.toStringAsFixed(0)} IQD. '
          'Debt: ${debtCalc.debtBefore.toStringAsFixed(0)} → ${debtCalc.debtAfter.toStringAsFixed(0)} IQD '
          '(deducted ${debtCalc.actualDeduction.toStringAsFixed(0)} IQD). '
          '${items.length} item(s) returned.',
    );
  }

  /// Returns all returns for a given order.
  Future<List<ReturnEntity>> getReturnsForOrder(String orderId) async {
    final snapshot = await _firestore
        .collection('returns')
        .where('orderId', isEqualTo: orderId)
        .orderBy('returnDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) =>
            ReturnEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Returns all line items for a given return.
  Future<List<ReturnItemEntity>> getReturnItems(String returnId) async {
    final snapshot = await _firestore
        .collection('return_items')
        .where('returnId', isEqualTo: returnId)
        .get();
    return snapshot.docs
        .map((doc) =>
            ReturnItemEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Returns all returns
  Future<List<ReturnEntity>> getAllReturns() async {
    final snapshot = await _firestore.collection('returns').get();
    return snapshot.docs
        .map((doc) => ReturnEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }
}
