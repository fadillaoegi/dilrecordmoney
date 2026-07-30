import 'dart:convert';

import 'package:dilrecordmoney/core/constants/app_constants.dart';
import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:dilrecordmoney/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:dilrecordmoney/features/backup/domain/failures/backup_failure.dart';
import 'package:dilrecordmoney/features/backup/domain/repositories/backup_repository.dart';
import 'package:dilrecordmoney/features/budgets/data/models/budget_model.dart';
import 'package:dilrecordmoney/features/transactions/data/models/money_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('createSnapshot menghasilkan JSON backup berisi transaksi dan anggaran', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _seedData(prefs);

    final BackupRepository repo = _makeRepo(prefs);
    final snapshot = repo.createSnapshot();
    final json = jsonDecode(snapshot.json) as Map<String, dynamic>;

    expect(json['app'], 'dilrecordmoney');
    expect(json['schemaVersion'], 1);
    expect(json['transactions'], hasLength(1));
    expect(json['budgets'], hasLength(1));
    expect(json['onboardingSeen'], isTrue);
    expect(snapshot.suggestedFileName, startsWith('dilrecordmoney-backup-'));
  });

  test('restore mengganti data lokal dari backup valid', () async {
    SharedPreferences.setMockInitialValues({});
    final sourcePrefs = await SharedPreferences.getInstance();
    await _seedData(sourcePrefs);
    final snapshot = _makeRepo(sourcePrefs).createSnapshot();

    SharedPreferences.setMockInitialValues({});
    final targetPrefs = await SharedPreferences.getInstance();
    await _makeRepo(targetPrefs).restoreFromJson(snapshot.json);

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
    final BackupRepository repo = _makeRepo(prefs);

    expect(
      () => repo.restoreFromJson('{"app":"lain"}'),
      throwsA(isA<BackupFailure>()),
    );
  });
}

BackupRepository _makeRepo(SharedPreferences prefs) =>
    BackupRepositoryImpl(BackupLocalDataSourceImpl(prefs));

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
