// Menguji pergantian bahasa & mode tampilan (termasuk penyimpanannya).

import 'package:dilrecordmoney/core/enums/app_theme_mode.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/l10n/app_locale.dart';
import 'package:dilrecordmoney/core/l10n/app_strings.dart';
import 'package:dilrecordmoney/core/providers/app_settings_providers.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/theme/app_colors.dart';
import 'package:dilrecordmoney/core/theme/app_palette.dart';
import 'package:dilrecordmoney/core/theme/app_theme.dart';
import 'package:dilrecordmoney/core/utils/date_formatter.dart';
import 'package:dilrecordmoney/features/categories/data/category_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Kembalikan ke default supaya tidak bocor antar test.
  tearDown(() {
    AppStrings.use(AppLocale.id);
    AppColors.use(AppPalette.light);
  });

  group('AppLocale & AppStrings', () {
    test('kode tak dikenal jatuh ke bahasa Indonesia', () {
      expect(AppLocale.fromCode(null), AppLocale.id);
      expect(AppLocale.fromCode('xx'), AppLocale.id);
      expect(AppLocale.fromCode('ja'), AppLocale.ja);
    });

    test('teks ikut bahasa aktif', () {
      AppStrings.use(AppLocale.id);
      expect(AppStrings.t.income, 'Pemasukan');
      AppStrings.use(AppLocale.en);
      expect(AppStrings.t.income, 'Income');
      AppStrings.use(AppLocale.zh);
      expect(AppStrings.t.income, '收入');
      AppStrings.use(AppLocale.ja);
      expect(AppStrings.t.income, '収入');
    });

    test('label enum & nama kategori ikut bahasa', () {
      AppStrings.use(AppLocale.en);
      expect(TransactionType.expense.label, 'Expense');
      final food = CategoryCatalog.expense.firstWhere((c) => c.id == 'exp_food');
      expect(food.name, 'Food & Drink');

      AppStrings.use(AppLocale.ja);
      expect(TransactionType.expense.label, '支出');
      final foodJa = CategoryCatalog.expense.firstWhere(
        (c) => c.id == 'exp_food',
      );
      expect(foodJa.name, '飲食');
    });

    test('nama bulan di DateFormatter ikut bahasa', () {
      AppStrings.use(AppLocale.id);
      expect(DateFormatter.monthYear(DateTime(2026, 9, 1)), 'September 2026');
      AppStrings.use(AppLocale.en);
      expect(DateFormatter.short(DateTime(2026, 5, 3)), '3 May 2026');
    });

    test('kategori baru tersedia di katalog', () {
      AppStrings.use(AppLocale.id);
      final expenseIds = CategoryCatalog.expense.map((c) => c.id);
      expect(expenseIds, containsAll(['exp_sports', 'exp_vape']));
      final incomeIds = CategoryCatalog.income.map((c) => c.id);
      expect(incomeIds, containsAll(['inc_refund', 'inc_freelance']));
    });
  });

  group('Tema', () {
    test('palet gelap membalik peran ink & latar', () {
      AppTheme.from(AppPalette.light);
      final lightInk = AppColors.ink;
      final lightBg = AppColors.background;

      AppTheme.from(AppPalette.dark);
      expect(AppColors.ink, isNot(lightInk));
      expect(AppColors.background, isNot(lightBg));
      // Di mode gelap, "tinta" jadi lebih terang dari latar.
      expect(
        AppColors.ink.computeLuminance(),
        greaterThan(AppColors.background.computeLuminance()),
      );
      expect(AppColors.palette.brightness, Brightness.dark);
    });

    test('mode tampilan tak dikenal jatuh ke ikut sistem', () {
      expect(AppThemeMode.fromKey(null), AppThemeMode.system);
      expect(AppThemeMode.fromKey('dark'), AppThemeMode.dark);
    });
  });

  group('Penyimpanan pengaturan', () {
    Future<ProviderContainer> makeContainer() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('default: bahasa Indonesia & ikut sistem', () async {
      final container = await makeContainer();
      expect(container.read(appLocaleProvider), AppLocale.id);
      expect(container.read(themeModeProvider), AppThemeMode.system);
    });

    test('pilihan bahasa & tema bertahan di SharedPreferences', () async {
      final container = await makeContainer();
      await container.read(appLocaleProvider.notifier).set(AppLocale.ja);
      await container.read(themeModeProvider.notifier).set(AppThemeMode.dark);

      // Container baru dengan prefs yang sama = seperti app dibuka ulang.
      final prefs = await SharedPreferences.getInstance();
      final reopened = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(reopened.dispose);

      expect(reopened.read(appLocaleProvider), AppLocale.ja);
      expect(reopened.read(themeModeProvider), AppThemeMode.dark);
    });
  });
}
