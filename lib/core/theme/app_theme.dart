import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
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
      textTheme: base.textTheme
          .apply(fontFamily: AppTextStyles.family)
          .copyWith(
            displayLarge: AppTextStyles.display,
            headlineMedium: AppTextStyles.headline,
            titleLarge: AppTextStyles.title,
            bodyLarge: AppTextStyles.body,
            bodyMedium: AppTextStyles.body,
            labelLarge: AppTextStyles.label,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.title,
        iconTheme: IconThemeData(color: palette.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: BorderSide(color: palette.ink, width: AppDimens.borderWidth),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.ink,
        contentTextStyle: AppTextStyles.label.copyWith(color: palette.onInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.ink,
        thickness: AppDimens.hairline,
        space: 0,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
