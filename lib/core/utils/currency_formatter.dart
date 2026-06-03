import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency and number formatting utilities for Iraqi Dinar.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  /// Formats a number as Iraqi Dinar currency.
  /// Example: 150000 → "150,000 د.ع"
  static String format(double amount) {
    return '${_formatter.format(amount.round())} ${AppConstants.currencySymbol}';
  }

  /// Formats a number as currency without the symbol.
  /// Example: 150000 → "150,000"
  static String formatNumber(double amount) {
    return _formatter.format(amount.round());
  }

  /// Formats a number as currency with symbol prefix.
  /// Example: 150000 → "د.ع 150,000"
  static String formatWithPrefix(double amount) {
    return '${AppConstants.currencySymbol} ${_formatter.format(amount.round())}';
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

  /// Formats a weight in kg with appropriate unit.
  /// Converts to tons if >= 1000 kg.
  static String formatWeight(double weightInKg) {
    if (weightInKg >= 1000) {
      final tons = weightInKg / 1000;
      return '${tons.toStringAsFixed(2)} ton';
    }
    return '${weightInKg.toStringAsFixed(weightInKg == weightInKg.roundToDouble() ? 0 : 2)} kg';
  }

  /// Formats a compact number for dashboard stats.
  /// Example: 1500000 → "1.5M"
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toInt().toString();
  }
}
