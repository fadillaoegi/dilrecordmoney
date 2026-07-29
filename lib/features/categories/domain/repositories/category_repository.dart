import '../../../../core/enums/transaction_type.dart';
import '../entities/category.dart';

/// Kontrak akses data kategori.
///
/// Untuk fondasi ini masih read-only (preset bawaan). Struktur ini sudah
/// siap diperluas untuk kategori kustom buatan pengguna nanti.
abstract interface class CategoryRepository {
  /// Semua kategori, atau tersaring berdasarkan [type] bila diberikan.
  List<Category> getCategories({TransactionType? type});

  Category? findById(String id);

  /// Kategori cadangan bila sebuah transaksi tidak berkategori ("Lainnya").
  Category fallbackFor(TransactionType type);
}
