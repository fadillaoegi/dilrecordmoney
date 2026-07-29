import 'package:flutter/foundation.dart';

/// Ringkasan agregat transaksi untuk suatu periode (hari/minggu/bulan/tahun).
@immutable
class TransactionSummary {
  const TransactionSummary({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.count = 0,
  });

  final int totalIncome;
  final int totalExpense;
  final int count;

  /// Saldo bersih periode ini (pemasukan − pengeluaran).
  int get balance => totalIncome - totalExpense;
}
