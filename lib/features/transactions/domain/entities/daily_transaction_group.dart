import 'package:flutter/foundation.dart';

import 'money_transaction.dart';

/// Kumpulan transaksi dalam satu hari kalender, lengkap dengan total harinya.
///
/// Dipakai untuk menampilkan daftar transaksi beranda terkelompok per hari
/// (mis. "Senin: 5.000, 4.000, 2.000 — total pengeluaran Rp11.000").
@immutable
class DailyTransactionGroup {
  const DailyTransactionGroup({
    required this.date,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  /// Tanggal (tanpa komponen jam) yang mewakili hari ini.
  final DateTime date;

  /// Transaksi hari ini, urutannya mengikuti urutan input (terbaru dulu).
  final List<MoneyTransaction> transactions;

  final int totalIncome;
  final int totalExpense;
}
