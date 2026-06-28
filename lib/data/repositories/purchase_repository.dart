import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_entity.dart';
import '../models/purchase_item_entity.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/sequence_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class PurchaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String businessId;

  PurchaseRepository(this.businessId);

  CollectionReference get _purchases => _firestore.collection('purchases');
  CollectionReference get _purchaseItems =>
      _firestore.collection('purchaseItems');

  Future<void> createPurchase(
    PurchaseEntity purchase,
    List<PurchaseItemEntity> items,
  ) async {
    final batch = _firestore.batch();

    // Generate strict sequence number for purchase
    final purchaseNum = await SequenceService.getNextSequence(
      'purchases',
      businessId: businessId,
    );
    final finalPurchase = purchase.copyWith(
      purchaseNumber: purchaseNum,
      businessId: businessId,
    );

    // 1. Create Purchase
    final purchaseRef = _purchases.doc(finalPurchase.id);
    batch.set(purchaseRef, finalPurchase.toJson());

    // 2. Create Items & Update Stock
    for (var item in items) {
      // If status is received, immediately increment stock
      if (finalPurchase.status == 'received') {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        final prodDoc = await productRef.get();
        if (prodDoc.exists) {
          final data = prodDoc.data() as Map<String, dynamic>;
          final double oldPrice = ((data['buyPrice'] as num?) ?? 0).toDouble();
          final double newQty = item.quantity;
          final double newPrice = item.unitPrice;

          if (oldPrice > 0 && oldPrice != newPrice) {
            // Split into a new product
            final newProductId = const Uuid().v4();
            final newProductData = Map<String, dynamic>.from(data);
            newProductData['id'] = newProductId;
            final formatter = NumberFormat('#,###');
            newProductData['name'] =
                '${data['name']} (${formatter.format(newPrice)})';
            newProductData['buyPrice'] = newPrice;
            newProductData['stockQuantity'] = newQty;

            // Create new product
            batch.set(
              _firestore.collection('products').doc(newProductId),
              newProductData,
            );

            // Update item to point to the new product
            item = item.copyWith(productId: newProductId);
          } else {
            // Normal increment
            batch.update(productRef, {
              'stockQuantity': FieldValue.increment(item.quantity),
            });
          }
        }
      }

      // Save item (with updated productId if it was split)
      final finalItem = item.copyWith(businessId: businessId);
      final itemRef = _purchaseItems.doc(item.id);
      batch.set(itemRef, finalItem.toJson());
    }

    // 3. Update Supplier Debt (we owe them more money)
    if (finalPurchase.status == 'received') {
      final supplierRef = _firestore
          .collection('suppliers')
          .doc(finalPurchase.supplierId);
      final supplierDoc = await supplierRef.get();
      if (supplierDoc.exists) {
        batch.update(supplierRef, {
          'debtBalance': FieldValue.increment(finalPurchase.totalAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<List<PurchaseEntity>> getAllPurchases() async {
    final snapshot = await _purchases
        .where('businessId', isEqualTo: businessId)
        .orderBy('purchaseDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => PurchaseEntity.fromJson(
            DataSanitizer.sanitize({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          ),
        )
        .toList();
  }

  Stream<List<PurchaseEntity>> watchAllPurchases() {
    return _purchases
        .where('businessId', isEqualTo: businessId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PurchaseEntity.fromJson(
                  DataSanitizer.sanitize({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }),
                ),
              )
              .toList(),
        );
  }

  Future<List<PurchaseItemEntity>> getPurchaseItems(String purchaseId) async {
    final snapshot = await _purchaseItems
        .where('businessId', isEqualTo: businessId)
        .where('purchaseId', isEqualTo: purchaseId)
        .get();
    return snapshot.docs
        .map(
          (doc) => PurchaseItemEntity.fromJson(
            DataSanitizer.sanitize({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          ),
        )
        .toList();
  }

  Future<List<PurchaseItemEntity>> getAllPurchaseItems() async {
    final snapshot = await _purchaseItems
        .where('businessId', isEqualTo: businessId)
        .get();
    return snapshot.docs
        .map(
          (doc) => PurchaseItemEntity.fromJson(
            DataSanitizer.sanitize({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          ),
        )
        .toList();
  }

  Future<List<PurchaseEntity>> getPurchasesBySupplier(String supplierId) async {
    final snapshot = await _purchases
        .where('businessId', isEqualTo: businessId)
        .where('supplierId', isEqualTo: supplierId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => PurchaseEntity.fromJson(
            DataSanitizer.sanitize({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          ),
        )
        .toList();
    list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return list;
  }

  Stream<List<PurchaseEntity>> watchPurchasesBySupplier(String supplierId) {
    return _purchases
        .where('businessId', isEqualTo: businessId)
        .where('supplierId', isEqualTo: supplierId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => PurchaseEntity.fromJson(
                  DataSanitizer.sanitize({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }),
                ),
              )
              .toList();
          list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
          return list;
        });
  }

  Future<void> deletePurchase(String purchaseId) async {
    final doc = await _purchases.doc(purchaseId).get();
    if (!doc.exists) return;

    final purchase = PurchaseEntity.fromJson(
      DataSanitizer.sanitize({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }),
    );
    final items = await getPurchaseItems(purchaseId);

    final batch = _firestore.batch();
    batch.delete(doc.reference);

    final itemsSnapshot = await _purchaseItems
        .where('businessId', isEqualTo: businessId)
        .where('purchaseId', isEqualTo: purchaseId)
        .get();
    for (final itemDoc in itemsSnapshot.docs) {
      batch.delete(itemDoc.reference);
    }

    // Delete orphan purchase returns and items
    final returnsSnapshot = await _firestore
        .collection('purchase_returns')
        .where('businessId', isEqualTo: businessId)
        .where('purchaseId', isEqualTo: purchaseId)
        .get();
    for (final rDoc in returnsSnapshot.docs) {
      batch.delete(rDoc.reference);
      final returnItemsSnapshot = await _firestore
          .collection('purchase_return_items')
          .where('businessId', isEqualTo: businessId)
          .where('returnId', isEqualTo: rDoc.id)
          .get();
      for (final riDoc in returnItemsSnapshot.docs) {
        batch.delete(riDoc.reference);
      }
    }

    if (purchase.status == 'received') {
      // Revert Stock
      for (final item in items) {
        final prodRef = _firestore.collection('products').doc(item.productId);
        final prodDoc = await prodRef.get();
        if (prodDoc.exists) {
          final netQuantityRevert = item.quantity - item.returnedQuantity;
          if (netQuantityRevert > 0) {
            batch.update(prodRef, {
              'stockQuantity': FieldValue.increment(-netQuantityRevert),
            });
          }
        }
      }

      // Calculate net debt revert
      double totalDeductedByReturns = 0.0;
      for (final rDoc in returnsSnapshot.docs) {
        totalDeductedByReturns +=
            (rDoc.data()['actualDeduction'] as num?)?.toDouble() ?? 0.0;
      }
      final netDebtRevert = purchase.totalAmount - totalDeductedByReturns;

      // Revert Supplier Debt
      if (netDebtRevert > 0) {
        final supplierRef = _firestore
            .collection('suppliers')
            .doc(purchase.supplierId);
        final supplierDoc = await supplierRef.get();
        if (supplierDoc.exists) {
          batch.update(supplierRef, {
            'debtBalance': FieldValue.increment(-netDebtRevert),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();
  }
}
