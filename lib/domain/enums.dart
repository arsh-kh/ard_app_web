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

/// Global sorting options for UI screens.
enum SortOptionType {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  stockAsc,
  stockDesc,
  debtDesc,
  debtAsc,
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}
