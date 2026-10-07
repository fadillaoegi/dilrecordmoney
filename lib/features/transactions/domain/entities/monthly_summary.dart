import 'package:flutter/foundation.dart';

import 'money_transaction.dart';
import 'transaction_summary.dart';

/// Ringkasan satu bulan kalender — dipakai daftar 12 bulan di tab Tahunan.
@immutable
class MonthlySummary {
  const MonthlySummary({required this.month, required this.summary});

  /// Tanggal 1 bulan tersebut.
  final DateTime month;
  final TransactionSummary summary;

  bool get isEmpty => summary.count == 0;

  /// Selalu 12 entri (Jan–Des [year]); bulan tanpa transaksi bernilai nol.
  static List<MonthlySummary> forYear(
    int year,
    Iterable<MoneyTransaction> transactions,
  ) {
    final income = List.filled(12, 0);
    final expense = List.filled(12, 0);
    final count = List.filled(12, 0);
    for (final t in transactions) {
      if (t.date.year != year) continue;
      final i = t.date.month - 1;
      count[i]++;
      if (t.type.isIncome) {
        income[i] += t.amount;
      } else {
        expense[i] += t.amount;
      }
    }
    return [
      for (var i = 0; i < 12; i++)
        MonthlySummary(
          month: DateTime(year, i + 1),
          summary: TransactionSummary(
            totalIncome: income[i],
            totalExpense: expense[i],
            count: count[i],
          ),
        ),
    ];
  }
}
