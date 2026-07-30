import 'dart:convert';
import 'dart:io';

import '../../../budgets/data/models/budget_model.dart';
import '../../../transactions/data/models/money_transaction_model.dart';
import '../../domain/entities/backup_snapshot.dart';
import '../../domain/failures/backup_failure.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_local_datasource.dart';

/// Implementasi [BackupRepository]: menyusun/memvalidasi format backup dan
/// mendelegasikan I/O ke [BackupLocalDataSource].
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._local);

  final BackupLocalDataSource _local;

  static const int _schemaVersion = 1;
  static const String _appId = 'dilrecordmoney';

  @override
  BackupSnapshot createSnapshot({DateTime? exportedAt}) {
    final json = const JsonEncoder.withIndent('  ').convert({
      'app': _appId,
      'schemaVersion': _schemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'onboardingSeen': _local.readOnboardingSeen(),
      'transactions': _decodeList(_local.readTransactionsRaw()),
      'budgets': _decodeList(_local.readBudgetsRaw()),
    });

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return BackupSnapshot(
      json: json,
      suggestedFileName: 'dilrecordmoney-backup-$timestamp.json',
    );
  }

  @override
  Future<File> writeSnapshotToFile(BackupSnapshot snapshot) {
    return _local.writeToTempFile(snapshot.suggestedFileName, snapshot.json);
  }

  @override
  Future<void> restoreFromJson(String rawJson) async {
    final backup = _decodeBackup(rawJson);
    final transactions = _validateTransactions(backup['transactions']);
    final budgets = _validateBudgets(backup['budgets']);
    final onboardingSeen = backup['onboardingSeen'];

    await _local.writeTransactionsRaw(
      jsonEncode(transactions.map((e) => e.toJson()).toList()),
    );
    await _local.writeBudgetsRaw(
      jsonEncode(budgets.map((e) => e.toJson()).toList()),
    );
    await _local.writeOnboardingSeen(
      onboardingSeen is bool ? onboardingSeen : true,
    );
  }

  // ── Serialisasi & validasi ────────────────────────────────────────────────

  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const BackupFailure('Data lokal tidak valid untuk di-export.');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeBackup(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFailure('File backup bukan JSON yang valid.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupFailure('Format backup tidak dikenali.');
    }
    if (decoded['app'] != _appId) {
      throw const BackupFailure('File ini bukan backup DilRecord Money.');
    }
    if (decoded['schemaVersion'] != _schemaVersion) {
      throw const BackupFailure('Versi backup belum didukung aplikasi ini.');
    }
    return decoded;
  }

  List<MoneyTransactionModel> _validateTransactions(Object? value) {
    if (value is! List) {
      throw const BackupFailure('Data transaksi di backup tidak valid.');
    }
    try {
      return value
          .map((e) => MoneyTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const BackupFailure('Ada transaksi backup yang rusak.');
    }
  }

  List<BudgetModel> _validateBudgets(Object? value) {
    if (value is! List) {
      throw const BackupFailure('Data anggaran di backup tidak valid.');
    }
    try {
      return value
          .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const BackupFailure('Ada anggaran backup yang rusak.');
    }
  }
}
