import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/product_entity.dart';
import '../models/category_entity.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  InventoryRepository(this._auditService);

  Stream<List<ProductEntity>> watchProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProductEntity.fromJson({'id': doc.id, ...doc.data()})).toList());
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
        snapshot.docs.map((doc) => CategoryEntity.fromJson({'id': doc.id, ...doc.data()})).toList());
  }

  Future<void> addCategory(CategoryEntity category) async {
    await _firestore.collection('categories').doc(category.id).set(category.toJson());
  }
  Stream<List<ProductEntity>> watchAllProducts() {
    return watchProducts();
  }

  Future<List<ProductEntity>> getAllProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map((doc) => ProductEntity.fromJson({'id': doc.id, ...doc.data()})).toList();
  }

  Future<ProductEntity?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return ProductEntity.fromJson({'id': doc.id, ...doc.data()!});
  }

  Future<void> restockProduct(String id, double quantity) async {
    await _firestore.collection('products').doc(id).update({
      'stockQuantity': FieldValue.increment(quantity),
    });
  }
}
