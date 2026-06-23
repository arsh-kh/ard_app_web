import 'package:flutter_test/flutter_test.dart';
import 'package:ard_app/core/utils/currency_formatter.dart';
import 'package:ard_app/core/constants/app_constants.dart';

void main() {
  group('CurrencyFormatter', () {
    test('format properly converts doubles to IQD string', () {
      expect(
        CurrencyFormatter.format(150000),
        '\u202A150,000 ${AppConstants.currencySymbol}\u202C',
      );
      expect(CurrencyFormatter.format(0), '\u202A0 ${AppConstants.currencySymbol}\u202C');
      expect(
        CurrencyFormatter.format(1234.56),
        '\u202A1,234.56 ${AppConstants.currencySymbol}\u202C',
      );
    });

    test('formatNumber strips symbol but keeps commas', () {
      expect(CurrencyFormatter.formatNumber(150000), '\u202A150,000\u202C');
    });

    test('parse converts formatted string back to double', () {
      expect(
        CurrencyFormatter.parse('\u202A150,000 ${AppConstants.currencySymbol}\u202C'),
        150000.0,
      );
      expect(CurrencyFormatter.parse('\u202A1,234.56\u202C'), 1234.56);
      expect(CurrencyFormatter.parse('invalid'), 0.0);
    });

    test('formatQuantity handles plurals in English', () {
      // Assuming default is English in tests
      expect(CurrencyFormatter.formatQuantity(1, 'bag'), '1 bag');
      expect(CurrencyFormatter.formatQuantity(2, 'bag'), '2 bags');
      expect(CurrencyFormatter.formatQuantity(5, 'box'), '5 boxes');
      expect(CurrencyFormatter.formatQuantity(2.5, 'kg'), '2.50 kg');
    });

    test('formatWeight converts to tons when >= 1000kg', () {
      expect(CurrencyFormatter.formatWeight(500), '500 kg');
      expect(CurrencyFormatter.formatWeight(1000), '1 ton');
      expect(CurrencyFormatter.formatWeight(1500), '1.5 ton');
      expect(CurrencyFormatter.formatWeight(2000), '2 ton');
    });

    test('formatCompact creates short dashboard stats', () {
      expect(CurrencyFormatter.formatCompact(500), '\u202A500\u202C');
      expect(CurrencyFormatter.formatCompact(1500), '\u202A1.5K\u202C');
      expect(CurrencyFormatter.formatCompact(1000000), '\u202A1M\u202C');
      expect(CurrencyFormatter.formatCompact(2500000), '\u202A2.5M\u202C');
      expect(CurrencyFormatter.formatCompact(1500000000), '\u202A1.5B\u202C');
    });
  });
}
