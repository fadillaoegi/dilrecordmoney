import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gaya teks tebal & padat untuk mendukung nuansa chunky.
///
/// Berupa *getter* (bukan `const`) karena warnanya mengikuti palet aktif —
/// lihat [AppColors].
class AppTextStyles {
  AppTextStyles._();

  static const String _family = 'Nunito'; // fallback ke default bila tak ada

  static TextStyle get display => TextStyle(
    fontFamily: _family,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.ink,
  );

  static TextStyle get headline => TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static TextStyle get title => TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle get label => TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    color: AppColors.ink,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
  );
}
