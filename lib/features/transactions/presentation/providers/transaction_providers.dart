import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/transaction_summary.dart';
import '../../domain/repositories/transaction_repository.dart';

// ── Dependency wiring (data → domain) ────────────────────────────────────────

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>(
  (ref) {
    return TransactionLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
  },
);

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(transactionLocalDataSourceProvider),
  );
});

// ── State daftar transaksi (sumber kebenaran untuk UI) ───────────────────────

/// Mengelola daftar transaksi: memuat, menambah, mengubah, menghapus.
class TransactionListNotifier extends AsyncNotifier<List<MoneyTransaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  @override
  Future<List<MoneyTransaction>> build() => _repo.getTransactions();

  Future<void> addTransaction(MoneyTransaction transaction) async {
    await _repo.add(transaction);
    state = AsyncData(await _repo.getTransactions());
  }

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    await _repo.update(transaction);
    state = AsyncData(await _repo.getTransactions());
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.getTransactions());
  }
}

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<MoneyTransaction>>(
      TransactionListNotifier.new,
    );

// ── Turunan (derived) ────────────────────────────────────────────────────────

/// Ringkasan total (income/expense/saldo) dari seluruh transaksi termuat.
final transactionSummaryProvider = Provider<TransactionSummary>((ref) {
  final transactions =
      ref.watch(transactionListProvider).asData?.value ?? const [];
  var income = 0;
  var expense = 0;
  for (final t in transactions) {
    if (t.type.isIncome) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }
  return TransactionSummary(
    totalIncome: income,
    totalExpense: expense,
    count: transactions.length,
  );
});
