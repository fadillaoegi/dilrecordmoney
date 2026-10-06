import 'dart:convert';
import 'dart:io';

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/categories/data/category_catalog.dart';
import 'package:dilrecordmoney/features/categories/data/datasources/custom_category_local_datasource.dart';
import 'package:dilrecordmoney/features/categories/data/repositories/category_repository_impl.dart';
import 'package:dilrecordmoney/features/categories/domain/entities/category_import.dart';
import 'package:dilrecordmoney/features/export/data/repositories/export_repository_impl.dart';
import 'package:dilrecordmoney/features/export/domain/entities/spreadsheet_import_result.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = ExportRepositoryImpl();

  _importEdgeCases(repository);

  setUpAll(() {
    PathProviderPlatform.instance = _TestPathProvider(
      Directory.systemTemp.path,
    );
  });

  test(
    'CSV format laporan membaca kategori baru dan kategori bawaan',
    () async {
      const csv = '''No,Tanggal,Keterangan,Pengeluaran,Pemasukan,Kategori
1,06/02/2024,, ,Rp1.000.000,Gaji
2,11/04/2024,Gojek ke stasiun,Rp12.500,,Motor
''';

      final result = await repository.importFromSpreadsheet(
        bytes: utf8.encode(csv),
        extension: 'csv',
        existingCategories: CategoryCatalog.all,
      );

      expect(result.transactions, hasLength(2));
      expect(result.transactions.first.type, TransactionType.income);
      expect(result.transactions.first.categoryId, 'inc_salary');
      expect(result.transactions.last.type, TransactionType.expense);
      expect(result.transactions.last.categoryId, 'custom_expense_motor');
      expect(result.newCategories.single.name, 'Motor');
    },
  );

  test('XLSX format laporan dapat dibaca ulang', () async {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    const values = [
      'No',
      'Tanggal',
      'Keterangan',
      'Pengeluaran',
      'Pemasukan',
      'Kategori',
    ];
    for (var column = 0; column < values.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
        TextCellValue(values[column]),
      );
    }
    const row = ['1', '11/04/2024', 'Makan siang', 'Rp25.000', '', 'Kuliner'];
    for (var column = 0; column < row.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 1),
        TextCellValue(row[column]),
      );
    }

    final result = await repository.importFromSpreadsheet(
      bytes: workbook.save()!,
      extension: 'xlsx',
      existingCategories: CategoryCatalog.all,
    );

    expect(result.transactions.single.amount, 25000);
    expect(result.transactions.single.note, 'Makan siang');
    expect(result.newCategories.single.name, 'Kuliner');
  });

  test('kategori impor tersimpan dan tidak diduplikasi', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final categories = CategoryRepositoryImpl(
      CustomCategoryLocalDataSourceImpl(prefs),
    );

    await categories.addImportedCategories([
      const CategoryImport(name: 'Motor', type: TransactionType.expense),
      const CategoryImport(name: 'motor', type: TransactionType.expense),
    ]);

    final stored = categories.getCustomCategories();
    expect(stored, hasLength(1));
    expect(stored.single.id, 'custom_expense_motor');
  });

  test(
    'export XLSX memakai format laporan dan dapat diimpor kembali',
    () async {
      final transactions = [
        MoneyTransaction(
          id: 'income',
          type: TransactionType.income,
          amount: 1000000,
          categoryId: 'inc_salary',
          walletId: 'cash',
          date: DateTime(2024, 2, 6),
        ),
        MoneyTransaction(
          id: 'expense',
          type: TransactionType.expense,
          amount: 12500,
          categoryId: 'exp_food',
          walletId: 'cash',
          date: DateTime(2024, 4, 11),
          note: 'Makan siang',
        ),
      ];
      final file = await repository.exportToXls(
        transactions: transactions,
        categories: CategoryCatalog.all,
        wallets: const <Never>[],
      );

      final imported = await repository.importFromSpreadsheet(
        bytes: await file.readAsBytes(),
        extension: 'xlsx',
        existingCategories: CategoryCatalog.all,
      );

      expect(imported.transactions, hasLength(2));
      expect(imported.transactions[0].amount, 1000000);
      expect(imported.transactions[1].note, 'Makan siang');
    },
  );
}

