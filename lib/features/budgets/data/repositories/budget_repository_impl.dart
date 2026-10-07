import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_datasource.dart';
import '../models/budget_model.dart';

/// Anggaran **berlanjut ke bulan-bulan berikutnya**.
///
/// Yang disimpan hanyalah titik perubahan: "mulai bulan M, batas kategori K
/// = X". Anggaran efektif sebuah bulan = titik perubahan terakhir pada/
/// sebelum bulan itu. Jadi set Transport 300.000 di Oktober → November dst.
/// ikut 300.000 **sampai ada pembaruan berikutnya**, sedangkan September
/// dan sebelumnya tetap nilai lamanya. Titik dengan batas 0 berarti
/// "anggaran berhenti mulai bulan ini".
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._local);

  final BudgetLocalDataSource _local;

  static int _key(int year, int month) => year * 12 + (month - 1);

  @override
  List<Budget> getBudgetsForMonth(int year, int month) {
    final target = _key(year, month);
    final latest = <String, BudgetModel>{};
    for (final b in _local.readAll()) {
      if (_key(b.year, b.month) > target) continue;
      final current = latest[b.categoryId];
      if (current == null ||
          _key(b.year, b.month) > _key(current.year, current.month)) {
        latest[b.categoryId] = b;
      }
    }
    return [
      for (final b in latest.values)
        if (b.limit > 0)
          // Diberi bulan yang diminta supaya pemakai (mis. pengecek batas)
          // bisa mencocokkan dengan `isForMonth` seperti biasa.
          Budget(
            id: b.id,
            categoryId: b.categoryId,
            year: year,
            month: month,
            limit: b.limit,
          ),
    ];
  }

  @override
  Future<void> setBudget({
    required String categoryId,
    required int year,
    required int month,
    required int limit,
  }) async {
    final from = _key(year, month);
    // Hanya titik perubahan bulan ini yang diganti. Pembaruan di bulan-bulan
    // sesudahnya (bila ada) tetap berlaku — nilai bulan ini terbawa sampai
    // pembaruan berikutnya itu.
    final items = _local.readAll()
      ..removeWhere(
        (b) => b.categoryId == categoryId && _key(b.year, b.month) == from,
      );

    final inherited = _effectiveLimit(items, categoryId, from);
    final value = limit <= 0 ? 0 : limit;
    // Tidak perlu titik baru bila nilainya sama dengan yang sudah terbawa
    // (termasuk "hapus" saat memang tidak ada anggaran sebelumnya).
    if (value != inherited) {
      items.add(
        BudgetModel(
          id: IdGenerator.generate(),
          categoryId: categoryId,
          year: year,
          month: month,
          limit: value,
        ),
      );
    }
    await _local.writeAll(items);
  }

  @override
  Future<void> removeBudget({
    required String categoryId,
    required int year,
    required int month,
  }) {
    return setBudget(
      categoryId: categoryId,
      year: year,
      month: month,
      limit: 0,
    );
  }

  /// Batas yang berlaku untuk kategori pada bulan [key] dari [items]
  /// (0 bila tidak ada).
  int _effectiveLimit(List<BudgetModel> items, String categoryId, int key) {
    BudgetModel? latest;
    for (final b in items) {
      if (b.categoryId != categoryId || _key(b.year, b.month) > key) continue;
      if (latest == null ||
          _key(b.year, b.month) > _key(latest.year, latest.month)) {
        latest = b;
      }
    }
    return latest?.limit ?? 0;
  }
}
