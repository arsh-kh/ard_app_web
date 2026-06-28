class AppValidators {
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    // Min 8 chars, 1 uppercase, 1 lowercase, 1 number
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$');
    return regex.hasMatch(password);
  }

  static bool isValidPhone(String phone) {
    // Basic international or local phone number format
    // E.g. +9647501234567 or 07501234567
    final regex = RegExp(
      r'^(\+?\d{1,4}?[\s-]?)?\(?\d{1,4}?\)?[\s-]?\d{1,4}[\s-]?\d{1,4}[\s-]?\d{1,9}$',
    );
    return regex.hasMatch(phone);
  }
}
