import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'app_translations.dart';

/// Centralized app feedback with themed SnackBars and haptic feedback.
/// Replaces raw ScaffoldMessenger calls for a consistent, professional feel.
class AppFeedback {
  AppFeedback._();

  /// Show a success-themed SnackBar (green) with haptic feedback.
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _show(context, message, _SnackType.success);
  }

  /// Show an error-themed SnackBar (red) with haptic feedback.
  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _show(context, message, _SnackType.error);
  }

  /// Show an info-themed SnackBar (blue/amber).
  static void showInfo(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _show(context, message, _SnackType.info);
  }

  /// Show an undo-style SnackBar with an action button.
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String? undoLabel,
  }) {
    HapticFeedback.lightImpact();
    final langCode = Localizations.localeOf(context).languageCode;
    final resolvedUndoLabel = undoLabel ?? Tr.t('btn_undo', langCode);

    final bottomMargin = _calculateBottomMargin(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsetsDirectional.only(
          bottom: bottomMargin,
          start: 16,
          end: 16,
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: resolvedUndoLabel,
          textColor: Colors.amber,
          onPressed: onUndo,
        ),
      ),
    );
  }

  static void _show(BuildContext context, String message, _SnackType type) {
    final (Color bg, Color iconColor, IconData icon) = switch (type) {
      _SnackType.success => (
        const Color(0xFF065F46),
        Colors.white,
        Icons.check_circle_outline,
      ),
      _SnackType.error => (
        const Color(0xFF991B1B),
        Colors.white,
        Icons.error_outline,
      ),
      _SnackType.info => (
        const Color(0xFF1E3A8A),
        Colors.white,
        Icons.info_outline,
      ),
    };

    final bottomMargin = _calculateBottomMargin(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsetsDirectional.only(
          bottom: bottomMargin,
          start: 16,
          end: 16,
        ),
        duration: Duration(seconds: type == _SnackType.error ? 4 : 2),
      ),
    );
  }

  static double _calculateBottomMargin(BuildContext context) {
    // Determine if we are on a shell route with the custom pill nav bar.
    bool hasBottomNav = false;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      hasBottomNav =
          location == '/admin' ||
          location == '/bakery' ||
          location == '/clients-orders' ||
          location == '/inventory' ||
          location == '/settings';
    } catch (_) {}

    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    if (hasBottomNav) {
      // The custom pill nav bar is 75px tall and sits 20px from the bottom edge (95px total).
      // We want the SnackBar to sit 10px above the pill (105px total).
      // Since SnackBar automatically ADDS safeAreaBottom to the margin,
      // we subtract it so the visual position remains strictly 105px from the absolute bottom.
      const targetAbsoluteMargin = 105.0;
      final margin = targetAbsoluteMargin - safeAreaBottom;
      return margin > 0 ? margin : 0;
    } else {
      // No nav bar. Just use 16px. SnackBar will add safeAreaBottom automatically,
      // resulting in a visually perfect placement above the home indicator.
      return 16.0;
    }
  }

  /// Show a confirmation dialog. Returns true if user confirms.
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
    IconData? icon,
  }) async {
    await HapticFeedback.lightImpact();
    if (!context.mounted) return false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final resolvedConfirm = confirmLabel ?? Tr.t('btn_confirm', langCode);
    final resolvedCancel = cancelLabel ?? Tr.t('btn_cancel', langCode);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        icon: icon != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (confirmColor ?? theme.colorScheme.primary).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: confirmColor ?? theme.colorScheme.primary,
                  size: 28,
                ),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            fontSize: 13,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(resolvedCancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? theme.colorScheme.primary,
              foregroundColor: confirmColor != null
                  ? Colors.white
                  : theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(resolvedConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

enum _SnackType { success, error, info }
