import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/enums/period_type.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/period_selection.dart';
import '../../../transactions/presentation/providers/period_providers.dart';

/// Satu segmen donut chart: kategori + total pengeluaran + warna.
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.total,
    required this.percentage,
  });

  final Category category;
  final int total;
  final double percentage;
}

/// Data donut chart: pengeluaran per kategori dalam periode aktif.
final categorySlicesProvider = Provider<List<CategorySlice>>((ref) {
  ref.watch(appearanceProvider);
  final transactions = ref.watch(filteredTransactionsProvider);
  final expenseTransactions = transactions
      .where((t) => t.type.isExpense)
      .toList();

  if (expenseTransactions.isEmpty) return [];

  // Agregasi per categoryId
  final totals = <String, int>{};
  for (final t in expenseTransactions) {
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
  }

  final grandTotal = totals.values.fold(0, (a, b) => a + b);
  if (grandTotal == 0) return [];

  // Sort by amount descending, ambil top 6 + gabung sisanya ke "Lainnya"
  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = sorted.take(6).toList();
  final rest = sorted.skip(6).toList();

  final slices = <CategorySlice>[];
  for (final entry in top) {
    final cat = ref.read(categoryByIdProvider(entry.key));
    if (cat == null) continue;
    slices.add(
      CategorySlice(
        category: cat,
        total: entry.value,
        percentage: entry.value / grandTotal * 100,
      ),
    );
  }

  // "Lainnya" jika ada lebih dari 6 kategori — disamakan dengan kategori
  // "Lainnya" bawaan di katalog (nama ikut bahasa, warna ikut palet).
  if (rest.isNotEmpty) {
    final restTotal = rest.fold<int>(0, (s, e) => s + e.value);
    slices.add(
      CategorySlice(
        category: Category(
          id: '__other__',
          name: AppStrings.t.catOther,
          icon: Icons.more_horiz_rounded,
          color: AppColors.muted,
          type: TransactionType.expense,
        ),
        total: restTotal,
        percentage: restTotal / grandTotal * 100,
      ),
    );
  }

  return slices;
});

/// Satu kelompok batang: total pemasukan & pengeluaran dalam satu rentang
/// (hari / minggu / bulan, tergantung jenis periode).
class BarEntry {
  const BarEntry({
    required this.label,
    required this.tooltipLabel,
    required this.income,
    required this.expense,
  });

  /// Label ringkas di sumbu X (mis. "Sen", "8–14", "Jan").
  final String label;

  /// Label lengkap untuk tooltip (mis. "8–14 Okt 2026").
  final String tooltipLabel;
  final int income;
  final int expense;
}

/// Tren pemasukan vs pengeluaran yang mencakup **seluruh** periode aktif,
/// dipecah sesuai jenis periode. Rentang tanpa transaksi tetap ada (nol),
/// sehingga jumlah semua batang = ringkasan periode di beranda.
///
/// (Dulu: hanya "7 hari terakhir yang ada transaksinya" — total tidak cocok
/// dengan periode, hari kosong terlewat, dan tab Tahunan cuma 7 hari.)
final barChartProvider = Provider<List<BarEntry>>((ref) {
  ref.watch(appearanceProvider); // label hari/bulan ikut bahasa
  return trendBuckets(
    ref.watch(periodSelectionProvider),
    ref.watch(filteredTransactionsProvider),
  );
});

/// Fungsi murni di balik [barChartProvider] — mudah diuji.
List<BarEntry> trendBuckets(
  PeriodSelection period,
  List<MoneyTransaction> transactions,
) {
  if (transactions.isEmpty) return const [];
  final t = AppStrings.t;
  final ranges = <(String, String, DateTime, DateTime)>[];

  switch (period.type) {
    case PeriodType.daily:
      ranges.add((
        DateFormatter.short(period.start),
        DateFormatter.withDay(period.start),
        period.start,
        period.end,
      ));
    case PeriodType.weekly:
      for (var i = 0; i < 7; i++) {
        final day = DateTime(
          period.start.year,
          period.start.month,
          period.start.day + i,
        );
        ranges.add((
          t.days[day.weekday - 1],
          DateFormatter.withDay(day),
          day,
          DateTime(day.year, day.month, day.day + 1),
        ));
      }
    case PeriodType.monthly:
      final first = period.start;
      final lastDay = period.lastDay.day;
      for (var from = 1; from <= lastDay; from += 7) {
        final to = from + 6 > lastDay ? lastDay : from + 6;
        final label = from == to ? '$from' : '$from–$to';
        ranges.add((
          label,
          '$label ${t.months[first.month - 1]} ${first.year}',
          DateTime(first.year, first.month, from),
          DateTime(first.year, first.month, to + 1),
        ));
      }
    case PeriodType.yearly:
      final year = period.start.year;
      for (var m = 1; m <= 12; m++) {
        ranges.add((
          t.months[m - 1],
          '${t.monthsFull[m - 1]} $year',
          DateTime(year, m),
          DateTime(year, m + 1),
        ));
      }
  }

  return [
    for (final (label, tooltip, from, until) in ranges)
      () {
        var income = 0;
        var expense = 0;
        for (final tx in transactions) {
          if (tx.date.isBefore(from) || !tx.date.isBefore(until)) continue;
          if (tx.type.isIncome) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
        return BarEntry(
          label: label,
          tooltipLabel: tooltip,
          income: income,
          expense: expense,
        );
      }(),
  ];
}
