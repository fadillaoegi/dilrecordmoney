import 'dart:convert';

import 'package:dilrecordmoney/core/constants/app_constants.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/backup/data/data_backup_service.dart';
import 'package:dilrecordmoney/features/budgets/data/models/budget_model.dart';
import 'package:dilrecordmoney/features/transactions/data/models/money_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('export membuat JSON backup berisi transaksi dan anggaran', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _seedData(prefs);

    final service = DataBackupService(prefs);
    final raw = service.createBackupJson(exportedAt: DateTime(2026, 7, 29));
    final json = jsonDecode(raw) as Map<String, dynamic>;

    expect(json['app'], 'dilrecordmoney');
    expect(json['schemaVersion'], 1);
    expect(json['transactions'], hasLength(1));
    expect(json['budgets'], hasLength(1));
    expect(json['onboardingSeen'], isTrue);
  });

  test('restore mengganti data lokal dari file backup valid', () async {
    SharedPreferences.setMockInitialValues({});
    final sourcePrefs = await SharedPreferences.getInstance();
    await _seedData(sourcePrefs);
    final backupRaw = DataBackupService(sourcePrefs).createBackupJson();

    SharedPreferences.setMockInitialValues({});
    final targetPrefs = await SharedPreferences.getInstance();
    await DataBackupService(targetPrefs).restoreBackupJson(backupRaw);

    final transactions =
        jsonDecode(targetPrefs.getString(AppConstants.kTransactions)!) as List;
    final budgets =
        jsonDecode(targetPrefs.getString(AppConstants.kBudgets)!) as List;
    expect(transactions.single['amount'], 25000);
    expect(budgets.single['limit'], 100000);
    expect(targetPrefs.getBool(AppConstants.kOnboardingSeen), isTrue);
  });

  test('restore menolak file yang bukan backup aplikasi', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = DataBackupService(prefs);

    expect(
      () => service.restoreBackupJson('{"app":"lain"}'),
      throwsA(isA<BackupDataException>()),
    );
  });
}

Future<void> _seedData(SharedPreferences prefs) async {
  final transaction = MoneyTransactionModel(
    id: 'tx-1',
    type: TransactionType.expense,
    amount: 25000,
    categoryId: 'exp_food',
    walletId: 'cash',
    date: DateTime(2026, 7, 29),
  );
  final budget = const BudgetModel(
    id: 'budget-1',
    categoryId: 'exp_food',
    year: 2026,
    month: 7,
    limit: 100000,
  );

  await prefs.setString(
    AppConstants.kTransactions,
    jsonEncode([transaction.toJson()]),
  );
  await prefs.setString(AppConstants.kBudgets, jsonEncode([budget.toJson()]));
  await prefs.setBool(AppConstants.kOnboardingSeen, true);
}
