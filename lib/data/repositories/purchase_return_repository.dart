import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/purchase_return_entity.dart';
import '../models/purchase_return_item_entity.dart';
import '../../core/utils/data_sanitizer.dart';

class PurchaseReturnRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  PurchaseReturnRepository(this._auditService, this.businessId);


  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Future<void> createPurchaseReturn(
    PurchaseReturnEntity returnRecord,
    List<PurchaseReturnItemEntity> items,
    Map<String, double> purchaseItemReturns,
  ) async {
    _checkBusinessId();

    await _firestore.runTransaction((tx) async {
      // --- READ PHASE ---
      final purchaseRef = _firestore.collection('purchases').doc(returnRecord.purchaseId);
      final purchaseDoc = await tx.get(purchaseRef);

      final Map<String, DocumentSnapshot> piDocs = {};
      for (final entry in purchaseItemReturns.entries) {
        if (entry.value > 0) {
          final piRef = _firestore.collection('purchaseItems').doc(entry.key);
          piDocs[entry.key] = await tx.get(piRef);
        }
      }

      final Map<String, DocumentSnapshot> prodDocs = {};
      for (final item in items) {
        if (item.returnedQty <= 0) continue;
        final prodRef = _firestore.collection('products').doc(item.productId);
        prodDocs[item.productId] = await tx.get(prodRef);
      }

      // --- WRITE PHASE ---
      // 2. Save the return header
      final returnRef = _firestore.collection('purchase_returns').doc(returnRecord.id);
      final returnJson = returnRecord.toJson();
      returnJson['businessId'] = businessId; // Enforce businessId
      tx.set(returnRef, returnJson);

      // 3. Save each return line item
      for (final item in items) {
        final itemRef = _firestore.collection('purchase_return_items').doc(item.id);
        final itemJson = item.toJson();
        itemJson['businessId'] = businessId; // Enforce businessId
        tx.set(itemRef, itemJson);
      }

      // 4. Update the original purchase's return tracking fields
      if (purchaseDoc.exists) {
        tx.update(purchaseRef, {
          'hasReturn': true,
          'totalReturnedAmount': FieldValue.increment(returnRecord.totalRefund),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 5. Update the specific purchase items' returned quantities
        for (final entry in purchaseItemReturns.entries) {
          if (entry.value > 0 && piDocs[entry.key]?.exists == true) {
            final piRef = _firestore.collection('purchaseItems').doc(entry.key);
            tx.update(piRef, {
              'returnedQuantity': FieldValue.increment(entry.value),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // 6. Reduce stock for each returned item (inside batch)
      for (final item in items) {
        if (item.returnedQty <= 0) continue;
        if (prodDocs[item.productId]?.exists == true) {
          final prodRef = _firestore.collection('products').doc(item.productId);
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
          '${items.length} item(s) returned.',
      metadata: {
        'purchaseId': returnRecord.purchaseId,
        'supplierId': returnRecord.supplierId,
        'totalRefund': returnRecord.totalRefund,
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
          (doc) => PurchaseReturnEntity.fromJson(DataSanitizer.sanitize({'id': doc.id, ...doc.data()})),
        )
        .toList();
    list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
    return list;
  }
}
