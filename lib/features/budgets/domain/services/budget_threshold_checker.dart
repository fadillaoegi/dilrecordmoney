import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/budget.dart';

/// Informasi peringatan saat transaksi membuat anggaran mencapai batas.
class BudgetThresholdAlert {
  const BudgetThresholdAlert({
    required this.categoryId,
    required this.limit,
    required this.spendingAfter,
  });

  final String categoryId;
  final int limit;
  final int spendingAfter;

  bool get isExceeded => spendingAfter > limit;
}

/// Mendeteksi transisi penggunaan anggaran dari di bawah menjadi mencapai
/// atau melewati batas. Kondisi yang sudah melewati batas tidak diperingatkan
/// berulang kali pada setiap transaksi berikutnya.
class BudgetThresholdChecker {
  BudgetThresholdChecker._();

  static BudgetThresholdAlert? check({
    required MoneyTransaction transaction,
    required Iterable<MoneyTransaction> existingTransactions,
    required Iterable<Budget> budgets,
  }) {
    if (!transaction.type.isExpense) return null;

    Budget? matchingBudget;
    for (final budget in budgets) {
      if (budget.categoryId == transaction.categoryId &&
          budget.isForMonth(transaction.date.year, transaction.date.month)) {
        matchingBudget = budget;
        break;
      }
    }
    if (matchingBudget == null || matchingBudget.limit <= 0) return null;

    var spendingBefore = 0;
    var spendingAfter = transaction.amount;

    for (final existing in existingTransactions) {
      if (!_matchesTarget(existing, transaction)) continue;

      spendingBefore += existing.amount;
      if (existing.id != transaction.id) {
        spendingAfter += existing.amount;
      }
    }

    if (spendingBefore >= matchingBudget.limit ||
        spendingAfter < matchingBudget.limit) {
      return null;
    }

    return BudgetThresholdAlert(
      categoryId: transaction.categoryId,
      limit: matchingBudget.limit,
      spendingAfter: spendingAfter,
    );
  }

  static bool _matchesTarget(
    MoneyTransaction existing,
    MoneyTransaction transaction,
  ) {
    return existing.type.isExpense &&
        existing.categoryId == transaction.categoryId &&
        existing.date.year == transaction.date.year &&
        existing.date.month == transaction.date.month;
  }
}
