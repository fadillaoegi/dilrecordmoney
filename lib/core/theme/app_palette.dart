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
    background: Color(0xFFF2F2F2),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF161616),
    shadow: Color(0xFF161616),
    primary: Color(0xFFFFF9C4), // kuning hangat — balance card tetap cerah
    secondary: Color(0xFFFFF3E0), // oranye sangat pucat
    accent: Color(0xFFE8F5E9), // hijau sangat pucat
    coral: Color(0xFFFFEBEE), // merah sangat pucat
    purple: Color(0xFFEDE7F6), // ungu sangat pucat
    positive: Color(0xFF15803D),
    negative: Color(0xFFDC2626),
    muted: Color(0xFF737373),
    chip: Color(0xFFEEEEEE),
    onInk: Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  /// Mode gelap: kebalikan logis mode terang, bukan sekadar abu-abu.
  ///
  /// - Latar arang, kartu sedikit lebih terang (hierarki tetap terbaca).
  /// - Tinta = putih gading untuk teks & garis tepi.
  /// - Bayangan keras abu gelap: masih terlihat sebagai "tumpukan kertas"
  ///   tanpa jadi garis putih menyala seperti sebelumnya.
  /// - Aksen = versi gelap dari pastel mode terang (kuning, oranye, hijau,
  ///   merah, ungu) sehingga ikon kategori & tombol utama tetap punya warna
  ///   dan tetap kontras dengan teks terang di atasnya.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF131313),
    surface: Color(0xFF1E1E1E),
    ink: Color(0xFFEDEAE3),
    shadow: Color(0xFF4A4A4A),
    primary: Color(0xFF4A3F12), // kuning tua — tombol "Catat Transaksi"
    secondary: Color(0xFF4A2F18), // oranye tua
    accent: Color(0xFF1F3A27), // hijau tua
    coral: Color(0xFF47222A), // merah tua
    purple: Color(0xFF332A4D), // ungu tua
    positive: Color(0xFF5BD98A),
    negative: Color(0xFFFF7A7A),
    muted: Color(0xFF9C9A95),
    chip: Color(0xFF2B2B2B),
    onInk: Color(0xFF131313),
    brightness: Brightness.dark,
  );
}
