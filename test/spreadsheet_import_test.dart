import 'dart:convert';
import 'dart:io';

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/categories/data/category_catalog.dart';
import 'package:dilrecordmoney/features/categories/data/datasources/custom_category_local_datasource.dart';
import 'package:dilrecordmoney/features/categories/data/repositories/category_repository_impl.dart';
import 'package:dilrecordmoney/features/categories/domain/entities/category_import.dart';
import 'package:dilrecordmoney/features/export/data/repositories/export_repository_impl.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = ExportRepositoryImpl();

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

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this._temporaryPath);

  final String _temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => _temporaryPath;
}
