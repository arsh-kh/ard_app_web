/// Extensions on [String] for common operations.
extension StringExtension on String {
  /// Capitalizes the first letter.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes each word.
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  /// Truncates the string to maxLength and adds ellipsis.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Returns true if the string contains only digits.
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Returns true if the string is a valid email.
  bool get isEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);

  /// Returns true if the string is a valid phone number.
  bool get isPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Converts a string to double, returning 0 if invalid.
  double get toDoubleOrZero => double.tryParse(replaceAll(',', '')) ?? 0;

  /// Converts a string to int, returning 0 if invalid.
  int get toIntOrZero => int.tryParse(replaceAll(',', '')) ?? 0;

  /// Returns the string with only digits.
  String get digitsOnly => replaceAll(RegExp(r'[^0-9]'), '');

  /// Returns initials from the name (max 2 characters).
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}
