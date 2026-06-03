/// Form validation utilities for the ئارد app.
class Validators {
  Validators._();

  /// Validates that a field is not empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password (minimum 6 characters).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates phone number (Iraqi format).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates a positive number.
  static String? positiveNumber(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return 'Enter a valid number';
    }
    if (number < 0) {
      return '$fieldName must be positive';
    }
    return null;
  }

  /// Validates a positive number greater than zero.
  static String? positiveNonZero(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return 'Enter a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  /// Validates that quantity doesn't exceed available stock.
  static String? maxQuantity(String? value, double maxStock, [String fieldName = 'Quantity']) {
    final baseValidation = positiveNonZero(value, fieldName);
    if (baseValidation != null) return baseValidation;

    final number = double.tryParse(value!.replaceAll(',', ''));
    if (number != null && number > maxStock) {
      return 'Only ${maxStock.toStringAsFixed(0)} available in stock';
    }
    return null;
  }

  /// Validates that a price is valid (non-negative number).
  static String? price(String? value, [String fieldName = 'Price']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return 'Enter a valid price';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }
}
