import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency and number formatting utilities for Iraqi Dinar.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,##0.##', 'en_US');

  /// Formats a number as Iraqi Dinar currency.
  /// Example: 150000 → "IQD 150,000"
  static String format(double amount) {
    return '${AppConstants.currencySymbol} ${_formatter.format(amount)}';
  }

  /// Formats a number as currency without the symbol.
  /// Example: 150000 → "150,000"
  static String formatNumber(double amount) {
    return _formatter.format(amount);
  }

  /// Formats a number as currency with symbol prefix.
  /// Example: 150000 → "IQD 150,000"
  static String formatWithPrefix(double amount) {
    return '${AppConstants.currencySymbol} ${_formatter.format(amount)}';
  }

  /// Parses a formatted currency string back to double.
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  /// Formats quantity with unit.
  /// Example: 50, "bag" → "50 bags"
  static String formatQuantity(double quantity, String unitType) {
    final formattedQty = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
    return '$formattedQty $unitType';
  }

  static String formatWeight(double weightInKg) {
    if (weightInKg >= 1000) {
      final tons = weightInKg / 1000;
      final formattedTons = tons.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      return '$formattedTons ton';
    }
    final formattedKg = weightInKg.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$formattedKg kg';
  }

  /// Formats a compact number for dashboard stats.
  /// Example: 1500000 → "1.5M"
  static String formatCompact(double amount) {
    bool isArabic = AppConstants.currencySymbol == 'د.ع';
    bool isKurdish = AppConstants.currencySymbol == 'دینار';
    
    String mStr = isArabic ? ' مليون' : isKurdish ? ' ملیۆن' : 'M';
    String bStr = isArabic ? ' مليار' : isKurdish ? ' ملیار' : 'B';
    String kStr = isArabic ? ' ألف' : isKurdish ? ' هەزار' : 'K';

    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$bStr';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$mStr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$kStr';
    }
    return amount.toInt().toString();
  }
}

