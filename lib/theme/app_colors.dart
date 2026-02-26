import 'package:flutter/material.dart';

class AppColors {
  // ─── Brand ─────────────────────────────────────────────────────
  static const Color primaryPurple   = Color(0xFFA855F7);
  static const Color secondaryPurple = Color(0xFF7C3AED);

  // ─── Dark Mode ─────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF0B0B0F);
  static const Color darkSurface = Color(0xFF151519);
  static const Color darkBorder  = Color(0xFF222228);
  static const Color darkText    = Color(0xFFFFFFFF);

  // ─── Light Mode (matched to Figma) ─────────────────────────────
  static const Color lightBg      = Color(0xFFF4F4F8); // page background
  static const Color lightSurface = Color(0xFFFFFFFF); // card / tile
  static const Color lightBorder  = Color(0xFFE5E7EB); // dividers & borders
  static const Color lightText    = Color(0xFF121214); // primary text
  static const Color lightSubtext = Color(0xFF6B7280); // secondary text

  // ─── Icon tint backgrounds ──────────────────────────────────────
  static const Color iconBgDark  = Color(0xFF2A1A3E); // dark purple tint
  static const Color iconBgLight = Color(0xFFF3E8FF); // light purple tint

  // ─── Neutral ───────────────────────────────────────────────────
  static const Color gray7B = Color(0xFF7B7B85);
  static const Color grayE6 = Color(0xFFE6E6EA);

  // ─── Status ────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);

  // ─── Gradients ─────────────────────────────────────────────────
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glowGradient = LinearGradient(
    colors: const [
      Color(0x99B12CFF),
      Color(0x4D8D21B7),
      Color(0x00000000),
    ],
    begin: Alignment.center,
    end: Alignment.bottomCenter,
  );

  // ─── Theme-aware helpers ────────────────────────────────────────

  /// Page / scaffold background
  static Color bg(BuildContext context) =>
      _isDark(context) ? darkBg : lightBg;

  /// Card / tile surface
  static Color surface(BuildContext context) =>
      _isDark(context) ? darkSurface : lightSurface;

  /// Divider / border
  static Color border(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;

  /// Primary text
  static Color text(BuildContext context) =>
      _isDark(context) ? darkText : lightText;

  /// Secondary / muted text
  static Color subtext(BuildContext context) =>
      _isDark(context) ? gray7B : lightSubtext;

  /// Icon container background
  static Color iconBg(BuildContext context) =>
      _isDark(context) ? iconBgDark : iconBgLight;

  // ─── Internal ──────────────────────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}