import 'package:flutter/material.dart';

/// Kumpulan warna untuk satu mode tampilan (terang / gelap).
///
/// Dipisah dari [AppColors] supaya nilainya bisa ditukar saat runtime tanpa
/// mengubah ratusan pemanggilan `AppColors.x` yang tersebar di widget.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.shadow,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.coral,
    required this.purple,
    required this.positive,
    required this.negative,
    required this.muted,
    required this.chip,
    required this.onInk,
    required this.brightness,
  });

  final Color background;
  final Color surface;

  /// Garis tepi & teks utama. Di mode gelap nilainya jadi terang.
  final Color ink;
  final Color shadow;

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color coral;
  final Color purple;

  /// Pengecualian tema monokrom: nominal pemasukan/pengeluaran tetap berwarna.
  final Color positive;
  final Color negative;

  final Color muted;
  final Color chip;

  /// Warna teks/ikon yang diletakkan **di atas** [ink] (mis. isi snackbar).
  final Color onInk;

  final Brightness brightness;

  /// Mode terang: latar hampir putih, garis tepi hitam.
  static const AppPalette light = AppPalette(
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF161616),
    shadow: Color(0xFF161616),
    primary: Color(0xFFE3E3E3),
    secondary: Color(0xFFCFCFCF),
    accent: Color(0xFFEDEDED),
    coral: Color(0xFFB8B8B8),
    purple: Color(0xFFA3A3A3),
    positive: Color(0xFF15803D),
    negative: Color(0xFFDC2626),
    muted: Color(0xFF737373),
    chip: Color(0xFFECECEC),
    onInk: Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  /// Mode gelap: peran terbalik — latar gelap, garis tepi & teks terang.
  /// Hard-shadow ikut terang supaya efek "timbul" tetap kebaca.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    ink: Color(0xFFF2F2F2),
    shadow: Color(0xFFF2F2F2),
    primary: Color(0xFF2E2E2E),
    secondary: Color(0xFF3A3A3A),
    accent: Color(0xFF262626),
    coral: Color(0xFF4A4A4A),
    purple: Color(0xFF555555),
    positive: Color(0xFF4ADE80),
    negative: Color(0xFFFF6B6B),
    muted: Color(0xFFA1A1A1),
    chip: Color(0xFF2A2A2A),
    onInk: Color(0xFF121212),
    brightness: Brightness.dark,
  );
}
