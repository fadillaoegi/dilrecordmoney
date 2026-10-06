import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi. Satu keluarga (Archivo) dengan kontras berat yang tajam:
/// angka besar & rapat untuk nominal, label kecil berhuruf kapital renggang
/// untuk judul bagian.
///
/// Berupa *getter* (bukan `const`) karena warnanya mengikuti palet aktif —
/// lihat [AppColors].
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Archivo';

  /// Angka sejajar kolom supaya nominal di daftar rata kanan dengan rapi.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle get display => TextStyle(
    fontFamily: family,
    fontSize: 40,
    height: 1.0,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.6,
    fontFeatures: _tabular,
    color: AppColors.ink,
  );

  static TextStyle get headline => TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.ink,
  );

  static TextStyle get title => TextStyle(
    fontFamily: family,
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static TextStyle get body => TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static TextStyle get label => TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  /// Label judul bagian — tulis teksnya dalam huruf kapital.
  static TextStyle get eyebrow => TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    color: AppColors.muted,
  );

  /// Nominal di baris daftar.
  static TextStyle get amount => TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    fontFeatures: _tabular,
    color: AppColors.ink,
  );
}
