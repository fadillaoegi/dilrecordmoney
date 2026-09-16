import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_text_styles.dart';

/// Tema aplikasi bergaya chunky 3D, dibangun dari [AppPalette] aktif.
class AppTheme {
  AppTheme._();

  /// Membangun tema untuk [palette].
  ///
  /// Penting: [AppColors.use] dipanggil lebih dulu supaya seluruh widget yang
  /// membaca `AppColors.x` (dan `AppTextStyles`) memakai palet yang sama
  /// dengan [ThemeData] yang dihasilkan di sini.
  static ThemeData from(AppPalette palette) {
    AppColors.use(palette);

    final base = palette.brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      colorScheme: base.colorScheme.copyWith(
        primary: palette.ink,
        secondary: palette.secondary,
        surface: palette.surface,
        onPrimary: palette.onInk,
        onSurface: palette.ink,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.label,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
