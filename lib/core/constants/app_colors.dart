import 'package:flutter/material.dart';

/// Humanist Accessible color palette for the Drone Crack Detection app.
/// Prioritizes warmth, readability, and clear visual hierarchies.
class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF40916C);
  static const Color primaryDark = Color(0xFF1B4332);

  // ── Secondary / Accent ───────────────────────────────────────────
  static const Color secondary = Color(0xFF52B788);
  static const Color secondaryLight = Color(0xFF74C69D);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);

  // ── Surface & Background ─────────────────────────────────────────
  static const Color background = Color(0xFFFAFAF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F0);
  static const Color cardShadow = Color(0x0D8B7355);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Severity Colors (Crack Classification) ───────────────────────
  static const Color severitySafe = Color(0xFF22C55E);
  static const Color severitySafeBg = Color(0xFFDCFCE7);
  static const Color severityHairline = Color(0xFFF59E0B);
  static const Color severityHairlineBg = Color(0xFFFEF3C7);
  static const Color severityStructural = Color(0xFFEF4444);
  static const Color severityStructuralBg = Color(0xFFFEE2E2);
  static const Color severitySpalling = Color(0xFFDC2626);
  static const Color severitySpallingBg = Color(0xFFFECACA);

  // ── Crack Class Colors (per classification) ──────────────────────
  // Color-coded by crack orientation class rather than severity category.
  static const Color classVertikal = Color(0xFF8B5CF6); // Purple
  static const Color classVertikalBg = Color(0xFFEDE9FE);
  static const Color classHorizontal = Color(0xFF3B82F6); // Blue
  static const Color classHorizontalBg = Color(0xFFDBEAFE);
  static const Color classDiagonal = Color(0xFFEAB308); // Yellow
  static const Color classDiagonalBg = Color(0xFFFEF9C3);

  // ── Connection States ────────────────────────────────────────────
  static const Color connected = Color(0xFF22C55E);
  static const Color connecting = Color(0xFFF59E0B);
  static const Color disconnected = Color(0xFFEF4444);

  // ── Misc ─────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmer = Color(0xFFE5E7EB);
  static const Color overlay = Color(0x80000000);
}
