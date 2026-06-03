/// Synchronization status for offline-first architecture.
/// NOTE: Must match the canonical enum in data/local_database/tables.dart
/// since Drift uses EnumIndexConverter (ordinal position matters).
enum SyncStatus {
  synced,
  pendingSync,
  syncing,
  failed;

  String get value => name;

  static SyncStatus fromValue(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pendingSync,
    );
  }
}

/// Operation type for sync queue items.
enum SyncOperation {
  create,
  update,
  delete;

  String get value => name;

  static SyncOperation fromValue(String value) {
    return SyncOperation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncOperation.create,
    );
  }
}

/// User roles in the B2B platform.
enum UserRole {
  admin,
  employee,
  customer;

  String get value => name;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.customer,
    );
  }
}

/// Order lifecycle status.
enum OrderStatus {
  pending,
  delivered,
  cancelled;

  String get value => name;

  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Payment completion status.
enum PaymentStatus {
  paid,
  partial,
  unpaid;

  String get value => name;

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

/// Method used to make a payment.
enum PaymentMethod {
  cash,
  transfer,
  check;

  String get value => name;

  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Product measurement unit.
enum UnitType {
  kg,
  bag,
  ton,
  piece,
  box;

  String get value => name;

  static UnitType fromValue(String value) {
    return UnitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UnitType.piece,
    );
  }
}

/// Delivery tracking status.
enum DeliveryStatus {
  pending,
  inTransit,
  delivered;

  String get value {
    switch (this) {
      case DeliveryStatus.inTransit:
        return 'in_transit';
      default:
        return name;
    }
  }

  static DeliveryStatus fromValue(String value) {
    if (value == 'in_transit') return DeliveryStatus.inTransit;
    return DeliveryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryStatus.pending,
    );
  }
}
