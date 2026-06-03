import 'package:intl/intl.dart';

/// Extensions on [DateTime] for convenient formatting.
extension DateTimeExtension on DateTime {
  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Returns true if this date is in the current month.
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Returns true if this date is in the current week.
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek);
  }

  /// Formats as display date: "22/05/2026"
  String get displayDate => DateFormat('dd/MM/yyyy').format(this);

  /// Formats as display date+time: "22/05/2026 14:30"
  String get displayDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// Formats as time only: "14:30"
  String get displayTime => DateFormat('HH:mm').format(this);

  /// Returns the start of this day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of this day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns the start of this month.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Returns the end of this month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}
