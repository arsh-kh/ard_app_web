import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

class InventoryRepositoryImpl  {
  final AppDatabase _db;

  InventoryRepositoryImpl(this._db);

  
  Stream<List<ProductEntity>> watchAllProducts() {
    return (_db.select(_db.products)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  
  Future<List<ProductEntity>> getAllProducts() {
    return (_db.select(_db.products)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  
  Stream<ProductEntity?> watchProduct(String id) {
    return (_db.select(_db.products)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  
  Future<ProductEntity?> getProduct(String id) {
    return (_db.select(_db.products)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  
  Future<void> addProduct(ProductsCompanion product) async {
    await _db.into(_db.products).insert(product);
  }

  
  Future<void> updateProduct(ProductsCompanion product) async {
    await _db.update(_db.products).replace(product);
  }

  
  Future<void> deleteProduct(String id) async {
    // Soft delete
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      const ProductsCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pendingSync), // needs sync to cloud
      ),
    );
  }

  
  Stream<List<CategoryEntity>> watchAllCategories() {
    return (_db.select(_db.categories)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  
  Future<void> addCategory(CategoriesCompanion category) async {
    await _db.into(_db.categories).insert(category);
  }

  
  Future<void> deleteCategory(String id) async {
    // Soft delete
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      const CategoriesCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pendingSync),
      ),
    );
  }
}
