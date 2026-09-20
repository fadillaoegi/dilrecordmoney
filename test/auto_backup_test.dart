// Menguji backup otomatis harian (timpa file) & auto-restore saat data kosong.

import 'dart:convert';
import 'dart:io';

import 'package:dilrecordmoney/core/constants/app_constants.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:dilrecordmoney/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:dilrecordmoney/features/backup/domain/repositories/backup_repository.dart';
import 'package:dilrecordmoney/features/transactions/data/models/money_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._root);

  final String _root;

  @override
  Future<String?> getExternalStoragePath() async => _root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;
}

void main() {
  late String tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('dilrecord_test_').path;
    PathProviderPlatform.instance = _FakePathProvider(tempRoot);
  });

  BackupRepository makeRepo(SharedPreferences prefs) =>
      BackupRepositoryImpl(BackupLocalDataSourceImpl(prefs));

  test(
    'backup harian: hanya jalan sekali per hari & menimpa file lama',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.kTransactions,
        jsonEncode([_txnJson('tx-1', 10000)]),
      );
      final repo = makeRepo(prefs);
      final day1 = DateTime(2026, 9, 1);

      final firstRun = await repo.runDailyAutoBackupIfDue(now: day1);
      expect(firstRun, isTrue);

      final backupFile = File(
        '$tempRoot/${AppConstants.autoBackupFolderName}/${AppConstants.autoBackupFileName}',
      );
      expect(backupFile.existsSync(), isTrue);
      final firstContent = jsonDecode(backupFile.readAsStringSync());
      expect(firstContent['transactions'], hasLength(1));

      // Same day lagi → tidak jalan ulang.
      final secondRun = await repo.runDailyAutoBackupIfDue(now: day1);
      expect(secondRun, isFalse);

      // Data berubah, lalu backup di hari berikutnya → file lama ditimpa,
      // bukan file baru dibuat di samping yang lama.
      await prefs.setString(
        AppConstants.kTransactions,
        jsonEncode([_txnJson('tx-1', 10000), _txnJson('tx-2', 5000)]),
      );
      final day2 = DateTime(2026, 9, 2);
      final thirdRun = await repo.runDailyAutoBackupIfDue(now: day2);
      expect(thirdRun, isTrue);

      final overwritten = jsonDecode(backupFile.readAsStringSync());
      expect(overwritten['transactions'], hasLength(2));

      final folder = Directory(
        '$tempRoot/${AppConstants.autoBackupFolderName}',
      );
      expect(folder.listSync().length, 1); // tetap satu file, bukan menumpuk.
    },
  );

  test('auto-restore hanya jalan kalau data lokal kosong', () async {
    // Sumber: buat backup dari sebuah repo yang punya data.
    SharedPreferences.setMockInitialValues({});
    final sourcePrefs = await SharedPreferences.getInstance();
    await sourcePrefs.setString(
      AppConstants.kTransactions,
      jsonEncode([_txnJson('tx-1', 25000)]),
    );
    await makeRepo(
      sourcePrefs,
    ).runDailyAutoBackupIfDue(now: DateTime(2026, 9, 1));

    // Target kosong (mis. baru install) → harus ke-restore otomatis.
    SharedPreferences.setMockInitialValues({});
    final emptyPrefs = await SharedPreferences.getInstance();
    final emptyRepo = makeRepo(emptyPrefs);

    final restored = await emptyRepo.restoreFromAutoBackupIfEmpty();
    expect(restored, isTrue);
    final restoredTransactions =
        jsonDecode(emptyPrefs.getString(AppConstants.kTransactions)!) as List;
    expect(restoredTransactions.single['id'], 'tx-1');

    // Target yang SUDAH punya data → tidak boleh ditimpa otomatis.
    SharedPreferences.setMockInitialValues({});
    final existingPrefs = await SharedPreferences.getInstance();
    await existingPrefs.setString(
      AppConstants.kTransactions,
      jsonEncode([_txnJson('tx-existing', 1000)]),
    );
    final existingRepo = makeRepo(existingPrefs);
    final restoredAgain = await existingRepo.restoreFromAutoBackupIfEmpty();
    expect(restoredAgain, isFalse);
    final untouched =
        jsonDecode(existingPrefs.getString(AppConstants.kTransactions)!)
            as List;
    expect(untouched.single['id'], 'tx-existing');
  });

  test(
    'regresi: setelah backup pertama jalan, restore tak lagi menimpa walau transaksi masih kosong',
    () async {
      // Skenario nyata: install baru, backup harian pertama sempat jalan
      // SEBELUM onboarding selesai (onboardingSeen masih false), lalu user
      // menyelesaikan onboarding tapi belum sempat catat transaksi apa pun.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = makeRepo(prefs);

      // Backup pertama: onboarding belum selesai, transaksi kosong.
      await repo.runDailyAutoBackupIfDue(now: DateTime(2026, 9, 1, 8));
      // Onboarding baru saja diselesaikan setelahnya.
      await prefs.setBool(AppConstants.kOnboardingSeen, true);

      // Buka app lagi (masih transaksi kosong) → TIDAK boleh restore dari
      // backup lama yang masih mencatat onboardingSeen=false.
      final restored = await repo.restoreFromAutoBackupIfEmpty();
      expect(restored, isFalse);
      expect(prefs.getBool(AppConstants.kOnboardingSeen), isTrue);
    },
  );
}

Map<String, dynamic> _txnJson(String id, int amount) => MoneyTransactionModel(
  id: id,
  type: TransactionType.expense,
  amount: amount,
  categoryId: 'exp_food',
  walletId: 'cash',
  date: DateTime(2026, 8, 30),
).toJson();
