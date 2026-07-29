// Menguji repository anggaran & provider ringkasan/pengeluaran per bulan.

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:dilrecordmoney/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:dilrecordmoney/features/budgets/presentation/providers/budget_providers.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BudgetRepository', () {
    late BudgetRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = BudgetRepositoryImpl(BudgetLocalDataSourceImpl(prefs));
    });

    test('set lalu ambil anggaran untuk bulan tertentu', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );

      final budgets = repo.getBudgetsForMonth(2026, 7);
      expect(budgets, hasLength(1));
      expect(budgets.first.limit, 500000);
      expect(repo.getBudgetsForMonth(2026, 8), isEmpty);
    });

    test('set ulang kategori sama memperbarui (bukan menduplikasi)', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 750000,
      );

      final budgets = repo.getBudgetsForMonth(2026, 7);
      expect(budgets, hasLength(1));
      expect(budgets.first.limit, 750000);
    });

    test('limit 0 menghapus anggaran', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 0,
      );

      expect(repo.getBudgetsForMonth(2026, 7), isEmpty);
    });
  });

  test('spending & summary provider menghitung terpakai vs anggaran', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Anggaran Makan Juli 2026 = 100.000
    container.read(budgetMonthProvider.notifier).state = DateTime(2026, 7);
    await container
        .read(monthlyBudgetsProvider.notifier)
        .setBudget('exp_food', 100000);

    // Dua pengeluaran Makan di Juli, satu di bulan lain (tidak dihitung).
    final txNotifier = container.read(transactionListProvider.notifier);
    await txNotifier.addTransaction(_food(DateTime(2026, 7, 5), 30000));
    await txNotifier.addTransaction(_food(DateTime(2026, 7, 20), 40000));
    await txNotifier.addTransaction(_food(DateTime(2026, 8, 1), 99000));

    final spending = container.read(monthlySpendingProvider);
    expect(spending['exp_food'], 70000);

    final summary = container.read(budgetSummaryProvider);
    expect(summary.totalBudget, 100000);
    expect(summary.totalSpent, 70000);
  });
}

MoneyTransaction _food(DateTime date, int amount) => MoneyTransaction(
  id: IdGenerator.generate(),
  type: TransactionType.expense,
  amount: amount,
  categoryId: 'exp_food',
  walletId: 'cash',
  date: date,
);
