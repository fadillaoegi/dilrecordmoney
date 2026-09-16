// Menguji penyaringan transaksi & ringkasan berdasarkan periode aktif.

import 'package:dilrecordmoney/core/enums/period_type.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/period_providers.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  MoneyTransaction expenseOn(DateTime date, int amount) => MoneyTransaction(
    id: IdGenerator.generate(),
    type: TransactionType.expense,
    amount: amount,
    categoryId: 'exp_food',
    walletId: 'cash',
    date: date,
  );

  test('periode bulanan hanya mencakup transaksi bulan jangkar', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);

    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 10), 10000));
    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 25), 5000));
    await notifier.addTransaction(
      expenseOn(DateTime(2026, 6, 30), 99000),
    ); // bulan lain

    // Set periode ke bulanan dengan jangkar Juli 2026.
    container
        .read(periodSelectionProvider.notifier)
        .setType(PeriodType.monthly);
    // setType mereset jangkar ke sekarang; geser manual bukan jaminan → set langsung.
    container.read(periodSelectionProvider.notifier).state = container
        .read(periodSelectionProvider)
        .copyWith(anchor: DateTime(2026, 7, 15));

    final filtered = container.read(filteredTransactionsProvider);
    expect(filtered, hasLength(2));

    final summary = container.read(filteredSummaryProvider);
    expect(summary.totalExpense, 15000);
  });

  test('periode harian hanya mencakup satu hari', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);

    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 15, 9), 8000));
    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 15, 20), 2000));
    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 16, 1), 500));

    container.read(periodSelectionProvider.notifier).state = container
        .read(periodSelectionProvider)
        .copyWith(type: PeriodType.daily, anchor: DateTime(2026, 7, 15));

    final filtered = container.read(filteredTransactionsProvider);
    expect(filtered, hasLength(2));
    expect(container.read(filteredSummaryProvider).totalExpense, 10000);
  });

  test('saldo bulan berjalan ikut membawa sisa saldo bulan sebelumnya', () async {
    final container = await makeContainer();
    final notifier = container.read(transactionListProvider.notifier);

    // Juni: pemasukan 100rb, pengeluaran 40rb → sisa 60rb.
    await notifier.addTransaction(expenseOn(DateTime(2026, 6, 5), 40000));
    await notifier.addTransaction(
      MoneyTransaction(
        id: IdGenerator.generate(),
        type: TransactionType.income,
        amount: 100000,
        categoryId: 'inc_salary',
        walletId: 'cash',
        date: DateTime(2026, 6, 1),
      ),
    );
    // Juli: pengeluaran 15rb saja.
    await notifier.addTransaction(expenseOn(DateTime(2026, 7, 10), 15000));

    container.read(periodSelectionProvider.notifier).state = container
        .read(periodSelectionProvider)
        .copyWith(type: PeriodType.monthly, anchor: DateTime(2026, 7, 15));

    // Saldo periode Juli saja = -15rb, tapi saldo total harus ikut sisa
    // Juni (60rb) sehingga jadi 60rb - 15rb = 45rb, bukan reset ke -15rb.
    expect(container.read(filteredSummaryProvider).balance, -15000);
    expect(container.read(runningBalanceProvider), 45000);
  });

  test('groupByDay mengelompokkan transaksi per tanggal dengan total benar', () {
    final senin = expenseOn(DateTime(2026, 9, 14, 9), 5000);
    final senin2 = expenseOn(DateTime(2026, 9, 14, 19), 4000);
    final senin3 = expenseOn(DateTime(2026, 9, 14, 20), 2000);
    final selasa = expenseOn(DateTime(2026, 9, 15, 8), 3000);

    // Input terurut terbaru dulu, seperti hasil filteredTransactionsProvider.
    final groups = groupByDay([selasa, senin3, senin2, senin]);

    expect(groups, hasLength(2));
    expect(groups[0].date, DateTime(2026, 9, 15));
    expect(groups[0].totalExpense, 3000);
    expect(groups[1].date, DateTime(2026, 9, 14));
    expect(groups[1].transactions, hasLength(3));
    expect(groups[1].totalExpense, 11000);
    expect(groups[1].totalIncome, 0);
  });
}
