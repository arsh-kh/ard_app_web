import '../constants/app_constants.dart';

/// Extensions on [num] for currency and quantity formatting.
extension NumExtension on num {
  /// Formats as Iraqi Dinar currency. 150000 → "150,000 د.ع"
  String get asCurrency {
    final formatted = toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$formatted ${AppConstants.currencySymbol}';
  }

  /// Formats as number with thousands separator. 150000 → "150,000"
  String get formatted {
    return toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  /// Formats as compact. 1500000 → "1.5M"
  String get compact {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toInt().toString();
  }

  /// Formats as percentage. 0.45 → "45%"
  String get asPercentage => '${(this * 100).toStringAsFixed(1)}%';

  /// Formats as quantity (removes trailing zeros). 50.0 → "50", 50.5 → "50.5"
  String get asQuantity {
    if (this == toInt()) {
      return toInt().toString();
    }
    return toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

