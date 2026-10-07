import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Warna seri grafik kategorikal (irisan pie, legenda).
///
/// Sengaja **terpisah** dari warna kategori (pastel pucat yang berulang):
/// enam rona ini divalidasi untuk buta warna (ΔE CVD ≥ 8,4) dan penglihatan
/// normal (ΔE ≥ 19,3) di mode terang & gelap, untuk **setiap** jumlah irisan
/// 2–6 — termasuk pasangan irisan terakhir ↔ pertama yang bersentuhan di pie.
/// Jangan ubah urutannya tanpa validasi ulang.
class ChartPalette {
  ChartPalette._();

  static const List<Color> _light = [
    Color(0xFF2A78D6), // biru
    Color(0xFFEB6834), // oranye
    Color(0xFF1BAF7A), // aqua
    Color(0xFFEDA100), // kuning
    Color(0xFFE87BA4), // magenta
    Color(0xFF008300), // hijau
  ];

  static const List<Color> _dark = [
    Color(0xFF3987E5),
    Color(0xFFD95926),
    Color(0xFF199E70),
    Color(0xFFC98500),
    Color(0xFFD55181),
    Color(0xFF008300),
  ];

  static bool get _isDark => AppColors.palette.brightness == Brightness.dark;

  /// Warna seri ke-[index] (urutan tetap, tidak diputar ulang).
  static Color series(int index) {
    final colors = _isDark ? _dark : _light;
    return colors[index.clamp(0, colors.length - 1)];
  }

  static int get seriesCount => _light.length;

  /// Abu netral untuk irisan gabungan "Lainnya".
  static Color get other =>
      _isDark ? const Color(0xFF6F6D68) : const Color(0xFFA8A6A0);
}
