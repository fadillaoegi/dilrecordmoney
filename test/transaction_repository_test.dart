// Menguji simpan/muat transaksi lewat repository + datasource lokal.

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:dilrecordmoney/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TransactionRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = TransactionRepositoryImpl(TransactionLocalDataSourceImpl(prefs));
  });

  MoneyTransaction make(
    String id,
    DateTime date,
    TransactionType type,
    int amount,
  ) {
    return MoneyTransaction(
      id: id,
      type: type,
      amount: amount,
      categoryId: 'exp_food',
      walletId: 'cash',
      date: date,
    );
  }

  test(
    'menambah lalu memuat kembali transaksi (roundtrip serialisasi)',
    () async {
      await repo.add(
        make('1', DateTime(2026, 7, 28), TransactionType.expense, 25000),
      );

      final result = await repo.getTransactions();

      expect(result, hasLength(1));
      expect(result.first.amount, 25000);
      expect(result.first.type, TransactionType.expense);
      expect(result.first.signedAmount, -25000);
      expect(result.first.date, DateTime(2026, 7, 28));
    },
  );

  test('mengurutkan transaksi terbaru lebih dulu', () async {
    await repo.add(
      make('lama', DateTime(2026, 1, 1), TransactionType.income, 1000),
    );
    await repo.add(
      make('baru', DateTime(2026, 7, 1), TransactionType.income, 2000),
    );

    final result = await repo.getTransactions();

    expect(result.map((e) => e.id).toList(), ['baru', 'lama']);
  });

  test('mengubah transaksi tetap mempertahankan id yang sama', () async {
    await repo.add(make('tetap', DateTime(2026, 7, 1), TransactionType.expense, 5000));

    await repo.update(MoneyTransaction(
      id: 'tetap',
      type: TransactionType.expense,
      amount: 9000,
      categoryId: 'exp_food',
      walletId: 'cash',
      date: DateTime(2026, 7, 1),
      note: 'diperbarui',
    ));

    final result = await repo.getTransactions();
    expect(result, hasLength(1));
    expect(result.first.id, 'tetap');
    expect(result.first.amount, 9000);
    expect(result.first.note, 'diperbarui');
  });

  test('menghapus transaksi berdasarkan id', () async {
    await repo.add(
      make('1', DateTime(2026, 7, 1), TransactionType.expense, 5000),
    );
    await repo.add(
      make('2', DateTime(2026, 7, 2), TransactionType.expense, 7000),
    );

    await repo.delete('1');

    final result = await repo.getTransactions();
    expect(result.map((e) => e.id), ['2']);
  });
}
