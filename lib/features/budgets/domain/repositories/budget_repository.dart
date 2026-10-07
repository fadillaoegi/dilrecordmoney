import '../entities/budget.dart';

/// Kontrak penyimpanan anggaran bulanan.
abstract interface class BudgetRepository {
  /// Anggaran yang **berlaku** pada bulan tertentu — termasuk yang terbawa
  /// dari bulan-bulan sebelumnya.
  List<Budget> getBudgetsForMonth(int year, int month);

  /// Menetapkan anggaran sebuah kategori mulai bulan ini; bulan-bulan
  /// sesudahnya ikut nilai ini sampai ada pembaruan berikutnya. Bulan-bulan
  /// sebelumnya tidak berubah. Bila [limit] ≤ 0, anggaran berhenti mulai
  /// bulan ini (sampai di-set lagi).
  Future<void> setBudget({
    required String categoryId,
    required int year,
    required int month,
    required int limit,
  });

  /// Sama dengan [setBudget] dengan batas 0.
  Future<void> removeBudget({
    required String categoryId,
    required int year,
    required int month,
  });
}
