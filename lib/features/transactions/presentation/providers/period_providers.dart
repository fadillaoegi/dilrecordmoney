import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/period_type.dart';
import '../../domain/entities/daily_transaction_group.dart';
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

/// Saldo total sampai akhir periode aktif (kumulatif sejak transaksi pertama).
///
/// Beda dengan [filteredSummaryProvider] yang hanya menghitung periode ini
/// saja — saldo di sini ikut membawa sisa saldo dari periode-periode
/// sebelumnya, sehingga saat ganti bulan (atau minggu/hari) saldo tidak
/// reset ke nol melainkan otomatis mengikut ke periode berikutnya.
final runningBalanceProvider = Provider<int>((ref) {
  final all = ref.watch(transactionListProvider).asData?.value ?? const [];
  final period = ref.watch(periodSelectionProvider);
  var balance = 0;
  for (final t in all) {
    if (t.date.isBefore(period.end)) balance += t.signedAmount;
  }
  return balance;
});

// ── Pengelompokan per hari ───────────────────────────────────────────────────

/// Mengelompokkan [transactions] per hari kalender.
///
/// Mengasumsikan [transactions] sudah terurut terbaru dulu — urutan
/// kelompok yang dihasilkan mengikuti urutan kemunculan harinya.
List<DailyTransactionGroup> groupByDay(List<MoneyTransaction> transactions) {
  final order = <DateTime>[];
  final buckets = <DateTime, List<MoneyTransaction>>{};
  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final bucket = buckets.putIfAbsent(day, () {
      order.add(day);
      return [];
    });
    bucket.add(t);
  }

  return [
    for (final day in order)
      DailyTransactionGroup(
        date: day,
        transactions: buckets[day]!,
        totalIncome: buckets[day]!
            .where((t) => t.type.isIncome)
            .fold(0, (sum, t) => sum + t.amount),
        totalExpense: buckets[day]!
            .where((t) => t.type.isExpense)
            .fold(0, (sum, t) => sum + t.amount),
      ),
  ];
}

/// Transaksi periode aktif, dikelompokkan per hari (untuk beranda).
final dailyGroupedTransactionsProvider = Provider<List<DailyTransactionGroup>>((
  ref,
) {
  return groupByDay(ref.watch(filteredTransactionsProvider));
});
