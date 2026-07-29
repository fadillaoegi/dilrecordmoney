import '../entities/budget.dart';

/// Kontrak penyimpanan anggaran bulanan.
abstract interface class BudgetRepository {
  /// Semua anggaran pada bulan tertentu.
  List<Budget> getBudgetsForMonth(int year, int month);

  /// Menetapkan/memperbarui anggaran sebuah kategori untuk satu bulan.
  /// Bila [limit] ≤ 0, anggaran kategori tersebut dihapus.
  Future<void> setBudget({
    required String categoryId,
    required int year,
    required int month,
    required int limit,
  });

  Future<void> removeBudget({
    required String categoryId,
    required int year,
    required int month,
  });
}
