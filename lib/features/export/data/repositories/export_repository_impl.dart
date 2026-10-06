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
import '../../../categories/data/category_catalog.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_import.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../wallets/domain/entities/wallet.dart';
import '../../domain/entities/spreadsheet_import_result.dart';
import '../datasources/legacy_xls_reader.dart';
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
    List<MoneyTransaction> existingTransactions = const [],
  }) async {
    final List<List<String>> rows;
    try {
      // Jenis file dikenali dari isinya, bukan ekstensi: di Android nama file
      // dari penyedia dokumen sering tanpa ekstensi, dan file `.xls` hasil
      // aplikasi lain kerap sebenarnya XLSX atau CSV.
      rows = switch (_detectKind(bytes, extension)) {
        _FileKind.xlsx => await _readWorkbook(bytes),
        _FileKind.legacyXls => _pickReportSheet(
          LegacyXlsReader.readSheets(bytes),
        ),
        _FileKind.csv => _readCsv(bytes),
        _FileKind.unknown => throw const FormatException(
          'Format file tidak didukung. Gunakan CSV atau XLSX.',
        ),
      };
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('File spreadsheet tidak dapat dibaca: $error');
    }

    return _parseReportRows(rows, existingCategories, existingTransactions);
  }

  _FileKind _detectKind(List<int> bytes, String extension) {
    bool startsWith(List<int> magic) =>
        bytes.length >= magic.length &&
        Iterable<int>.generate(magic.length).every((i) => bytes[i] == magic[i]);

    if (startsWith(const [0x50, 0x4B, 0x03, 0x04])) return _FileKind.xlsx;
    if (startsWith(const [0xD0, 0xCF, 0x11, 0xE0])) return _FileKind.legacyXls;
    // Sisanya dianggap teks bila ekstensinya cocok atau tidak diketahui.
    final ext = extension.toLowerCase();
    if (const {'csv', 'txt', 'xls', ''}.contains(ext)) {
      return _FileKind.csv;
    }
    return _FileKind.unknown;
  }

  List<List<String>> _readCsv(List<int> bytes) {
    var raw = utf8.decode(bytes, allowMalformed: true);
    // Excel di Windows menyimpan CSV UTF-8 dengan BOM di awal file.
    if (raw.startsWith('﻿')) raw = raw.substring(1);
    raw = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Excel berlocale Indonesia memakai `;` sebagai pemisah kolom.
    final firstLine = raw
        .split('\n')
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
    final delimiter =
        ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
        ? ';'
        : ',';

    return CsvToListConverter(fieldDelimiter: delimiter, eol: '\n')
        .convert(raw, shouldParseNumbers: false)
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();
  }

  Future<List<List<String>>> _readWorkbook(List<int> bytes) async {
    final workbook = await Excel.decodeBytesAsync(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('Workbook tidak memiliki sheet.');
    }
    return _pickReportSheet(
      workbook.tables.values
          .map(
            (sheet) =>
                sheet.rows.map((row) => row.map(_cellText).toList()).toList(),
          )
          .toList(),
    );
  }

  /// Sheet pertama yang punya header laporan; bila tidak ada, sheet pertama
  /// (pesan error header akan muncul dari parser).
  List<List<String>> _pickReportSheet(List<List<List<String>>> sheets) {
    if (sheets.isEmpty) {
      throw const FormatException('Workbook tidak memiliki sheet.');
    }
    return sheets.firstWhere(
      (rows) => _findHeader(rows) != null,
      orElse: () => sheets.first,
    );
  }

  /// Nilai sel dalam bentuk teks kanonis. Angka & tanggal dibaca dari nilai
  /// mentah (bukan `displayText`) supaya format tampilan seperti
  /// `1,234.50` atau `9/21/26` tidak merusak hasil parsing.
  String _cellText(Data? cell) {
    final value = cell?.value;
    return switch (value) {
      null => '',
      IntCellValue(:final value) => '$value',
      DoubleCellValue(:final value) => '${value.round()}',
      DateCellValue() => _isoDate(value.asDateTimeUtc()),
      DateTimeCellValue() => _isoDate(value.asDateTimeUtc()),
      _ => cell!.displayText.trim(),
    };
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  SpreadsheetImportResult _parseReportRows(
    List<List<String>> rows,
    List<Category> existingCategories,
    List<MoneyTransaction> existingTransactions,
  ) {
    final found = _findHeader(rows);
    if (found == null) {
      throw const FormatException(
        'Header laporan tidak ditemukan. Gunakan kolom Tanggal, '
        'Pengeluaran, Pemasukan, dan Kategori '
        '(atau Tanggal, Tipe, Nominal, Kategori).',
      );
    }
    final (headerRow, columns) = found;

    String valueAt(List<String> row, _Column column) {
      final index = columns[column];
      return index != null && index < row.length ? row[index].trim() : '';
    }

    final transactions = <MoneyTransaction>[];
    final importsByIdentity = <String, CategoryImport>{};
    final byId = {for (final c in existingCategories) c.id: c};
    final knownByIdentity = {
      // Nama kategori bawaan dalam semua bahasa → kategori aktifnya.
      for (final MapEntry(:key, :value) in CategoryCatalog.nameAliases.entries)
        key: ?byId[value],
      for (final category in existingCategories)
        _categoryIdentity(category.name, category.type): category,
    };

    // Hitungan transaksi yang sudah ada per "sidik jari", supaya file yang
    // sama tidak menggandakan data saat diimpor ulang. Pakai hitungan (bukan
    // set) agar dua jajan identik di hari yang sama tetap bisa masuk.
    final existingCounts = <String, int>{};
    for (final t in existingTransactions) {
      final key = _fingerprint(t);
      existingCounts[key] = (existingCounts[key] ?? 0) + 1;
    }
    var skippedDuplicates = 0;
    var skippedInvalid = 0;

    for (final row in rows.skip(headerRow + 1)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;

      final date = _parseDate(valueAt(row, _Column.date));
      final parsed = _parseTypeAndAmount(row, valueAt);
      if (date == null || parsed == null) {
        skippedInvalid++;
        continue;
      }
      final (type, amount) = parsed;

      final categoryName = valueAt(row, _Column.category);
      final fallbackId = type.isIncome ? 'inc_other' : 'exp_other';
      final identity = _categoryIdentity(categoryName, type);
      final knownCategory = knownByIdentity[identity];
      final categoryId = categoryName.isEmpty || categoryName == '-'
          ? fallbackId
          : knownCategory?.id ??
                CategoryImport(name: categoryName, type: type).id;

      if (categoryName.isNotEmpty &&
          categoryName != '-' &&
          knownCategory == null) {
        importsByIdentity.putIfAbsent(
          identity,
          () => CategoryImport(name: categoryName, type: type),
        );
      }

      final note = valueAt(row, _Column.note);
      final transaction = MoneyTransaction(
        id: IdGenerator.generate(),
        type: type,
        amount: amount,
        categoryId: categoryId,
        walletId: _parseWallet(valueAt(row, _Column.wallet)),
        date: date,
        note: note.isEmpty ? null : note,
      );

      final key = _fingerprint(transaction);
      final remaining = existingCounts[key] ?? 0;
      if (remaining > 0) {
        existingCounts[key] = remaining - 1;
        skippedDuplicates++;
        continue;
      }
      transactions.add(transaction);
    }

    if (transactions.isEmpty && skippedDuplicates == 0) {
      throw const FormatException('Tidak ada transaksi valid di file ini.');
    }
    return SpreadsheetImportResult(
      transactions: transactions,
      newCategories: importsByIdentity.values
          .where((c) => transactions.any((t) => t.categoryId == c.id))
          .toList(),
      skippedDuplicates: skippedDuplicates,
      skippedInvalid: skippedInvalid,
    );
  }

  /// Mencari baris header dan memetakan kolomnya. Mendukung dua tata letak:
  /// laporan (Pengeluaran + Pemasukan terpisah) dan daftar (Tipe + Nominal),
  /// dengan nama kolom Indonesia maupun Inggris.
  (int, Map<_Column, int>)? _findHeader(List<List<String>> rows) {
    for (var r = 0; r < rows.length; r++) {
      final columns = <_Column, int>{};
      for (var c = 0; c < rows[r].length; c++) {
        final column = _headerAliases[_normaliseHeader(rows[r][c])];
        if (column != null) columns.putIfAbsent(column, () => c);
      }
      final hasDate = columns.containsKey(_Column.date);
      final splitAmounts =
          columns.containsKey(_Column.expense) &&
          columns.containsKey(_Column.income);
      final singleAmount =
          columns.containsKey(_Column.type) &&
          columns.containsKey(_Column.amount);
      if (hasDate && (splitAmounts || singleAmount)) return (r, columns);
    }
    return null;
  }

  (TransactionType, int)? _parseTypeAndAmount(
    List<String> row,
    String Function(List<String>, _Column) valueAt,
  ) {
    final expense = _parseAmount(valueAt(row, _Column.expense));
    final income = _parseAmount(valueAt(row, _Column.income));
    if (income > 0) return (TransactionType.income, income);
    if (expense > 0) return (TransactionType.expense, expense);

    final amountText = valueAt(row, _Column.amount);
    final amount = _parseAmount(amountText);
    if (amount <= 0) return null;
    final typeText = _normaliseHeader(valueAt(row, _Column.type));
    if (_incomeWords.contains(typeText)) {
      return (TransactionType.income, amount);
    }
    if (_expenseWords.contains(typeText)) {
      return (TransactionType.expense, amount);
    }
    // Tanpa kolom tipe yang jelas: nominal negatif berarti pengeluaran.
    if (typeText.isEmpty) {
      return amountText.trim().startsWith('-')
          ? (TransactionType.expense, amount)
          : (TransactionType.income, amount);
    }
    return null;
  }

  String _parseWallet(String value) {
    final name = _normaliseHeader(value);
    if (name.isEmpty) return 'cash';
    for (final MapEntry(:key, value: aliases) in _walletAliases.entries) {
      if (aliases.any(name.contains)) return key;
    }
    return 'cash';
  }

  String _fingerprint(MoneyTransaction t) =>
      '${t.type.key}|${t.amount}|${_isoDate(t.date)}|'
      '${t.categoryId}|${(t.note ?? '').trim().toLowerCase()}';

  String _normaliseHeader(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _categoryIdentity(String name, TransactionType type) =>
      '${type.key}:${name.trim().toLowerCase()}';

  /// Membaca nominal Rupiah dari teks bebas: `Rp12.500`, `12,500`,
  /// `Rp 12.500,00`, `25000.0`, `-15.000`. Desimal dibulatkan.
  int _parseAmount(String value) {
    var text = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (text.isEmpty) return 0;

    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');
    String? decimalSeparator;
    if (lastDot >= 0 && lastComma >= 0) {
      // Keduanya ada: yang terakhir muncul adalah pemisah desimal.
      decimalSeparator = lastDot > lastComma ? '.' : ',';
    } else if (lastDot >= 0 || lastComma >= 0) {
      final sep = lastDot >= 0 ? '.' : ',';
      final occurrences = sep.allMatches(text).length;
      final digitsAfter = text.length - text.lastIndexOf(sep) - 1;
      // `12.500` / `1.000.000` = ribuan; `25000.5` / `12,50` = desimal.
      if (occurrences == 1 && digitsAfter != 3) decimalSeparator = sep;
    }

    var fraction = '';
    if (decimalSeparator != null) {
      final index = text.lastIndexOf(decimalSeparator);
      fraction = text.substring(index + 1);
      text = text.substring(0, index);
    }
    final whole = int.tryParse(text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    final roundUp = fraction.isNotEmpty && int.parse(fraction[0]) >= 5;
    return whole + (roundUp ? 1 : 0);
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    // Nomor seri tanggal Excel (mis. 45321) dari CSV hasil Excel.
    final serial = int.tryParse(text);
    if (serial != null && serial > 20000 && serial < 80000) {
      final d = DateTime.utc(1899, 12, 30).add(Duration(days: serial));
      return DateTime(d.year, d.month, d.day);
    }

    // Format Indonesia: hari dulu. `21/09/2026`, `21-9-26`, `21.09.2026`.
    final match = RegExp(
      r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2}|\d{4})$',
    ).firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}

enum _FileKind { xlsx, legacyXls, csv, unknown }

enum _Column { date, note, expense, income, category, type, amount, wallet }

const Map<String, _Column> _headerAliases = {
  'tanggal': _Column.date,
  'tgl': _Column.date,
  'date': _Column.date,
  'catatan': _Column.note,
  'keterangan': _Column.note,
  'note': _Column.note,
  'notes': _Column.note,
  'description': _Column.note,
  'pengeluaran': _Column.expense,
  'expense': _Column.expense,
  'expenses': _Column.expense,
  'pemasukan': _Column.income,
  'income': _Column.income,
  'kategori': _Column.category,
  'category': _Column.category,
  'tipe': _Column.type,
  'jenis': _Column.type,
  'type': _Column.type,
  'nominal': _Column.amount,
  'jumlah': _Column.amount,
  'amount': _Column.amount,
  'dompet': _Column.wallet,
  'metode pembayaran': _Column.wallet,
  'wallet': _Column.wallet,
  'payment method': _Column.wallet,
};

const Set<String> _incomeWords = {'pemasukan', 'income', 'masuk', 'in'};
const Set<String> _expenseWords = {'pengeluaran', 'expense', 'keluar', 'out'};

const Map<String, List<String>> _walletAliases = {
  'bank': ['bank', 'transfer', 'debit', 'bca', 'bri', 'bni', 'mandiri'],
  'ewallet': [
    'e-wallet',
    'ewallet',
    'gopay',
    'ovo',
    'dana',
    'shopeepay',
    'qris',
  ],
  'cash': ['tunai', 'cash'],
};
