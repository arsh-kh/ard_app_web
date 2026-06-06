import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/product_entity.dart';
import '../models/category_entity.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  InventoryRepository(this._auditService);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final doubleFields = ['amount', 'totalAmount', 'debtBalance', 'buyPrice', 'sellPrice', 'unitPrice', 'stockQuantity', 'quantity'];
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

  Stream<List<ProductEntity>> watchProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProductEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList());
  }

  Future<void> addProduct(ProductEntity product) async {
    await _firestore.collection('products').doc(product.id).set({
      ...product.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'ADDED',
      entityType: 'Product',
      entityId: product.id,
      details: 'Added product ${product.name}',
    );
  }

  Future<void> updateProduct(ProductEntity product) async {
    await _firestore.collection('products').doc(product.id).update({
      ...product.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'UPDATED',
      entityType: 'Product',
      entityId: product.id,
      details: 'Updated product ${product.name}',
    );
  }

  Future<void> deleteProduct(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    final name = doc.data()?['name'] ?? id;
    
    await _firestore.collection('products').doc(id).delete();
    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Product',
      entityId: id,
      details: 'Deleted product $name',
    );
  }

  Stream<List<CategoryEntity>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CategoryEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList());
  }

  Future<void> addCategory(CategoryEntity category) async {
    await _firestore.collection('categories').doc(category.id).set(category.toJson());
  }
  Stream<List<ProductEntity>> watchAllProducts() {
    return watchProducts();
  }

  Future<List<ProductEntity>> getAllProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map((doc) => ProductEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList();
  }

  Future<ProductEntity?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return ProductEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()!}));
  }

  Future<void> restockProduct(String id, double quantity) async {
    await _firestore.collection('products').doc(id).update({
      'stockQuantity': FieldValue.increment(quantity),
    });
  }
}
