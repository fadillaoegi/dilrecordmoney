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

  /// Menulis/menimpa file backup otomatis di folder backup khusus app.
  Future<File> writeAutoBackupFile(String content);

  /// Membaca file backup otomatis bila ada; `null` bila belum pernah dibuat.
  Future<String?> readAutoBackupFile();

  String? readLastAutoBackupDate();
  Future<void> writeLastAutoBackupDate(String value);
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

  @override
  Future<File> writeAutoBackupFile(String content) async {
    final dir = await _autoBackupDirectory();
    final file = File('${dir.path}/${AppConstants.autoBackupFileName}');
    return file.writeAsString(content, flush: true);
  }

  @override
  Future<String?> readAutoBackupFile() async {
    final dir = await _autoBackupDirectory();
    final file = File('${dir.path}/${AppConstants.autoBackupFileName}');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Folder khusus app (tanpa perlu izin storage) — terhapus bila app
  /// di-uninstall, jadi ini BUKAN perlindungan dari uninstall, cuma cadangan
  /// harian yang bisa dipulihkan lagi kalau app di-install ulang tanpa
  /// benar-benar uninstall (mis. `flutter run` ulang), atau kalau isi
  /// filenya dipindahkan manual sebelum reinstall.
  Future<Directory> _autoBackupDirectory() async {
    final base =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/${AppConstants.autoBackupFolderName}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  String? readLastAutoBackupDate() =>
      _prefs.getString(AppConstants.kLastAutoBackupDate);

  @override
  Future<void> writeLastAutoBackupDate(String value) =>
      _prefs.setString(AppConstants.kLastAutoBackupDate, value);
}
