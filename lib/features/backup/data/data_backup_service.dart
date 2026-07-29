import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../budgets/data/models/budget_model.dart';
import '../../transactions/data/models/money_transaction_model.dart';

class BackupDataException implements Exception {
  const BackupDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Membuat dan memulihkan backup JSON untuk data lokal aplikasi.
class DataBackupService {
  const DataBackupService(this._prefs);

  static const int _schemaVersion = 1;
  static const String _appId = 'dilrecordmoney';

  final SharedPreferences _prefs;

  String createBackupJson({DateTime? exportedAt}) {
    final transactions = _readJsonList(AppConstants.kTransactions);
    final budgets = _readJsonList(AppConstants.kBudgets);

    return const JsonEncoder.withIndent('  ').convert({
      'app': _appId,
      'schemaVersion': _schemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'onboardingSeen': _prefs.getBool(AppConstants.kOnboardingSeen) ?? false,
      'transactions': transactions,
      'budgets': budgets,
    });
  }

  Future<File> createBackupFile() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final file = File(
      '${directory.path}/dilrecordmoney-backup-$timestamp.json',
    );
    return file.writeAsString(createBackupJson(), flush: true);
  }

  Future<void> restoreBackupJson(String raw) async {
    final backup = _decodeBackup(raw);
    final transactions = _validateTransactions(backup['transactions']);
    final budgets = _validateBudgets(backup['budgets']);
    final onboardingSeen = backup['onboardingSeen'];

    await _prefs.setString(
      AppConstants.kTransactions,
      jsonEncode(transactions.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      AppConstants.kBudgets,
      jsonEncode(budgets.map((e) => e.toJson()).toList()),
    );
    await _prefs.setBool(
      AppConstants.kOnboardingSeen,
      onboardingSeen is bool ? onboardingSeen : true,
    );
  }

  List<dynamic> _readJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const BackupDataException(
        'Data lokal tidak valid untuk di-export.',
      );
    }
    return decoded;
  }

  Map<String, dynamic> _decodeBackup(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupDataException('File backup bukan JSON yang valid.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupDataException('Format backup tidak dikenali.');
    }
    if (decoded['app'] != _appId) {
      throw const BackupDataException('File ini bukan backup DilRecord Money.');
    }
    if (decoded['schemaVersion'] != _schemaVersion) {
      throw const BackupDataException(
        'Versi backup belum didukung aplikasi ini.',
      );
    }
    return decoded;
  }

  List<MoneyTransactionModel> _validateTransactions(Object? value) {
    if (value is! List) {
      throw const BackupDataException('Data transaksi di backup tidak valid.');
    }
    try {
      return value
          .map((e) => MoneyTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const BackupDataException('Ada transaksi backup yang rusak.');
    }
  }

  List<BudgetModel> _validateBudgets(Object? value) {
    if (value is! List) {
      throw const BackupDataException('Data anggaran di backup tidak valid.');
    }
    try {
      return value
          .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const BackupDataException('Ada anggaran backup yang rusak.');
    }
  }
}
