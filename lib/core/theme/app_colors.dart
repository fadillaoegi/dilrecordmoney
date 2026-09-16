import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Titik akses warna untuk seluruh UI — **monokrom**, mengikuti palet aktif.
///
/// Prinsip: hitam-putih-abu di semua elemen (fill, border, teks, shadow).
/// Satu-satunya pengecualian yang disengaja adalah [positive]/[negative]:
/// tetap hijau/merah karena dipakai khusus untuk teks nominal
/// pemasukan/pengeluaran (sinyal untung/rugi harus kebaca cepat).
///
/// Nilainya berupa *getter* (bukan `const`) supaya bisa ikut berubah saat
/// mode gelap dinyalakan. Palet diganti lewat [use] dari `AppTheme`, tepat
/// sebelum widget tree dibangun ulang, jadi seluruh widget membaca nilai baru.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;

  /// Palet yang sedang dipakai.
  static AppPalette get palette => _palette;

  /// Menukar palet aktif (dipanggil `AppTheme` saat mode tampilan berubah).
  static void use(AppPalette palette) => _palette = palette;

  // Latar
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;

  // Garis tepi & teks utama (tinta)
  static Color get ink => _palette.ink;
  static Color get shadow => _palette.shadow;

  // "Aksen" chunky — tangga abu netral supaya elemen tetap bisa dibedakan.
  static Color get primary => _palette.primary;
  static Color get secondary => _palette.secondary;
  static Color get accent => _palette.accent;
  static Color get coral => _palette.coral;
  static Color get purple => _palette.purple;

  // Pengecualian yang disengaja: nominal pemasukan/pengeluaran tetap berwarna.
  static Color get positive => _palette.positive;
  static Color get negative => _palette.negative;

  // Netral pendukung
  static Color get muted => _palette.muted;
  static Color get chip => _palette.chip;

  /// Teks/ikon di atas [ink] (mis. isi snackbar) — ikut terbalik di mode gelap.
  static Color get white => _palette.onInk;
}
