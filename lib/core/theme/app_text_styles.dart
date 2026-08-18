import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralised text styles. Swap [_fontFamily] for a Carlton Leisure
/// brand font later by pointing it at a bundled font instead of Google Fonts.
class AppTextStyles {
  AppTextStyles._();
  static bool _isDark = false;

  static void setDarkMode(bool isDark) => _isDark = isDark;

  static Color get _textPrimary => _isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  static Color get _textSecondary => _isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

  static TextStyle get _base => GoogleFonts.inter(color: _textPrimary);

  static TextStyle get h1 => _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle get h2 => _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25);
  static TextStyle get h3 => _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get h4 => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get bodyLarge => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: _textSecondary,
      );

  static TextStyle get button => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2);

  static TextStyle get price => _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary);

  static TextStyle get badge => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnAccent,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: _textSecondary);
}
