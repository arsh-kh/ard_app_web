import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/audit_service.dart';
import '../models/product_entity.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  InventoryRepository(this._auditService, this.businessId);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return DataSanitizer.sanitize(data);
  }

  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Stream<List<ProductEntity>> watchProducts() {
    if (businessId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => ProductEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList();
          list.sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
            final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
          return list;
        });
  }

  Future<void> addProduct(ProductEntity product) async {
    _checkBusinessId();
    await _firestore.collection('products').doc(product.id).set({
      ...product.toJson(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'ADDED',
      entityType: 'Product',
      entityId: product.id,
      details:
          'Added new product \'${product.name}\' with starting stock ${product.stockQuantity}',
      metadata: {
        'productName': product.name,
        'stockQuantity': product.stockQuantity,
        'buyPrice': product.buyPrice,
        'sellPrice': product.sellPrice,
      },
    );
  }

  Future<void> updateProductImageUrl(String productId, String imageUrl) async {
    _checkBusinessId();
    await _firestore.collection('products').doc(productId).update({
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(ProductEntity product) async {
    final Map<String, dynamic> data = product.toJson();
    if (product.imageUrl == null) {
      data['imageUrl'] = FieldValue.delete();
    }
    data['businessId'] = businessId;

    final oldDoc = await _firestore
        .collection('products')
        .doc(product.id)
        .get();
    final Map<String, dynamic> changes = {};
    if (oldDoc.exists && oldDoc.data() != null) {
      final oldData = oldDoc.data()!;
      if (oldData['name'] != product.name) {
        changes['name'] = {'old': oldData['name'], 'new': product.name};
      }
      if (oldData['buyPrice'] != product.buyPrice) {
        changes['buyPrice'] = {
          'old': oldData['buyPrice'],
          'new': product.buyPrice,
        };
      }
      if (oldData['sellPrice'] != product.sellPrice) {
        changes['sellPrice'] = {
          'old': oldData['sellPrice'],
          'new': product.sellPrice,
        };
      }
      if (oldData['stockQuantity'] != product.stockQuantity) {
        changes['stockQuantity'] = {
          'old': oldData['stockQuantity'],
          'new': product.stockQuantity,
        };
      }
      if (oldData['barcode'] != product.barcode) {
        changes['barcode'] = {
          'old': oldData['barcode'],
          'new': product.barcode,
        };
      }
    }

    await _firestore.collection('products').doc(product.id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'UPDATED',
      entityType: 'Product',
      entityId: product.id,
      details:
          'Modified product \'${product.name}\' (Price: ${product.sellPrice}, Stock: ${product.stockQuantity})',
      metadata: {
        'productName': product.name,
        'stockQuantity': product.stockQuantity,
        'buyPrice': product.buyPrice,
        'sellPrice': product.sellPrice,
        if (changes.isNotEmpty) 'changes': changes,
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    _checkBusinessId();
    final doc = await _firestore.collection('products').doc(id).get();
    final data = doc.data();
    if (data != null && data['businessId'] != businessId) return; // security

    final name = data?['name'] ?? id;

    await _firestore.collection('products').doc(id).delete();
    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Product',
      entityId: id,
      details: 'Deleted product \'$name\' from inventory',
      metadata: {'productName': name, 'productId': id},
    );
  }

  Stream<List<ProductEntity>> watchAllProducts() {
    if (businessId.isEmpty) return Stream.value([]);
    return watchProducts();
  }

  Future<List<ProductEntity>> getAllProducts() async {
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => ProductEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
    list.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<ProductEntity?> getProductById(String id) async {
    if (businessId.isEmpty) return null;
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['businessId'] != businessId) return null; // Security check
    return ProductEntity.fromJson(_sanitizeData({'id': doc.id, ...data}));
  }

  Future<void> restockProduct(String id, double quantity) async {
    _checkBusinessId();
    final doc = await _firestore.collection('products').doc(id).get();
    if (doc.exists && doc.data()?['businessId'] == businessId) {
      await _firestore.collection('products').doc(id).update({
        'stockQuantity': FieldValue.increment(quantity),
      });
    }
  }
}
