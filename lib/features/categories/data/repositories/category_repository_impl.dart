import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../datasources/custom_category_local_datasource.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_import.dart';
import '../../domain/repositories/category_repository.dart';
import '../category_catalog.dart';

/// Implementasi [CategoryRepository] berbasis preset [CategoryCatalog].
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._customLocal);

  final CustomCategoryLocalDataSource _customLocal;

  @override
  List<Category> getCategories({TransactionType? type}) {
    final preset = switch (type) {
      TransactionType.expense => CategoryCatalog.expense,
      TransactionType.income => CategoryCatalog.income,
      null => CategoryCatalog.all,
    };
    final custom = getCustomCategories().where(
      (category) => type == null || category.type == type,
    );
    return [...preset, ...custom];
  }

  @override
  Category? findById(String id) {
    for (final category in getCategories()) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Category fallbackFor(TransactionType type) {
    final id = type.isExpense
        ? CategoryCatalog.expenseFallbackId
        : CategoryCatalog.incomeFallbackId;
    return findById(id)!;
  }

  @override
  List<Category> getCustomCategories() {
    return _customLocal.readAll().map(_toCategory).toList();
  }

  @override
  Future<List<Category>> addImportedCategories(
    Iterable<CategoryImport> categories,
  ) async {
    final stored = _customLocal.readAll();
    final known = <String>{
      for (final category in CategoryCatalog.all)
        _identity(category.name, category.type),
      for (final category in stored) _identity(category.name, category.type),
    };

    var changed = false;
    for (final category in categories) {
      final name = category.name.trim();
      final key = _identity(name, category.type);
      if (name.isEmpty || !known.add(key)) continue;
      stored.add(CategoryImport(name: name, type: category.type));
      changed = true;
    }
    if (changed) await _customLocal.writeAll(stored);
    return getCustomCategories();
  }

  Category _toCategory(CategoryImport source) {
    return Category(
      id: source.id,
      name: source.name,
      icon: Icons.label_rounded,
      color: source.type.isIncome ? AppColors.primary : AppColors.secondary,
      type: source.type,
    );
  }

  String _identity(String name, TransactionType type) =>
      '${type.key}:${name.trim().toLowerCase()}';
}
