import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../category_catalog.dart';

/// Implementasi [CategoryRepository] berbasis preset [CategoryCatalog].
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl();

  @override
  List<Category> getCategories({TransactionType? type}) {
    return switch (type) {
      TransactionType.expense => CategoryCatalog.expense,
      TransactionType.income => CategoryCatalog.income,
      null => CategoryCatalog.all,
    };
  }

  @override
  Category? findById(String id) {
    for (final category in CategoryCatalog.all) {
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
}
