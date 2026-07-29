import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return const CategoryRepositoryImpl();
});

/// Daftar kategori sesuai jenis transaksi (pemasukan/pengeluaran).
final categoriesByTypeProvider =
    Provider.family<List<Category>, TransactionType>((ref, type) {
      return ref.watch(categoryRepositoryProvider).getCategories(type: type);
    });

/// Cari kategori berdasarkan id (mis. untuk menampilkan ikon di daftar transaksi).
final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  return ref.watch(categoryRepositoryProvider).findById(id);
});
