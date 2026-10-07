// Menguji data donut & bar chart di beranda.

import 'package:dilrecordmoney/core/enums/period_type.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/l10n/app_locale.dart';
import 'package:dilrecordmoney/core/l10n/app_strings.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/theme/app_colors.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/home/presentation/providers/chart_providers.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/period_selection.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/period_providers.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dilrecordmoney/core/providers/app_settings_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppStrings.use(AppLocale.id));

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  MoneyTransaction expenseOn(DateTime date, int amount, String categoryId) =>
      MoneyTransaction(
        id: IdGenerator.generate(),
        type: TransactionType.expense,
        amount: amount,
        categoryId: categoryId,
        walletId: 'cash',
        date: date,
      );

  /// Menyetel periode ke bulan yang memuat [anchor].
  void useMonthOf(ProviderContainer container, DateTime anchor) {
    container.read(periodSelectionProvider.notifier).state = container
        .read(periodSelectionProvider)
        .copyWith(type: PeriodType.monthly, anchor: anchor);
  }

  test('donut: kategori ke-7 dan seterusnya digabung ke "Lainnya"', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);
    final day = DateTime(2026, 9, 10);

    // 6 kategori teratas + 2 kategori kecil yang harus tergabung.
    const ids = [
      'exp_food',
      'exp_transport',
      'exp_shopping',
      'exp_bills',
      'exp_entertainment',
      'exp_health',
    ];
    for (var i = 0; i < ids.length; i++) {
      await notifier.addTransaction(expenseOn(day, 100000 - i * 1000, ids[i]));
    }
    await notifier.addTransaction(expenseOn(day, 5000, 'exp_education'));
    await notifier.addTransaction(expenseOn(day, 3000, 'exp_sports'));

    useMonthOf(container, day);
    final slices = container.read(categorySlicesProvider);

    expect(slices, hasLength(7)); // 6 teratas + gabungan
    final other = slices.last;
    expect(other.category.id, '__other__');
    expect(other.total, 8000); // 5000 + 3000
    // Ikut palet, bukan warna hardcode.
    expect(other.category.color, AppColors.muted);
    // Persentase total selalu ~100.
    final sum = slices.fold<double>(0, (a, s) => a + s.percentage);
    expect(sum, closeTo(100, 0.001));
  });

  test('donut: nama "Lainnya" ikut bahasa aktif', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);
    final day = DateTime(2026, 9, 10);

    const ids = [
      'exp_food',
      'exp_transport',
      'exp_shopping',
      'exp_bills',
      'exp_entertainment',
      'exp_health',
      'exp_education',
    ];
    for (final id in ids) {
      await notifier.addTransaction(expenseOn(day, 10000, id));
    }
    useMonthOf(container, day);

    // Ganti bahasa lewat provider (jalur yang dipakai aplikasi) — data
    // grafik harus ikut berubah tanpa invalidate manual.
    final locale = container.read(appLocaleProvider.notifier);
    expect(
      container.read(categorySlicesProvider).last.category.name,
      'Lainnya',
    );

    await locale.set(AppLocale.en);
    expect(container.read(categorySlicesProvider).last.category.name, 'Other');

    await locale.set(AppLocale.ja);
    expect(container.read(categorySlicesProvider).last.category.name, 'その他');
  });

  group('tren batang mencakup seluruh periode', () {
    MoneyTransaction tx(DateTime d, int amount, {bool income = false}) =>
        MoneyTransaction(
          id: IdGenerator.generate(),
          type: income ? TransactionType.income : TransactionType.expense,
          amount: amount,
          categoryId: income ? 'inc_salary' : 'exp_food',
          walletId: 'cash',
          date: d,
        );

    test('Bulanan: per minggu 1–7 … 29–30, total = ringkasan bulan', () async {
      final container = await makeContainer();
      final notifier = container.read(transactionListProvider.notifier);
      // 9 hari bertransaksi + pemasukan — dulu hanya 7 hari terakhir masuk.
      for (var day = 1; day <= 9; day++) {
        await notifier.addTransaction(
          tx(DateTime(2026, 9, day, 10), 1000 * day),
        );
      }
      await notifier.addTransaction(
        tx(DateTime(2026, 9, 30, 23, 59), 500000, income: true),
      );
      useMonthOf(container, DateTime(2026, 9, 15));

      final bars = container.read(barChartProvider);
      expect(bars.map((b) => b.label), [
        '1–7',
        '8–14',
        '15–21',
        '22–28',
        '29–30',
      ]);
      expect(bars[0].expense, 28000); // 1+…+7 ribu
      expect(bars[1].expense, 17000); // 8+9 ribu
      expect(bars[2].expense, 0); // minggu kosong tetap ada
      expect(bars[4].income, 500000); // 30 Sep 23:59 tetap masuk

      final summary = container.read(filteredSummaryProvider);
      expect(bars.fold(0, (a, b) => a + b.expense), summary.totalExpense);
      expect(bars.fold(0, (a, b) => a + b.income), summary.totalIncome);
    });

    test('Tahunan: 12 bulan Jan–Des', () {
      final bars = trendBuckets(
        PeriodSelection(type: PeriodType.yearly, anchor: DateTime(2026, 5)),
        [tx(DateTime(2026, 1, 5), 100), tx(DateTime(2026, 12, 31, 22), 300)],
      );
      expect(bars, hasLength(12));
      expect(bars.first.label, 'Jan');
      expect(bars.first.expense, 100);
      expect(bars.last.expense, 300);
      expect(bars[5].expense, 0);
    });

    test('Mingguan: 7 hari Sen–Min termasuk hari kosong', () {
      final bars = trendBuckets(
        PeriodSelection(
          type: PeriodType.weekly,
          anchor: DateTime(2026, 10, 7), // Rabu
        ),
        [tx(DateTime(2026, 10, 5), 100), tx(DateTime(2026, 10, 11), 200)],
      );
      expect(bars.map((b) => b.label), [
        'Sen',
        'Sel',
        'Rab',
        'Kam',
        'Jum',
        'Sab',
        'Min',
      ]);
      expect(bars.first.expense, 100);
      expect(bars.last.expense, 200);
      expect(bars[2].expense, 0);
    });

    test('Harian: satu kelompok untuk hari itu', () {
      final bars = trendBuckets(
        PeriodSelection(type: PeriodType.daily, anchor: DateTime(2026, 10, 7)),
        [
          tx(DateTime(2026, 10, 7, 8), 100),
          tx(DateTime(2026, 10, 7, 20), 50, income: true),
        ],
      );
      expect(bars, hasLength(1));
      expect(bars.single.expense, 100);
      expect(bars.single.income, 50);
    });
  });

  test('chart kosong saat tidak ada pengeluaran di periode', () async {
    final container = await makeContainer();
    useMonthOf(container, DateTime(2026, 9, 15));

    expect(container.read(categorySlicesProvider), isEmpty);
    expect(container.read(barChartProvider), isEmpty);
  });
}