void _importEdgeCases(ExportRepositoryImpl repository) {
  group('import tahan banting', () {
    Future<List<MoneyTransaction>> importCsv(
      String csv, {
      List<MoneyTransaction> existing = const [],
      String extension = 'csv',
    }) async {
      final result = await repository.importFromSpreadsheet(
        bytes: utf8.encode(csv),
        extension: extension,
        existingCategories: CategoryCatalog.all,
        existingTransactions: existing,
      );
      return result.transactions;
    }

    test('CSV Excel Indonesia: BOM + pemisah titik koma', () async {
      final rows = await importCsv(
        '\uFEFFNo;Tanggal;Catatan;Pengeluaran;Pemasukan;Kategori\n'
        '1;21/09/2026;Kopi;Rp 18.000,00;;Makan & Minum\n',
      );
      expect(rows.single.amount, 18000);
      expect(rows.single.categoryId, 'exp_food');
      expect(rows.single.date, DateTime(2026, 9, 21));
    });

    test('format nominal campuran dibaca benar', () async {
      final rows = await importCsv(
        'Tanggal,Pengeluaran,Pemasukan,Kategori\n'
        '2026-09-01,"12,500",,Transport\n'
        '2026-09-02,25000.0,,Transport\n'
        '2026-09-03,1.000.000,,Transport\n'
        '01/09/26,,"1,250,000.75",Gaji\n',
      );
      expect(rows.map((t) => t.amount), [12500, 25000, 1000000, 1250001]);
      expect(rows.last.date, DateTime(2026, 9, 1));
    });

    test('header bahasa Inggris + kolom Tipe/Nominal/Dompet', () async {
      final rows = await importCsv(
        'Date,Type,Amount,Category,Wallet,Note\n'
        '2026-09-05,Income,500000,Freelance,Bank BCA,Proyek\n'
        '2026-09-06,Expense,30000,,GoPay,\n',
      );
      expect(rows[0].type, TransactionType.income);
      expect(rows[0].walletId, 'bank');
      expect(rows[0].note, 'Proyek');
      expect(rows[1].type, TransactionType.expense);
      expect(rows[1].walletId, 'ewallet');
      expect(rows[1].categoryId, 'exp_other');
    });

    test('impor ulang file yang sama tidak menggandakan data', () async {
      const csv =
          'Tanggal,Catatan,Pengeluaran,Pemasukan,Kategori\n'
          '21/09/2026,Kopi,18000,,Makan & Minum\n'
          '21/09/2026,Kopi,18000,,Makan & Minum\n';
      final first = await importCsv(csv);
      expect(first, hasLength(2));

      // Satu sudah ada → hanya baris kembar kedua yang masuk.
      final partial = await importCsv(csv, existing: first.take(1).toList());
      expect(partial, hasLength(1));

      await expectLater(
        repository.importFromSpreadsheet(
          bytes: utf8.encode(csv),
          extension: 'csv',
          existingCategories: CategoryCatalog.all,
          existingTransactions: first,
        ),
        completion(
          isA<SpreadsheetImportResult>()
              .having((r) => r.transactions, 'transactions', isEmpty)
              .having((r) => r.skippedDuplicates, 'skipped', 2),
        ),
      );
    });

    test('jenis file dikenali dari isi, bukan ekstensi', () async {
      final workbook = Excel.createExcel();
      final sheet = workbook['Sheet1'];
      const header = ['Tanggal', 'Pengeluaran', 'Pemasukan', 'Kategori'];
      for (var c = 0; c < header.length; c++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
          TextCellValue(header[c]),
        );
      }
      // Nominal numerik + tanggal bertipe tanggal (bukan teks).
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        DateCellValue(year: 2026, month: 9, day: 21),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
        DoubleCellValue(25000.0),
      );

      final result = await repository.importFromSpreadsheet(
        bytes: workbook.save()!,
        extension: '', // nama file Android tanpa ekstensi
        existingCategories: CategoryCatalog.all,
      );
      expect(result.transactions.single.amount, 25000);
      expect(result.transactions.single.date, DateTime(2026, 9, 21));
    });
  });
}

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this._temporaryPath);

  final String _temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => _temporaryPath;
}
