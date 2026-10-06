import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../enums/app_theme_mode.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'shared_preferences_provider.dart';

/// Mode tampilan pilihan pengguna (default: ikut sistem), disimpan lokal.
class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppThemeMode.fromKey(prefs.getString(AppConstants.kThemeMode));
  }

  Future<void> set(AppThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(AppConstants.kThemeMode, mode.key);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

/// Bahasa pilihan pengguna (default: Indonesia), disimpan lokal.
class AppLocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppLocale.fromCode(prefs.getString(AppConstants.kLocale));
  }

  Future<void> set(AppLocale locale) async {
    if (locale == state) return;
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(AppConstants.kLocale, locale.code);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale>(
  AppLocaleNotifier.new,
);

/// Kecerahan sistem (terang/gelap) — diperbarui oleh `DilRecordApp` lewat
/// `WidgetsBindingObserver` saat pengguna mengganti mode gelap di HP, supaya
/// mode "Ikuti Sistem" ikut berubah tanpa membuka ulang aplikasi.
class PlatformBrightnessNotifier extends Notifier<Brightness> {
  @override
  Brightness build() => PlatformDispatcher.instance.platformBrightness;

  void set(Brightness brightness) => state = brightness;
}

final platformBrightnessProvider =
    NotifierProvider<PlatformBrightnessNotifier, Brightness>(
      PlatformBrightnessNotifier.new,
    );

/// Tampilan aktif: palet hasil pilihan tema (+ kecerahan sistem) dan bahasa.
///
/// Sekaligus menerapkannya ke [AppColors] & [AppStrings] global. Provider
/// yang membuat data berwarna/berteks (kategori, dompet, grafik) **wajib**
/// me-watch provider ini: selain otomatis dihitung ulang saat tema/bahasa
/// berubah, urutan baca menjamin palet global sudah diganti sebelum data
/// baru dibuat.
typedef Appearance = ({AppPalette palette, AppLocale locale});

final appearanceProvider = Provider<Appearance>((ref) {
  final isDark = switch (ref.watch(themeModeProvider)) {
    AppThemeMode.system =>
      ref.watch(platformBrightnessProvider) == Brightness.dark,
    AppThemeMode.light => false,
    AppThemeMode.dark => true,
  };
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  final locale = ref.watch(appLocaleProvider);
  AppColors.use(palette);
  AppStrings.use(locale);
  return (palette: palette, locale: locale);
});
