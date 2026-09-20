import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/custom_category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_import.dart';
import '../../domain/repositories/category_repository.dart';

final customCategoryLocalDataSourceProvider =
    Provider<CustomCategoryLocalDataSource>((ref) {
      return CustomCategoryLocalDataSourceImpl(
        ref.watch(sharedPreferencesProvider),
      );
    });

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    ref.watch(customCategoryLocalDataSourceProvider),
  );
});

/// Memuat kategori tambahan dari file impor dan menyegarkan pemilih kategori.
class CustomCategoriesNotifier extends Notifier<List<Category>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  List<Category> build() => _repo.getCustomCategories();

  Future<void> addImported(Iterable<CategoryImport> categories) async {
    state = await _repo.addImportedCategories(categories);
  }
}

final customCategoriesProvider =
    NotifierProvider<CustomCategoriesNotifier, List<Category>>(
      CustomCategoriesNotifier.new,
    );

/// Daftar kategori sesuai jenis transaksi (pemasukan/pengeluaran).
final categoriesByTypeProvider =
    Provider.family<List<Category>, TransactionType>((ref, type) {
      ref.watch(customCategoriesProvider);
      return ref.watch(categoryRepositoryProvider).getCategories(type: type);
    });

/// Cari kategori berdasarkan id (mis. untuk menampilkan ikon di daftar transaksi).
final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  ref.watch(customCategoriesProvider);
  return ref.watch(categoryRepositoryProvider).findById(id);
});
