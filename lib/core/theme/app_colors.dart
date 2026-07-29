import 'package:flutter/material.dart';

/// Palet warna untuk gaya "chunky 3D / neo-brutalism".
///
/// Prinsip: warna solid & berani, garis tepi gelap ([ink]), dan latar hangat.
/// Kedalaman 3D dibuat dari [shadow] (hard shadow tanpa blur).
class AppColors {
  AppColors._();

  // Latar
  static const Color background = Color(0xFFFDF3E3); // cream hangat
  static const Color surface = Color(0xFFFFFDF8); // hampir putih

  // Garis tepi & teks utama (tinta)
  static const Color ink = Color(0xFF1E1B2E);
  static const Color shadow = Color(0xFF1E1B2E);

  // Warna brand / aksen (chunky & playful)
  static const Color primary = Color(0xFF4ADE80); // mint green — uang/tumbuh
  static const Color secondary = Color(0xFF5B8DEF); // biru langit
  static const Color accent = Color(0xFFFFD84D); // kuning cerah
  static const Color coral = Color(0xFFFF6B6B); // merah koral
  static const Color purple = Color(0xFFB08BFA); // ungu lembut

  // Semantik nominal (kontras cukup di atas latar terang)
  static const Color positive = Color(0xFF15803D); // hijau tua — pemasukan
  static const Color negative = Color(0xFFDC2626); // merah tua — pengeluaran

  // Netral pendukung
  static const Color muted = Color(0xFF6E687A);
  static const Color chip = Color(0xFFF1E7D6);
  static const Color white = Color(0xFFFFFFFF);
}
