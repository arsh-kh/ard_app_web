import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Date and time formatting utilities.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);
  static final DateFormat _displayDateFormat = DateFormat(AppConstants.displayDateFormat);
  static final DateFormat _displayDateTimeFormat = DateFormat(AppConstants.displayDateTimeFormat);
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonth = DateFormat('dd MMM');

  /// Formats a DateTime for storage. "2026-05-22"
  static String formatForStorage(DateTime date) => _dateFormat.format(date);

  /// Formats a DateTime with time for storage. "2026-05-22 14:30"
  static String formatDateTimeForStorage(DateTime date) => _dateTimeFormat.format(date);

  /// Formats a DateTime for display. "22/05/2026"
  static String formatForDisplay(DateTime date) => _displayDateFormat.format(date);

  /// Formats a DateTime with time for display. "22/05/2026 14:30"
  static String formatDateTimeForDisplay(DateTime date) => _displayDateTimeFormat.format(date);

  /// Formats time only. "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Formats month and year. "May 2026"
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Formats day and month. "22 May"
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  /// Returns a human-readable relative time string.
  /// Example: "2 hours ago", "Yesterday", "3 days ago"
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return formatForDisplay(date);
    }
  }

  /// Gets the start of today (midnight).
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Gets the end of today (23:59:59).
  static DateTime get todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Gets the start of the current month.
  static DateTime get monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Gets the start of the current week (Monday).
  static DateTime get weekStart {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  /// Gets a date range for the last N days.
  static (DateTime, DateTime) lastNDays(int days) {
    final now = DateTime.now();
    return (
      DateTime(now.year, now.month, now.day - days),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Checks if a date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
