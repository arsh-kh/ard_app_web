import 'package:flutter/material.dart';

/// Application color palette for the ئارد flour distribution app.
/// Uses Material Design 3 color system with custom brand colors.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────
  /// Deep blue - trust, professionalism, reliability
  static const Color primarySeed = Color(0xFF1565C0);

  /// Warm amber - wheat/flour tones, warmth
  static const Color secondarySeed = Color(0xFFF59E0B);

  /// Green - growth, profit, success
  static const Color tertiarySeed = Color(0xFF16A34A);

  // ── Semantic Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ── Sync Status Colors ────────────────────────────────────────
  static const Color synced = Color(0xFF16A34A);
  static const Color pendingSync = Color(0xFFF59E0B);
  static const Color syncing = Color(0xFF2563EB);
  static const Color syncFailed = Color(0xFFDC2626);

  // ── Stock Status Colors ───────────────────────────────────────
  static const Color inStock = Color(0xFF16A34A);
  static const Color lowStock = Color(0xFFF59E0B);
  static const Color outOfStock = Color(0xFFDC2626);

  // ── Payment Status Colors ─────────────────────────────────────
  static const Color paid = Color(0xFF16A34A);
  static const Color partialPayment = Color(0xFFF59E0B);
  static const Color unpaid = Color(0xFFDC2626);

  // ── Chart Colors ──────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF1565C0),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  // ── Gradient Presets ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Color(0x80000000), Color(0x00000000)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
