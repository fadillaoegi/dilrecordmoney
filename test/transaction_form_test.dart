// Menguji logika formulir input transaksi & provider ringkasan.

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_form_provider.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TransactionFormNotifier', () {
    test('keypad membangun nominal: digit, 000, dan hapus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(transactionFormProvider.notifier);

      notifier.appendDigit(2);
      notifier.appendDigit(5);
      expect(container.read(transactionFormProvider).amount, 25);

      notifier.appendThousands(); // 25 → 25000
      expect(container.read(transactionFormProvider).amount, 25000);

      notifier.deleteDigit(); // 25000 → 2500
      expect(container.read(transactionFormProvider).amount, 2500);
    });

    test('ganti jenis transaksi mereset kategori terpilih', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(transactionFormProvider.notifier);

      notifier.setCategory('exp_food');
      expect(container.read(transactionFormProvider).categoryId, 'exp_food');

      notifier.setType(TransactionType.income);
      expect(container.read(transactionFormProvider).categoryId, isNull);
      expect(container.read(transactionFormProvider).type, TransactionType.income);
    });

    test('isValid hanya true saat ada nominal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(transactionFormProvider.notifier);

      expect(container.read(transactionFormProvider).isValid, isFalse);
      notifier.appendDigit(1);
      expect(container.read(transactionFormProvider).isValid, isTrue);
    });
  });

  test('summary provider mencerminkan transaksi tersimpan', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionListProvider.notifier);
    await notifier.addTransaction(MoneyTransaction(
      id: IdGenerator.generate(),
      type: TransactionType.income,
      amount: 100000,
      categoryId: 'inc_salary',
      walletId: 'bank',
      date: DateTime(2026, 7, 1),
    ));
    await notifier.addTransaction(MoneyTransaction(
      id: IdGenerator.generate(),
      type: TransactionType.expense,
      amount: 30000,
      categoryId: 'exp_food',
      walletId: 'cash',
      date: DateTime(2026, 7, 2),
    ));

    final summary = container.read(transactionSummaryProvider);
    expect(summary.totalIncome, 100000);
    expect(summary.totalExpense, 30000);
    expect(summary.balance, 70000);
    expect(summary.count, 2);
  });
}
