import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/period_type.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/period_selection.dart';
import '../../domain/entities/transaction_summary.dart';
import 'transaction_providers.dart';

/// Periode aktif di beranda (default: bulan ini).
class PeriodSelectionNotifier extends Notifier<PeriodSelection> {
  @override
  PeriodSelection build() =>
      PeriodSelection(type: PeriodType.monthly, anchor: DateTime.now());

  /// Ganti jenis periode; jangkar direset ke hari ini agar tak membingungkan.
  void setType(PeriodType type) {
    state = PeriodSelection(type: type, anchor: DateTime.now());
  }

  void next() => state = state.shift(1);

  void previous() => state = state.shift(-1);
}

final periodSelectionProvider =
    NotifierProvider<PeriodSelectionNotifier, PeriodSelection>(
      PeriodSelectionNotifier.new,
    );

/// Transaksi yang jatuh dalam periode aktif.
final filteredTransactionsProvider = Provider<List<MoneyTransaction>>((ref) {
  final all = ref.watch(transactionListProvider).asData?.value ?? const [];
  final period = ref.watch(periodSelectionProvider);
  return all.where((t) => period.contains(t.date)).toList();
});

/// Ringkasan (income/expense/saldo) untuk periode aktif.
final filteredSummaryProvider = Provider<TransactionSummary>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
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
