import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
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

/// Satu batang bar chart: total pemasukan & pengeluaran pada satu hari.
class BarEntry {
  const BarEntry({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;
}

/// Income vs expense per hari — maksimal 7 hari terakhir yang ada transaksinya
/// di dalam periode aktif.
final barChartProvider = Provider<List<BarEntry>>((ref) {
  final all = ref.watch(filteredTransactionsProvider);
  if (all.isEmpty) return [];

  // Pakai semua transaksi terfilter, kelompokkan per hari dalam periode aktif
  final byDay = <String, _DayBucket>{};

  for (final t in all) {
    final key =
        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
    final bucket = byDay.putIfAbsent(key, () => _DayBucket(t.date));
    if (t.type.isIncome) {
      bucket.income += t.amount;
    } else {
      bucket.expense += t.amount;
    }
  }

  // Sort by date, ambil 7 hari terakhir (atau semua jika < 7)
  final sorted = byDay.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final relevant = sorted.length > 7
      ? sorted.sublist(sorted.length - 7)
      : sorted;

  return relevant.map((b) {
    final d = b.date;
    final label =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return BarEntry(label: label, income: b.income, expense: b.expense);
  }).toList();
});

class _DayBucket {
  _DayBucket(this.date);
  final DateTime date;
  int income = 0;
  int expense = 0;
}
