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
import 'package:dilrecordmoney/features/transactions/presentation/providers/period_providers.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    AppStrings.use(AppLocale.id);
    expect(container.read(categorySlicesProvider).last.category.name, 'Lainnya');

    AppStrings.use(AppLocale.en);
    container.invalidate(categorySlicesProvider);
    expect(container.read(categorySlicesProvider).last.category.name, 'Other');

    AppStrings.use(AppLocale.ja);
    container.invalidate(categorySlicesProvider);
    expect(
      container.read(categorySlicesProvider).last.category.name,
      'その他',
    );
  });

  test('bar chart: satu batang per hari, maksimal 7 hari terakhir', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);

    // 9 hari berbeda di bulan yang sama → hanya 7 terakhir yang dipakai.
    for (var day = 1; day <= 9; day++) {
      await notifier.addTransaction(
        expenseOn(DateTime(2026, 9, day), 1000 * day, 'exp_food'),
      );
    }
    useMonthOf(container, DateTime(2026, 9, 15));

    final bars = container.read(barChartProvider);
    expect(bars, hasLength(7));
    expect(bars.first.label, '03/09'); // hari ke-3 s.d. ke-9
    expect(bars.last.label, '09/09');
    expect(bars.last.expense, 9000);
    expect(bars.last.income, 0);
  });

  test('chart kosong saat tidak ada pengeluaran di periode', () async {
    final container = await makeContainer();
    useMonthOf(container, DateTime(2026, 9, 15));

    expect(container.read(categorySlicesProvider), isEmpty);
    expect(container.read(barChartProvider), isEmpty);
  });
}
