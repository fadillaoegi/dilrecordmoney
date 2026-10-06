/// Konstanta ukuran untuk gaya brutalist: sudut tegas, garis tebal,
/// bayangan keras yang jatuh diagonal (bukan blur).
class AppDimens {
  AppDimens._();

  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Radius — sengaja kecil. Sudut membulat besar bikin semua terlihat
  // seperti template; sudut tegas memberi karakter "kertas & tinta".
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 10;
  static const double radiusPill = 999;

  // Garis tepi
  static const double borderWidth = 2;
  static const double borderWidthBold = 3;
  static const double hairline = 1;

  // Offset hard-shadow, jatuh ke kanan-bawah.
  static const double shadowOffset = 5;
  static const double shadowOffsetSm = 3;
}
