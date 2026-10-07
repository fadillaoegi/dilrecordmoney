import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/l10n/app_locale.dart';
import 'package:dilrecordmoney/core/l10n/app_strings.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/currency_formatter.dart';
import 'package:dilrecordmoney/features/home/presentation/pages/charts_page.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:dilrecordmoney/core/theme/chart_palette.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => AppStrings.use(AppLocale.id));

  test('format ringkas untuk sumbu grafik', () {
    expect(CurrencyFormatter.compact(0), '0');
    expect(CurrencyFormatter.compact(850), '850');
    expect(CurrencyFormatter.compact(850000), '850rb');
    expect(CurrencyFormatter.compact(1250000), '1,3jt');
    expect(CurrencyFormatter.compact(2000000), '2jt');
    expect(CurrencyFormatter.compact(15000000), '15jt');
    AppStrings.use(AppLocale.en);
    expect(CurrencyFormatter.compact(1500), '1,5K');
  });

  for (final size in const [Size(390, 1400), Size(320, 1400)]) {
    testWidgets('halaman grafik tampil rapi di lebar ${size.width}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      MoneyTransaction tx(int i, TransactionType type, int amount, String c) =>
          MoneyTransaction(
            id: 't$i',
            type: type,
            amount: amount,
            categoryId: c,
            walletId: 'cash',
            date: DateTime(now.year, now.month, 1 + i % 7),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            transactionRepositoryProvider.overrideWithValue(
              _FakeRepo([
                tx(0, TransactionType.income, 8500000, 'inc_salary'),
                tx(1, TransactionType.expense, 1250000, 'exp_food'),
                tx(2, TransactionType.expense, 350000, 'exp_bills'),
                tx(3, TransactionType.expense, 42000, 'exp_transport'),
                tx(4, TransactionType.expense, 2000, 'exp_health'),
                tx(5, TransactionType.expense, 229000, 'exp_shopping'),
                tx(6, TransactionType.expense, 999999999, 'exp_other'),
              ]),
            ),
          ],
          child: const MaterialApp(home: ChartsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DISTRIBUSI PENGELUARAN'), findsOneWidget);
      expect(find.text('Makan & Minum'), findsOneWidget);
      expect(find.text('<1%'), findsWidgets);

      // Pie: satu irisan per kategori, warna mengikuti urutan palet tetap.
      PieChartData pie() =>
          tester.widget<PieChart>(find.byKey(const Key('expense-pie'))).data;
      expect(pie().sections, hasLength(6));
      for (var i = 0; i < 6; i++) {
        expect(pie().sections[i].color, ChartPalette.series(i));
      }
      expect(pie().sections.map((x) => x.radius).toSet(), {96});

      // Tab Tahunan: 12 kelompok batang, tidak overflow di layar sempit.
      await tester.tap(find.text('TAHUNAN'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bar = tester.widget<BarChart>(find.byType(BarChart));
      expect(bar.data.barGroups, hasLength(12));
      final rodWidth = bar.data.barGroups.first.barRods.first.width;
      final plotWidth = size.width - 2 * 16 - 2 * 16 - 40;
      expect((rodWidth * 2 + 3) * 12, lessThan(plotWidth));
      await tester.tap(find.text('BULANAN'));
      await tester.pumpAndSettle();

      // Ketuk baris legenda teratas → irisan pertama disorot.
      await tester.tap(find.text('Lainnya').first);
      await tester.pumpAndSettle();
      expect(pie().sections.first.radius, 104);
    });
  }
}

class _FakeRepo implements TransactionRepository {
  _FakeRepo(this._items);

  final List<MoneyTransaction> _items;

  @override
  Future<List<MoneyTransaction>> getTransactions() async => _items;

  @override
  Future<void> add(MoneyTransaction transaction) async {}

  @override
  Future<int> addAll(List<MoneyTransaction> transactions) async => 0;

  @override
  Future<void> update(MoneyTransaction transaction) async {}

  @override
  Future<void> delete(String id) async {}
}
