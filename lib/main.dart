import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_locale.dart';
import 'core/providers/app_settings_providers.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/router/app_router.dart';
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

class DilRecordApp extends ConsumerStatefulWidget {
  const DilRecordApp({super.key});

  @override
  ConsumerState<DilRecordApp> createState() => _DilRecordAppState();
}

class _DilRecordAppState extends ConsumerState<DilRecordApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Mode gelap HP diganti saat aplikasi terbuka → mode "Ikuti Sistem"
  /// langsung ikut.
  @override
  void didChangePlatformBrightness() {
    ref
        .read(platformBrightnessProvider.notifier)
        .set(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  /// Banyak widget membaca `AppColors.x` / `AppStrings.t` global yang tidak
  /// memberi tahu siapa pun saat berubah. Tandai seluruh subtree untuk
  /// dibangun ulang (state & riwayat navigasi tetap utuh) supaya semua
  /// halaman — termasuk yang tertutup di belakang — langsung ganti tampilan.
  void _rebuildEverything() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appearanceProvider, (previous, next) {
      if (previous != next) _rebuildEverything();
    });

    final router = ref.watch(routerProvider);
    final appearance = ref.watch(appearanceProvider);
    final palette = appearance.palette;
    final isDark = palette.brightness == Brightness.dark;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.from(palette),
      // Tanpa animasi lerp: widget yang memakai AppColors berganti seketika,
      // jadi tema Material juga harus seketika agar tidak campur aduk.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: appearance.locale.locale,
      supportedLocales: AppLocale.values.map((e) => e.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Ikon status bar ikut tema, juga di layar tanpa AppBar.
          value: isDark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: palette.background,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: palette.background,
                ),
          // Tap di mana saja (di luar widget yang menangani tap-nya sendiri)
          // menutup keyboard sistem yang sedang terbuka.
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        );
      },
    );
  }
}
