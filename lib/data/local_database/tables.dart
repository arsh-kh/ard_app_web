import 'package:drift/drift.dart';

// Sync Status Enum for the Sync Engine
enum SyncStatus {
  synced,       // 0
  pendingSync,  // 1
  syncing,      // 2
  failed        // 3
}

mixin SyncMetadata on Table {
  TextColumn get id => text()(); // UUID string
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(1))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('UserEntity')
class Users extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};
  
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()(); // 'admin', 'employee', 'bakery'
  TextColumn get name => text()();
}

@DataClassName('ProductEntity')
class Products extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  TextColumn get unitType => text()(); // 'bag', 'kg', 'ton', 'box'
  RealColumn get buyPrice => real()();
  RealColumn get sellPrice => real()();
  TextColumn get barcode => text().nullable()();
}

@DataClassName('CategoryEntity')
class Categories extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text()();
}

@DataClassName('CustomerEntity')
class Customers extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get userId => text().nullable()(); // Linked to User account if bakery
  TextColumn get businessName => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get debtBalance => real().withDefault(const Constant(0.0))();
}

@DataClassName('OrderEntity')
class Orders extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get customerId => text()();
  TextColumn get status => text()(); // 'pending', 'approved', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'
  RealColumn get totalAmount => real()();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('OrderItemEntity')
class OrderItems extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
}

@DataClassName('PaymentEntity')
class Payments extends Table with SyncMetadata {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get customerId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
}
