import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/categories/data/category_catalog.dart';
import 'package:dilrecordmoney/features/home/presentation/pages/home_page.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saldo disamarkan dan bisa ditampilkan kembali', (tester) async {
    await _pumpHome(tester, _transactions(1));

    Text balance = tester.widget(find.byKey(const Key('balance-value')));
    expect(balance.data, 'Rp ••••••••');

    await tester.tap(find.byKey(const Key('balance-visibility-toggle')));
    await tester.pump();

    balance = tester.widget(find.byKey(const Key('balance-value')));
    expect(balance.data, 'Rp1.000');
  });

  testWidgets('kartu saldo tetap rapi di layar kecil', (tester) async {
    await _pumpHome(
      tester,
      _transactions(1),
      surfaceSize: const Size(379, 800),
    );

    expect(tester.takeException(), isNull);
    final balance = tester.widget<Text>(find.byKey(const Key('balance-value')));
    expect(balance.style?.fontSize, lessThan(40));
  });

  testWidgets('transaksi dimuat bertahap sebanyak 10 item', (tester) async {
    await _pumpHome(tester, _transactions(25));

    expect(find.byType(Dismissible), findsNWidgets(10));
    expect(find.text('Muat 10 Lagi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('load-more-transactions')));
    await tester.pump();

    expect(find.byType(Dismissible), findsNWidgets(20));
    expect(find.text('Muat 5 Lagi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('load-more-transactions')));
    await tester.pump();

    expect(find.byType(Dismissible), findsNWidgets(25));
    expect(find.byKey(const Key('load-more-transactions')), findsNothing);
  });

  test('katalog pengeluaran memuat kategori Digital dan Game', () {
    final categories = {
      for (final category in CategoryCatalog.expense) category.id: category,
    };

    expect(categories['exp_digital']?.name, 'Digital');
    expect(categories['exp_digital']?.type, TransactionType.expense);
    expect(categories['exp_game']?.name, 'Game');
    expect(categories['exp_game']?.type, TransactionType.expense);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  List<MoneyTransaction> transactions, {
  Size surfaceSize = const Size(900, 4000),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          _FakeTransactionRepository(transactions),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

List<MoneyTransaction> _transactions(int count) {
  final now = DateTime.now();
  return List.generate(
    count,
    (index) => MoneyTransaction(
      id: 'transaction-$index',
      type: TransactionType.income,
      amount: 1000,
      categoryId: 'inc_salary',
      walletId: 'cash',
      date: now.subtract(Duration(minutes: index)),
    ),
  );
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(List<MoneyTransaction> transactions)
    : _transactions = List.of(transactions);

  final List<MoneyTransaction> _transactions;

  @override
  Future<List<MoneyTransaction>> getTransactions() async =>
      List.unmodifiable(_transactions);

  @override
  Future<void> add(MoneyTransaction transaction) async {
    _transactions.insert(0, transaction);
  }

  @override
  Future<void> update(MoneyTransaction transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) _transactions[index] = transaction;
  }

  @override
  Future<void> delete(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }
}
