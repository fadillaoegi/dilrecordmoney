import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/datasources/budget_local_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

// ── Dependency wiring ────────────────────────────────────────────────────────

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  return BudgetLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(budgetLocalDataSourceProvider));
});

// ── Bulan aktif untuk halaman anggaran ───────────────────────────────────────

class BudgetMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void next() => state = DateTime(state.year, state.month + 1);

  void previous() => state = DateTime(state.year, state.month - 1);
}

final budgetMonthProvider =
    NotifierProvider<BudgetMonthNotifier, DateTime>(BudgetMonthNotifier.new);

// ── Daftar anggaran untuk bulan aktif ────────────────────────────────────────

class MonthlyBudgetsNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    final month = ref.watch(budgetMonthProvider);
    return ref
        .read(budgetRepositoryProvider)
        .getBudgetsForMonth(month.year, month.month);
  }

  Future<void> setBudget(String categoryId, int limit) async {
    final month = ref.read(budgetMonthProvider);
    final repo = ref.read(budgetRepositoryProvider);
    await repo.setBudget(
      categoryId: categoryId,
      year: month.year,
      month: month.month,
      limit: limit,
    );
    state = repo.getBudgetsForMonth(month.year, month.month);
  }
}

final monthlyBudgetsProvider =
    NotifierProvider<MonthlyBudgetsNotifier, List<Budget>>(
  MonthlyBudgetsNotifier.new,
);

/// Peta {categoryId → total pengeluaran} untuk bulan aktif.
final monthlySpendingProvider = Provider<Map<String, int>>((ref) {
  final month = ref.watch(budgetMonthProvider);
  final all = ref.watch(transactionListProvider).asData?.value ?? const [];
  final map = <String, int>{};
  for (final t in all) {
    if (t.type.isExpense &&
        t.date.year == month.year &&
        t.date.month == month.month) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
  }
  return map;
});

/// Total anggaran vs total terpakai (pada kategori yang dianggarkan).
final budgetSummaryProvider = Provider<({int totalBudget, int totalSpent})>((ref) {
  final budgets = ref.watch(monthlyBudgetsProvider);
  final spending = ref.watch(monthlySpendingProvider);
  final totalBudget = budgets.fold<int>(0, (s, b) => s + b.limit);
  final totalSpent =
      budgets.fold<int>(0, (s, b) => s + (spending[b.categoryId] ?? 0));
  return (totalBudget: totalBudget, totalSpent: totalSpent);
});
