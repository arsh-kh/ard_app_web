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
