import 'package:uuid/uuid.dart';

/// Generates unique IDs for offline-first entities.
/// Uses UUID v4 to avoid collisions across devices.
class IdGenerator {
  IdGenerator._();

  static const _uuid = Uuid();

  /// Generates a new UUID v4 string.
  static String generate() => _uuid.v4();

  /// Generates a sequential invoice number.
  /// Format: PREFIX-YYYYMM-XXXX (e.g., INV-202605-0001)
  static String generateInvoiceNumber(String prefix, int sequenceNumber) {
    final now = DateTime.now();
    final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final seq = sequenceNumber.toString().padLeft(4, '0');
    return '$prefix-$yearMonth-$seq';
  }
}

