import 'package:flutter/material.dart';

/// Carlton Leisure brand palette.
///
/// Primary  -> Dark blue  (headers, app bar, primary buttons, nav)
/// Surface  -> White      (backgrounds, cards)
/// Accent   -> Yellow     (CTAs, price highlights, badges, active states)
class AppColors {
  AppColors._();

  // Primary - dark blue
  static const Color primary = Color(0xFF0A2540);
  static const Color primaryLight = Color(0xFF13385E);
  static const Color primaryDark = Color(0xFF061A2E);

  // Accent - yellow
  static const Color accent = Color(0xFFFFC72C);
  static const Color accentLight = Color(0xFFFFDA6A);
  static const Color accentDark = Color(0xFFE6AC00);

  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceVariant = Color(0xFFEDF0F4);

  // Text
  static const Color textPrimary = Color(0xFF0A2540);
  static const Color textSecondary = Color(0xFF5C6B7A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0A2540);

  // Semantic
  static const Color success = Color(0xFF1E9E6C);
  static const Color error = Color(0xFFD93A3A);
  static const Color warning = Color(0xFFE6AC00);
  static const Color info = Color(0xFF2F80ED);

  // Borders / dividers
  static const Color border = Color(0xFFDDE2E8);
  static const Color divider = Color(0xFFE8EBEF);

  // Disabled
  static const Color disabled = Color(0xFFB8C0C9);
}
