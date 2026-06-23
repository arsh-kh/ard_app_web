import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) != 0) {
      final int selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.end;

      // Clean string
      final String cleanText = newValue.text.replaceAll(',', '');

      // Handle decimals
      final parts = cleanText.split('.');
      String integerPart = parts[0];
      final String decimalPart = parts.length > 1
          ? '.${parts.sublist(1).join('')}'
          : '';

      // Default to 0 if starting with a decimal point
      if (integerPart.isEmpty && cleanText.startsWith('.')) {
        integerPart = '0';
      }

      // Formatting
      final number = int.tryParse(integerPart);
      if (number != null) {
        final f = NumberFormat('#,###');
        final newString = f.format(number) + decimalPart;

        int newSelection = newString.length - selectionIndexFromTheRight;
        if (newSelection < 0) newSelection = 0;
        if (newSelection > newString.length) newSelection = newString.length;

        return TextEditingValue(
          text: newString,
          selection: TextSelection.collapsed(offset: newSelection),
        );
      }
    }
    return newValue;
  }
}

class ArabicToEnglishFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    String newText = newValue.text;
    for (int i = 0; i < 10; i++) {
      newText = newText.replaceAll(arabic[i], english[i]);
      newText = newText.replaceAll(persian[i], english[i]);
    }

    // Convert Arabic decimal separator to standard dot
    newText = newText.replaceAll('٫', '.');

    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 11) return oldValue;

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 4 || i == 7) formatted += ' ';
      formatted += digitsOnly[i];
    }

    int cursorPosition = formatted.length;
    if (newValue.selection.end < newValue.text.length) {
      final int digitsBeforeCursor = newValue.text
          .substring(0, newValue.selection.end)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      cursorPosition = digitsBeforeCursor;
      if (digitsBeforeCursor > 4) cursorPosition++;
      if (digitsBeforeCursor > 7) cursorPosition++;
      if (cursorPosition > formatted.length) cursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
