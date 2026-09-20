import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel_plus/excel_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_import.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../wallets/domain/entities/wallet.dart';
import '../../domain/entities/spreadsheet_import_result.dart';
import '../../domain/repositories/export_repository.dart';

/// Header tabel laporan, mengikuti format file Excel sumber pengguna.
const List<String> _headers = [
  'No',
  'Tanggal',
  'Catatan',
  'Pengeluaran',
  'Pemasukan',
  'Kategori',
];

class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl();

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Directory> get _tempDir => getTemporaryDirectory();

  String _timestamp() => DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-')
      .substring(0, 19);

  String _categoryName(String id, List<Category> cats) {
    try {
      return cats.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '-';
    }
  }

  String _dateText(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _rupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer('Rp');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  List<List<String>> _buildRows(
    List<MoneyTransaction> transactions,
    List<Category> categories,
  ) {
    return transactions.indexed.map((entry) {
      final index = entry.$1;
      final t = entry.$2;
      return [
        '${index + 1}',
        _dateText(t.date),
        t.note ?? '',
        t.type.isExpense ? _rupiah(t.amount) : '',
        t.type.isIncome ? _rupiah(t.amount) : '',
        _categoryName(t.categoryId, categories),
      ];
    }).toList();
  }

  // ── CSV Export ────────────────────────────────────────────────────────────

  @override
  Future<File> exportToCsv({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) async {
    final rows = [_headers, ..._buildRows(transactions, categories)];
    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await _tempDir;
    final file = File('${dir.path}/dilrecordmoney-export-${_timestamp()}.csv');
    return file.writeAsString(csvString, flush: true);
  }

  // ── XLS (XLSX) Export ─────────────────────────────────────────────────────

  @override
  Future<File> exportToXls({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Laporan Keuangan';

    final income = transactions
        .where((transaction) => transaction.type.isIncome)
        .fold(0, (sum, transaction) => sum + transaction.amount);
    final expense = transactions
        .where((transaction) => transaction.type.isExpense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
    final firstDate = transactions
        .map((t) => t.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = transactions
        .map((t) => t.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final title = sheet.getRangeByName('B1:G1')
      ..merge()
      ..setText('Laporan Keuangan');
    title.cellStyle.bold = true;
    title.cellStyle.fontSize = 16;

    final summary = <(String, String)>[
      ('Tanggal', '${_dateText(firstDate)} - ${_dateText(lastDate)}'),
      ('Pemasukan', _rupiah(income)),
      ('Pengeluaran', _rupiah(expense)),
      ('Saldo', _rupiah(income - expense)),
      ('Saldo bawaan', _rupiah(0)),
    ];
    for (var index = 0; index < summary.length; index++) {
      sheet.getRangeByIndex(index + 3, 2).setText(summary[index].$1);
      sheet.getRangeByIndex(index + 3, 4).setText(summary[index].$2);
    }

    // Header style
    final headerStyle = workbook.styles.add('header');
    headerStyle.bold = true;
    headerStyle.backColor = '#F5C842';
    headerStyle.fontColor = '#1A1A1A';

    // Write header row
    for (var col = 0; col < _headers.length; col++) {
      final cell = sheet.getRangeByIndex(9, col + 2);
      cell.setText(_headers[col]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidthInPixels(col + 2, col == 0 ? 45 : 150);
    }

    // Write data rows
    final rows = _buildRows(transactions, categories);
    for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        final cell = sheet.getRangeByIndex(rowIdx + 10, colIdx + 2);
        cell.setText(row[colIdx]);
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await _tempDir;
    final file = File('${dir.path}/dilrecordmoney-export-${_timestamp()}.xlsx');
    return file.writeAsBytes(bytes, flush: true);
  }

  // ── PDF Export ────────────────────────────────────────────────────────────

  @override
  Future<File> exportToPdf({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) async {
    final doc = pw.Document();
    final rows = _buildRows(transactions, categories);

    // Split ke halaman-halaman agar tidak overflow
    const rowsPerPage = 30;
    final pages = <List<List<dynamic>>>[];
    for (var i = 0; i < rows.length; i += rowsPerPage) {
      final end = i + rowsPerPage > rows.length ? rows.length : i + rowsPerPage;
      pages.add(rows.sublist(i, end));
    }
    if (pages.isEmpty) pages.add([]);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    for (final pageRows in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'DilRecord Money — Laporan Transaksi',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Diekspor: $dateStr  |  Total: ${transactions.length} transaksi',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 12),
              // Table
              pw.Table(
                border: pw.TableBorder.all(
                  width: 0.5,
                  color: PdfColors.grey400,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.8),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.8),
                  3: const pw.FlexColumnWidth(1.6),
                  4: const pw.FlexColumnWidth(1.4),
                  5: const pw.FlexColumnWidth(2.2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.amber200,
                    ),
                    children: _headers
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  // Data rows
                  ...pageRows.map(
                    (row) => pw.TableRow(
                      children: row
                          .map(
                            (cell) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: pw.Text(
                                cell.toString(),
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final pdfBytes = await doc.save();
    final dir = await _tempDir;
    final file = File('${dir.path}/dilrecordmoney-export-${_timestamp()}.pdf');
    return file.writeAsBytes(pdfBytes, flush: true);
  }

  // ── Spreadsheet Import ────────────────────────────────────────────────────

  @override
  Future<SpreadsheetImportResult> importFromSpreadsheet({
    required List<int> bytes,
    required String extension,
    required List<Category> existingCategories,
  }) async {
    final lowerExtension = extension.toLowerCase();
    final List<List<String>> rows;
    try {
      if (lowerExtension == 'csv') {
        final raw = utf8.decode(bytes, allowMalformed: true);
        rows = const CsvToListConverter()
            .convert(
              raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
              eol: '\n',
            )
            .map((row) => row.map((cell) => cell.toString()).toList())
            .toList();
      } else if (lowerExtension == 'xls' || lowerExtension == 'xlsx') {
        final workbook = await Excel.decodeBytesAsync(bytes);
        if (workbook.tables.isEmpty) {
          throw const FormatException('Workbook tidak memiliki sheet.');
        }
        final sheet = workbook.tables.values.first;
        rows = sheet.rows
            .map(
              (row) =>
                  row.map((cell) => cell?.displayText.trim() ?? '').toList(),
            )
            .toList();
      } else {
        throw const FormatException('Format file tidak didukung.');
      }
    } on Object catch (error) {
      throw FormatException('File spreadsheet tidak dapat dibaca: $error');
    }

    return _parseReportRows(rows, existingCategories);
  }

  SpreadsheetImportResult _parseReportRows(
    List<List<String>> rows,
    List<Category> existingCategories,
  ) {
    final headerRow = rows.indexWhere((row) {
      final values = row.map(_normaliseHeader).toSet();
      return values.containsAll({
        'tanggal',
        'pengeluaran',
        'pemasukan',
        'kategori',
      });
    });
    if (headerRow == -1) {
      throw const FormatException(
        'Header laporan tidak ditemukan. Gunakan kolom Tanggal, Pengeluaran, Pemasukan, dan Kategori.',
      );
    }

    final header = rows[headerRow].map(_normaliseHeader).toList();
    final dateColumn = header.indexOf('tanggal');
    final noteColumn = header.contains('catatan')
        ? header.indexOf('catatan')
        : header.indexOf('keterangan');
    final expenseColumn = header.indexOf('pengeluaran');
    final incomeColumn = header.indexOf('pemasukan');
    final categoryColumn = header.indexOf('kategori');

    String valueAt(List<String> row, int column) =>
        column >= 0 && column < row.length ? row[column].trim() : '';

    final transactions = <MoneyTransaction>[];
    final importsByIdentity = <String, CategoryImport>{};
    final knownByIdentity = {
      for (final category in existingCategories)
        _categoryIdentity(category.name, category.type): category,
    };

    for (final row in rows.skip(headerRow + 1)) {
      final date = _parseDate(valueAt(row, dateColumn));
      final expense = _parseAmount(valueAt(row, expenseColumn));
      final income = _parseAmount(valueAt(row, incomeColumn));
      if (date == null || (expense <= 0 && income <= 0)) continue;

      final type = income > 0
          ? TransactionType.income
          : TransactionType.expense;
      final amount = income > 0 ? income : expense;
      final categoryName = valueAt(row, categoryColumn);
      final fallbackId = type.isIncome ? 'inc_other' : 'exp_other';
      final identity = _categoryIdentity(categoryName, type);
      final knownCategory = knownByIdentity[identity];
      final categoryId = categoryName.isEmpty
          ? fallbackId
          : knownCategory?.id ??
                CategoryImport(name: categoryName, type: type).id;

      if (categoryName.isNotEmpty && knownCategory == null) {
        importsByIdentity.putIfAbsent(
          identity,
          () => CategoryImport(name: categoryName, type: type),
        );
      }

      final note = valueAt(row, noteColumn);
      transactions.add(
        MoneyTransaction(
          id: IdGenerator.generate(),
          type: type,
          amount: amount,
          categoryId: categoryId,
          walletId: 'cash',
          date: date,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    if (transactions.isEmpty) {
      throw const FormatException('Tidak ada transaksi valid di file ini.');
    }
    return SpreadsheetImportResult(
      transactions: transactions,
      newCategories: importsByIdentity.values.toList(),
    );
  }

  String _normaliseHeader(String value) => value.trim().toLowerCase();

  String _categoryIdentity(String name, TransactionType type) =>
      '${type.key}:${name.trim().toLowerCase()}';

  int _parseAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  DateTime? _parseDate(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final match = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(value);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
