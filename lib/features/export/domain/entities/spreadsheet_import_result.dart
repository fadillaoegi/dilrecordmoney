import 'package:flutter/foundation.dart';

import '../../../categories/domain/entities/category_import.dart';
import '../../../transactions/domain/entities/money_transaction.dart';

/// Hasil pembacaan laporan spreadsheet sebelum disimpan ke aplikasi.
@immutable
class SpreadsheetImportResult {
  const SpreadsheetImportResult({
    required this.transactions,
    required this.newCategories,
  });

  final List<MoneyTransaction> transactions;

  /// Hanya kategori yang belum tersedia di aplikasi.
  final List<CategoryImport> newCategories;
}
