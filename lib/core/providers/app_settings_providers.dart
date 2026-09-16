import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../enums/app_theme_mode.dart';
import '../l10n/app_locale.dart';
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
