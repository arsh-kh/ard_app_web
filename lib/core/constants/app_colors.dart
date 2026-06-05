import 'package:flutter/material.dart';

/// Application color palette for the ئارد flour distribution app.
/// Uses Material Design 3 color system with custom brand colors.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primarySeed = Color(0xFF000000); // Black
  static const Color secondarySeed = Color(0xFF4B5563); // Grey
  static const Color tertiarySeed = Color(0xFF9CA3AF); // Light Grey

  // ── Semantic Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF000000); // Black
  static const Color warning = Color(0xFF4B5563); // Grey
  static const Color error = Color(0xFF6B7280); // Muted Grey
  static const Color info = Color(0xFF111827); // Dark Grey

  // ── Sync Status Colors ────────────────────────────────────────
  static const Color synced = Color(0xFF000000); // Black
  static const Color pendingSync = Color(0xFF4B5563); // Grey
  static const Color syncing = Color(0xFF111827); // Dark Grey
  static const Color syncFailed = Color(0xFF6B7280); // Muted Grey

  // ── Stock Status Colors ───────────────────────────────────────
  static const Color inStock = Color(0xFF000000); // Black
  static const Color lowStock = Color(0xFF4B5563); // Grey
  static const Color outOfStock = Color(0xFF6B7280); // Muted Grey

  // ── Payment Status Colors ─────────────────────────────────────
  static const Color paid = Color(0xFF000000); // Black
  static const Color partialPayment = Color(0xFF4B5563); // Grey
  static const Color unpaid = Color(0xFF6B7280); // Muted Grey

  // ── Chart Colors ──────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF000000), // Black
    Color(0xFF374151), // Grey 700
    Color(0xFF6B7280), // Grey 500
    Color(0xFF9CA3AF), // Grey 400
    Color(0xFFD1D5DB), // Grey 300
    Color(0xFF111827), // Grey 900
    Color(0xFF4B5563), // Grey 600
    Color(0xFFE5E7EB), // Grey 200
  ];

  // ── Gradient Presets ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF374151)], // Black to Dark Grey
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF111827)], // Black to near Black
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFF4B5563), Color(0xFF6B7280)], // Greys
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)], // Lighter Greys
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Color(0x80000000), Color(0x00000000)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

