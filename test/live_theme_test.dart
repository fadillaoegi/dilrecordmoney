import 'package:dilrecordmoney/core/enums/app_theme_mode.dart';
import 'package:dilrecordmoney/core/l10n/app_locale.dart';
import 'package:dilrecordmoney/core/l10n/app_strings.dart';
import 'package:dilrecordmoney/core/providers/app_settings_providers.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/router/app_router.dart';
import 'package:dilrecordmoney/core/theme/app_colors.dart';
import 'package:dilrecordmoney/core/theme/app_palette.dart';
import 'package:dilrecordmoney/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget `const` yang membaca warna/teks global — tipe widget yang dulu
/// tidak ikut berubah saat tema/bahasa diganti.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('probe'),
      color: AppColors.background,
      child: Text(AppStrings.t.income),
    );
  }
}

void main() {
  tearDown(() {
    AppColors.use(AppPalette.light);
    AppStrings.use(AppLocale.id);
  });

  testWidgets('tema & bahasa berganti seketika tanpa restart', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        routerProvider.overrideWithValue(
          GoRouter(
            routes: [GoRoute(path: '/', builder: (_, _) => const _Probe())],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DilRecordApp(),
      ),
    );
    await tester.pumpAndSettle();

    Color probeColor() =>
        tester.widget<ColoredBox>(find.byKey(const Key('probe'))).color;

    expect(probeColor(), AppPalette.light.background);
    expect(find.text('Pemasukan'), findsOneWidget);

    await container.read(themeModeProvider.notifier).set(AppThemeMode.dark);
    await tester.pump();
    expect(probeColor(), AppPalette.dark.background);

    await container.read(appLocaleProvider.notifier).set(AppLocale.en);
    await tester.pump();
    expect(find.text('Income'), findsOneWidget);

    // Mode "Ikuti Sistem" mengikuti perubahan kecerahan HP.
    await container.read(themeModeProvider.notifier).set(AppThemeMode.system);
    container.read(platformBrightnessProvider.notifier).set(Brightness.light);
    await tester.pump();
    expect(probeColor(), AppPalette.light.background);
    container.read(platformBrightnessProvider.notifier).set(Brightness.dark);
    await tester.pump();
    expect(probeColor(), AppPalette.dark.background);
  });
}
