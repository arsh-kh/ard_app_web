import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/purchase_return_entity.dart';
import '../models/purchase_return_item_entity.dart';
import 'return_repository.dart'; // for DebtCalculation

class PurchaseReturnRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  PurchaseReturnRepository(this._auditService, this.businessId);

  /// Previews how much the supplier debt will be reduced by.
  /// (Since we return items to the supplier, the amount we owe them decreases).
  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Future<DebtCalculation> previewSupplierDebtReduction(
    String supplierId,
    double refundAmount,
  ) async {
    if (refundAmount <= 0) {
      return const DebtCalculation(
        debtBefore: 0,
        debtAfter: 0,
        actualDeduction: 0,
      );
    }

    final doc = await _firestore.collection('suppliers').doc(supplierId).get();
    final currentDebt = (doc.data()?['debtBalance'] as num?)?.toDouble() ?? 0.0;

    final deduction = refundAmount;
    final newDebt = currentDebt - deduction;

    return DebtCalculation(
      debtBefore: currentDebt,
      debtAfter: newDebt,
      actualDeduction: deduction,
    );
  }

  Future<void> createPurchaseReturn(
    PurchaseReturnEntity returnRecord,
    List<PurchaseReturnItemEntity> items,
    DebtCalculation debtCalc,
    Map<String, double> purchaseItemReturns,
  ) async {
    _checkBusinessId();
    double finalDebtBefore = debtCalc.debtBefore;
    double finalDebtAfter = debtCalc.debtAfter;

    await _firestore.runTransaction((tx) async {
      // 1. Recalculate debt securely inside transaction
      if (debtCalc.actualDeduction > 0) {
        final supplierRef = _firestore.collection('suppliers').doc(returnRecord.supplierId);
        final supplierDoc = await tx.get(supplierRef);
        if (supplierDoc.exists) {
          final currentDebt = (supplierDoc.data()?['debtBalance'] as num?)?.toDouble() ?? 0.0;
          finalDebtBefore = currentDebt;
          finalDebtAfter = currentDebt - debtCalc.actualDeduction;
          
          tx.update(supplierRef, {
            'debtBalance': FieldValue.increment(-debtCalc.actualDeduction),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 2. Save the return header
      final returnRef = _firestore.collection('purchase_returns').doc(returnRecord.id);
      final returnJson = returnRecord.toJson();
      returnJson['businessId'] = businessId; // Enforce businessId
      tx.set(returnRef, {
        ...returnJson,
        'debtBefore': finalDebtBefore,
        'debtAfter': finalDebtAfter,
        'actualDeduction': debtCalc.actualDeduction,
      });

      // 3. Save each return line item
      for (final item in items) {
        final itemRef = _firestore.collection('purchase_return_items').doc(item.id);
        final itemJson = item.toJson();
        itemJson['businessId'] = businessId; // Enforce businessId
        tx.set(itemRef, itemJson);
      }

      // 4. Update the original purchase's return tracking fields
      final purchaseRef = _firestore.collection('purchases').doc(returnRecord.purchaseId);
      final purchaseDoc = await tx.get(purchaseRef);
      if (purchaseDoc.exists) {
        tx.update(purchaseRef, {
          'hasReturn': true,
          'totalReturnedAmount': FieldValue.increment(returnRecord.totalRefund),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 5. Update the specific purchase items' returned quantities
        for (final entry in purchaseItemReturns.entries) {
          if (entry.value > 0) {
            final piRef = _firestore.collection('purchaseItems').doc(entry.key);
            final piDoc = await tx.get(piRef);
            if (piDoc.exists) {
              tx.update(piRef, {
                'returnedQuantity': FieldValue.increment(entry.value),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      // 6. Reduce stock for each returned item (inside batch)
      for (final item in items) {
        if (item.returnedQty <= 0) continue;
        final prodRef = _firestore.collection('products').doc(item.productId);
        final prodDoc = await tx.get(prodRef);
        if (prodDoc.exists) {
          tx.update(prodRef, {
            // Important: DECREMENT stock because we are giving it back to the supplier
            'stockQuantity': FieldValue.increment(-item.returnedQty),
          });
        }
      }
    });

    // 7. Audit log
    await _auditService.logAction(
      action: 'PURCHASE_RETURN_PROCESSED',
      entityType: 'PurchaseReturn',
      entityId: returnRecord.id,
      details:
          'Return for Purchase #${returnRecord.purchaseId.substring(0, 8).toUpperCase()}. '
          'Refund value: ${returnRecord.totalRefund.toStringAsFixed(0)}. '
          'Supplier Debt: ${finalDebtBefore.toStringAsFixed(0)} → ${finalDebtAfter.toStringAsFixed(0)} '
          '(deducted ${debtCalc.actualDeduction.toStringAsFixed(0)}). '
          '${items.length} item(s) returned.',
      metadata: {
        'purchaseId': returnRecord.purchaseId,
        'supplierId': returnRecord.supplierId,
        'totalRefund': returnRecord.totalRefund,
        'debtBefore': finalDebtBefore,
        'debtAfter': finalDebtAfter,
        'actualDeduction': debtCalc.actualDeduction,
        'itemsReturned': items.length,
      },
    );
  }

  Future<List<PurchaseReturnEntity>> getReturnsForPurchase(
    String purchaseId,
  ) async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('purchase_returns')
        .where('businessId', isEqualTo: businessId)
        .where('purchaseId', isEqualTo: purchaseId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => PurchaseReturnEntity.fromJson({'id': doc.id, ...doc.data()}),
        )
        .toList();
    list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
    return list;
  }
}
