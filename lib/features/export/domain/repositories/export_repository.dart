import 'dart:io';

import '../../../categories/domain/entities/category.dart';
import '../entities/spreadsheet_import_result.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../wallets/domain/entities/wallet.dart';

/// Kontrak domain untuk export/import laporan transaksi multi-format.
///
/// Layer domain hanya mendefinisikan operasi tingkat bisnis.
/// Detail teknis (pdf/csv/xlsx library) berada di layer data.
///
/// Catatan: Import hanya didukung untuk CSV karena library XLSX open-source
/// yang tersedia konflik dengan dependency syncfusion saat ini.
abstract interface class ExportRepository {
  /// Export semua [transactions] ke file CSV.
  ///
  /// Kolom: Tanggal, Tipe, Nominal, Kategori, Dompet, Catatan.
  Future<File> exportToCsv({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  });

  /// Export semua [transactions] ke file XLSX.
  Future<File> exportToXls({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  });

  /// Export semua [transactions] ke file PDF.
  Future<File> exportToPdf({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  });

  /// Membaca laporan CSV, XLS, atau XLSX dengan format laporan keuangan app.
  ///
  /// Seluruh transaksi mendapat ID baru; kategori baru dikembalikan terpisah
  /// agar caller dapat menyimpannya sebelum menampilkan transaksi.
  Future<SpreadsheetImportResult> importFromSpreadsheet({
    required List<int> bytes,
    required String extension,
    required List<Category> existingCategories,
  });
}
