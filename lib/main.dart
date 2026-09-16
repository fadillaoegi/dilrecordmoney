import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/enums/app_theme_mode.dart';
import 'core/l10n/app_locale.dart';
import 'core/l10n/app_strings.dart';
import 'core/providers/app_settings_providers.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat SharedPreferences sekali di awal agar bisa dipakai sinkron
  // oleh provider di seluruh aplikasi (di-override di ProviderScope).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DilRecordApp(),
    ),
  );
}

class DilRecordApp extends ConsumerWidget {
  const DilRecordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);

    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = switch (themeMode) {
      AppThemeMode.system => systemDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
    };

    // Palet & bahasa aktif ditukar di sini — sebelum subtree dibangun — supaya
    // `AppColors.x` dan `AppStrings.t` di seluruh widget membaca nilai terbaru.
    final theme = AppTheme.from(isDark ? AppPalette.dark : AppPalette.light);
    AppStrings.use(appLocale);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      locale: appLocale.locale,
      supportedLocales: AppLocale.values.map((e) => e.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Tap di mana saja (di luar widget yang menangani tap-nya sendiri)
      // menutup keyboard sistem yang sedang terbuka.
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }
}
