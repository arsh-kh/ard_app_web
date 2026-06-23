import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency and number formatting utilities for Iraqi Dinar.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,##0.##', 'en_US');

  /// Formats a number as Iraqi Dinar currency.
  /// Example: 150000 → "IQD 150,000"
  static String format(double amount) {
    return '\u202A${_formatter.format(amount)} ${AppConstants.currencySymbol}\u202C';
  }

  /// Formats a number as currency without the symbol.
  /// Example: 150000 → "150,000"
  static String formatNumber(double amount) {
    return '\u202A${_formatter.format(amount)}\u202C';
  }

  /// Formats a number as currency with symbol prefix.
  /// Example: 150000 → "IQD 150,000"
  static String formatWithPrefix(double amount) {
    return '\u202A${_formatter.format(amount)} ${AppConstants.currencySymbol}\u202C';
  }

  /// Parses a formatted currency string back to double.
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .replaceAll('\u202A', '')
        .replaceAll('\u202C', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  /// Formats quantity with unit.
  /// Example: 50, "bag" → "50 bags"
  static String formatQuantity(double quantity, String unitType) {
    final formattedQty = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);

    String finalUnit = unitType;
    if (AppConstants.languageCode == 'en' && quantity != 1.0) {
      final lowerUnit = unitType.toLowerCase();
      if (lowerUnit == 'box') {
        finalUnit = '${unitType}es';
      } else if (!lowerUnit.endsWith('s') &&
          lowerUnit != 'kg' &&
          lowerUnit != 'ton') {
        finalUnit = '${unitType}s';
      }
    }

    return '$formattedQty $finalUnit';
  }

  static String formatWeight(double weightInKg) {
    if (weightInKg >= 1000) {
      final tons = weightInKg / 1000;
      final formattedTons = tons
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      return '$formattedTons ton';
    }
    final formattedKg = weightInKg
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '$formattedKg kg';
  }

  /// Formats a compact number for dashboard stats.
  /// Example: 1500000 → "1.5M"
  static String formatCompact(double amount) {
    final bool isArabic = AppConstants.languageCode == 'ar';
    final bool isKurdish = AppConstants.languageCode == 'ku';

    final String mStr = isArabic
        ? ' مليون'
        : isKurdish
        ? ' ملیۆن'
        : 'M';
    final String bStr = isArabic
        ? ' مليار'
        : isKurdish
        ? ' ملیار'
        : 'B';
    final String kStr = isArabic
        ? ' ألف'
        : isKurdish
        ? ' هەزار'
        : 'K';

    final bool isNegative = amount < 0;
    final double absAmount = amount.abs();

    String result;
    if (absAmount >= 1000000000) {
      result =
          '${(absAmount / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$bStr';
    } else if (absAmount >= 1000000) {
      result =
          '${(absAmount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$mStr';
    } else if (absAmount >= 1000) {
      result =
          '${(absAmount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$kStr';
    } else {
      result = absAmount.toInt().toString();
    }

    if (isNegative) {
      result = '-$result';
    }

    return '\u202A$result\u202C';
  }
}
