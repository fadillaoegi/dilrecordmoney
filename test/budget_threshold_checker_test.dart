import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/budgets/domain/entities/budget.dart';
import 'package:dilrecordmoney/features/budgets/domain/services/budget_threshold_checker.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetThresholdChecker', () {
    test('memberi peringatan saat pengeluaran tepat mencapai batas', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(id: 'new', amount: 60000),
        existingTransactions: [_transaction(id: 'old', amount: 40000)],
        budgets: [_budget(100000)],
      );

      expect(alert, isNotNull);
      expect(alert!.spendingAfter, 100000);
      expect(alert.limit, 100000);
      expect(alert.isExceeded, isFalse);
    });

    test('memberi peringatan saat pengeluaran melewati batas', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(id: 'new', amount: 30000),
        existingTransactions: [_transaction(id: 'old', amount: 80000)],
        budgets: [_budget(100000)],
      );

      expect(alert, isNotNull);
      expect(alert!.spendingAfter, 110000);
      expect(alert.isExceeded, isTrue);
    });

    test('tidak memberi peringatan selama masih di bawah batas', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(id: 'new', amount: 50000),
        existingTransactions: [_transaction(id: 'old', amount: 40000)],
        budgets: [_budget(100000)],
      );

      expect(alert, isNull);
    });

    test('tidak mengulang peringatan jika sebelumnya sudah melewati batas', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(id: 'new', amount: 10000),
        existingTransactions: [_transaction(id: 'old', amount: 110000)],
        budgets: [_budget(100000)],
      );

      expect(alert, isNull);
    });

    test('edit transaksi dihitung sebagai penggantian nominal lama', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(id: 'edited', amount: 80000),
        existingTransactions: [
          _transaction(id: 'edited', amount: 60000),
          _transaction(id: 'other', amount: 30000),
        ],
        budgets: [_budget(100000)],
      );

      expect(alert, isNotNull);
      expect(alert!.spendingAfter, 110000);
    });

    test('pemasukan tidak pernah memicu peringatan anggaran', () {
      final alert = BudgetThresholdChecker.check(
        transaction: _transaction(
          id: 'income',
          amount: 120000,
          type: TransactionType.income,
        ),
        existingTransactions: const [],
        budgets: [_budget(100000)],
      );

      expect(alert, isNull);
    });
  });
}

Budget _budget(int limit) => Budget(
  id: 'budget-food-2026-08',
  categoryId: 'exp_food',
  year: 2026,
  month: 8,
  limit: limit,
);

MoneyTransaction _transaction({
  required String id,
  required int amount,
  TransactionType type = TransactionType.expense,
}) => MoneyTransaction(
  id: id,
  type: type,
  amount: amount,
  categoryId: 'exp_food',
  walletId: 'cash',
  date: DateTime(2026, 8, 18),
);
