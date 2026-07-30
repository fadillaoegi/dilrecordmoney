import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Sumber data mentah untuk backup: baca/tulis SharedPreferences + file sementara.
///
/// Hanya menangani I/O; tidak tahu format backup, versi skema, atau validasi.
abstract interface class BackupLocalDataSource {
  String? readTransactionsRaw();
  String? readBudgetsRaw();
  bool readOnboardingSeen();

  Future<void> writeTransactionsRaw(String value);
  Future<void> writeBudgetsRaw(String value);
  Future<void> writeOnboardingSeen(bool value);

  /// Menulis [content] ke berkas sementara dengan nama [fileName].
  Future<File> writeToTempFile(String fileName, String content);
}

class BackupLocalDataSourceImpl implements BackupLocalDataSource {
  const BackupLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? readTransactionsRaw() => _prefs.getString(AppConstants.kTransactions);

  @override
  String? readBudgetsRaw() => _prefs.getString(AppConstants.kBudgets);

  @override
  bool readOnboardingSeen() =>
      _prefs.getBool(AppConstants.kOnboardingSeen) ?? false;

  @override
  Future<void> writeTransactionsRaw(String value) =>
      _prefs.setString(AppConstants.kTransactions, value);

  @override
  Future<void> writeBudgetsRaw(String value) =>
      _prefs.setString(AppConstants.kBudgets, value);

  @override
  Future<void> writeOnboardingSeen(bool value) =>
      _prefs.setBool(AppConstants.kOnboardingSeen, value);

  @override
  Future<File> writeToTempFile(String fileName, String content) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsString(content, flush: true);
  }
}
