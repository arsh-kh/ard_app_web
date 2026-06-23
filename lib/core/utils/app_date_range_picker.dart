// lib/core/utils/app_date_range_picker.dart
//
// Shared styled date-range picker used by orders and purchase history screens.
//
// Key properties:
//  - ALWAYS left-to-right layout regardless of app locale (wraps in Directionality.ltr)
//  - Localized button labels and field hints for en / ku / ar
//  - Black-and-white theme that matches the app palette
//  - Rounded dialog corners + clean typography

import 'package:flutter/material.dart';
import 'app_translations.dart';

/// Opens the Flutter Material date-range picker with app-specific styling and
/// fully localised text strings. The picker layout is always LTR.
///
/// Returns the chosen [DateTimeRange] or `null` if the user dismissed it.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required String langCode,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  String t(String key) => Tr.t(key, langCode);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDateRangePicker(
    context: context,
    locale: Locale(langCode),
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime.now(),
    initialDateRange: initialDateRange,
    // ── Localised strings ──────────────────────────────────────────
    helpText: t('dpTitle').toUpperCase(),
    saveText: t('dpSave'),
    cancelText: t('cancelBtn'),
    fieldStartLabelText: t('dpStartDate'),
    fieldEndLabelText: t('dpEndDate'),
    fieldStartHintText: t('dpStartHint'),
    fieldEndHintText: t('dpEndHint'),
    errorInvalidRangeText: t('dpInvalidRange'),
    errorFormatText: t('dpInvalidFormat'),
    errorInvalidText: t('dpInvalidFormat'),
    // ── Styling ───────────────────────────────────────────────────
    builder: (context, child) {
      // 1. Always LTR so the calendar grid renders correctly
      // 2. Apply a clean black-and-white theme
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(data: _buildPickerTheme(context, isDark), child: child!),
      );
    },
  );
}

ThemeData _buildPickerTheme(BuildContext context, bool isDark) {
  final base = Theme.of(context);

  // Primary = black in light mode, white in dark mode (matches app rule)
  final bgColor = isDark ? Colors.white : Colors.black;
  final textColor = isDark ? Colors.black : Colors.white;
  
  final primary = Theme.of(context).colorScheme.onSurface;
  final onPrimary = Theme.of(context).colorScheme.surface;
  final surface = Theme.of(context).colorScheme.surface;
  final onSurface = Theme.of(context).colorScheme.onSurface;

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      surface: surface,
      onSurface: onSurface,
      // Fixes the default teal/green range highlight
      primaryContainer: primary.withValues(alpha: 0.15),
      onPrimaryContainer: primary,
      // Fixes the invisible weekday text (M, T, W, etc.)
      onSurfaceVariant: onSurface.withValues(alpha: 0.7),
    ),
    // Rounded dialog
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: surface,
      elevation: 8,
    ),
    // Text buttons (Cancel / Save)
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return textColor.withValues(alpha: 0.5);
          return textColor;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return bgColor.withValues(alpha: 0.15);
          return bgColor;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.disabled) ? textColor.withValues(alpha: 0.5) : textColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          );
        }),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),
    // Input decoration for the date text fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      labelStyle: TextStyle(
        color: onSurface.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: onSurface.withValues(alpha: 0.35),
        fontSize: 13,
      ),
    ),
  );
}
