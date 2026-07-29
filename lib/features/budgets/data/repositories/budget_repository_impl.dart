import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._local);

  final BudgetLocalDataSource _local;

  @override
  List<Budget> getBudgetsForMonth(int year, int month) {
    return _local.readAll().where((b) => b.isForMonth(year, month)).toList();
  }

  @override
  Future<void> setBudget({
    required String categoryId,
    required int year,
    required int month,
    required int limit,
  }) async {
    final items = _local.readAll();
    final index = items.indexWhere(
      (b) => b.categoryId == categoryId && b.isForMonth(year, month),
    );

    if (limit <= 0) {
      // Batas 0/negatif = hapus anggaran.
      if (index != -1) {
        items.removeAt(index);
        await _local.writeAll(items);
      }
      return;
    }

    if (index == -1) {
      items.add(
        BudgetModel(
          id: IdGenerator.generate(),
          categoryId: categoryId,
          year: year,
          month: month,
          limit: limit,
        ),
      );
    } else {
      items[index] = BudgetModel.fromEntity(
        items[index].copyWith(limit: limit),
      );
    }
    await _local.writeAll(items);
  }

  @override
  Future<void> removeBudget({
    required String categoryId,
    required int year,
    required int month,
  }) async {
    final items = _local.readAll()
      ..removeWhere(
        (b) => b.categoryId == categoryId && b.isForMonth(year, month),
      );
    await _local.writeAll(items);
  }
}
