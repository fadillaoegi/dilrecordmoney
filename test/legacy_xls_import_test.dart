import 'dart:io';

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/categories/data/category_catalog.dart';
import 'package:dilrecordmoney/features/export/data/datasources/legacy_xls_reader.dart';
import 'package:dilrecordmoney/features/export/data/repositories/export_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture dibuat dengan xlwt (BIFF8 asli, bukan XLSX berganti nama).
void main() {
  const repository = ExportRepositoryImpl();
  final large = File('test/fixtures/report_large.xls').readAsBytesSync();
  final small = File('test/fixtures/report_small.xls').readAsBytesSync();

  test('reader membaca semua sheet, tanggal, angka, dan teks unicode', () {
    final sheets = LegacyXlsReader.readSheets(large);
    expect(sheets, hasLength(2));
    expect(sheets[0][1], ['Saldo', '1234567']);

    final data = sheets[1];
    expect(data[8].sublist(1), [
      'No',
      'Tanggal',
      'Catatan',
      'Pengeluaran',
      'Pemasukan',
      'Kategori',
    ]);
    expect(data[9].sublist(1, 5), [
      '1',
      '2026-09-21',
      'Kopi susu gula aren',
      '18000',
    ]);
    expect(data[11][3], 'Tiket 中文 café');
    expect(data[11][4], '12500.5');
    // SST besar terpecah ke record CONTINUE — baris terakhir tetap utuh.
    expect(data.last[3], contains('nomor 0594'));
  });

  test('import .xls besar: sheet data dipilih otomatis', () async {
    final result = await repository.importFromSpreadsheet(
      bytes: large,
      extension: 'xls',
      existingCategories: CategoryCatalog.all,
    );

    expect(result.transactions, hasLength(600));
    final first = result.transactions.first;
    expect(first.amount, 18000);
    expect(first.date, DateTime(2026, 9, 21));
    expect(first.categoryId, 'exp_food');
    expect(result.transactions[1].type, TransactionType.income);
    expect(result.transactions[1].amount, 8500000);
    expect(result.transactions[2].amount, 12501); // 12500,5 dibulatkan
    expect(result.transactions[3].amount, 350000); // teks "Rp 350.000"
    expect(result.transactions[4].amount, 15000); // nominal negatif
    expect(result.newCategories.map((c) => c.name), contains('Motor'));
  });

  test('import .xls kecil dengan tanggal teks & tanggal sel', () async {
    final result = await repository.importFromSpreadsheet(
      bytes: small,
      extension: 'xls',
      existingCategories: CategoryCatalog.all,
    );
    expect(result.transactions, hasLength(2));
    expect(result.transactions[0].date, DateTime(2026, 10, 1));
    expect(result.transactions[1].date, DateTime(2026, 10, 2));
    expect(result.transactions[1].type, TransactionType.income);
  });

  test('file .xls rusak memberi FormatException, bukan crash', () {
    final broken = large.sublist(0, 700);
    expect(
      () => LegacyXlsReader.readSheets(broken),
      throwsA(isA<FormatException>()),
    );
  });
}
