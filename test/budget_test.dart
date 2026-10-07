// Menguji repository anggaran & provider ringkasan/pengeluaran per bulan.

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:dilrecordmoney/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:dilrecordmoney/features/budgets/domain/services/budget_threshold_checker.dart';
import 'package:dilrecordmoney/features/budgets/presentation/providers/budget_providers.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BudgetRepository', () {
    late BudgetRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = BudgetRepositoryImpl(BudgetLocalDataSourceImpl(prefs));
    });

    test('set lalu ambil anggaran untuk bulan tertentu', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );

      final budgets = repo.getBudgetsForMonth(2026, 7);
      expect(budgets, hasLength(1));
      expect(budgets.first.limit, 500000);
      // Bulan sebelumnya tidak ikut.
      expect(repo.getBudgetsForMonth(2026, 6), isEmpty);
    });

    test('set ulang kategori sama memperbarui (bukan menduplikasi)', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 750000,
      );

      final budgets = repo.getBudgetsForMonth(2026, 7);
      expect(budgets, hasLength(1));
      expect(budgets.first.limit, 750000);
    });

    test('limit 0 menghapus anggaran', () async {
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 500000,
      );
      await repo.setBudget(
        categoryId: 'exp_food',
        year: 2026,
        month: 7,
        limit: 0,
      );

      expect(repo.getBudgetsForMonth(2026, 7), isEmpty);
    });

    group('anggaran berlanjut ke bulan berikutnya', () {
      Future<void> set(int month, int limit, {int year = 2026}) =>
          repo.setBudget(
            categoryId: 'exp_food',
            year: year,
            month: month,
            limit: limit,
          );
      int? limitIn(int month, {int year = 2026}) {
        final list = repo.getBudgetsForMonth(year, month);
        return list.isEmpty ? null : list.single.limit;
      }

      test('set Juli → Agustus s.d. tahun depan otomatis terisi', () async {
        await set(7, 500000);
        expect(limitIn(8), 500000);
        expect(limitIn(12), 500000);
        expect(limitIn(3, year: 2027), 500000);
        // Bulan hasil turunan membawa bulan yang diminta (dipakai pengecek
        // batas anggaran saat menyimpan transaksi).
        final aug = repo.getBudgetsForMonth(2026, 8).single;
        expect(aug.isForMonth(2026, 8), isTrue);
      });

      test(
        'ubah di Oktober → Oktober dan sesudahnya ikut, Juli–Sep tetap',
        () async {
          await set(7, 500000);
          await set(10, 800000);
          expect(limitIn(9), 500000);
          expect(limitIn(10), 800000);
          expect(limitIn(11), 800000);
        },
      );

      test(
        'contoh: Transport Okt 300rb, Des diupdate 400rb, lalu Okt diubah',
        () async {
          await set(9, 250000); // nilai lama September
          await set(10, 300000);
          expect(limitIn(9), 250000); // bulan lalu tidak ikut terupdate
          expect(limitIn(11), 300000); // bulan berikutnya otomatis sama
          await set(12, 400000); // diupdate lagi di Desember
          expect(limitIn(11), 300000);
          expect(limitIn(12), 400000);
          expect(limitIn(2, year: 2027), 400000);
          // Ubah Oktober → hanya Okt–Nov; Desember sudah punya pembaruan
          // sendiri jadi tetap 400rb.
          await set(10, 350000);
          expect(limitIn(9), 250000);
          expect(limitIn(10), 350000);
          expect(limitIn(11), 350000);
          expect(limitIn(12), 400000);
        },
      );

      test(
        'hapus di Oktober menghentikan anggaran mulai Oktober saja',
        () async {
          await set(7, 500000);
          await set(10, 0);
          expect(limitIn(9), 500000);
          expect(limitIn(10), isNull);
          expect(limitIn(12), isNull);
          // Set lagi di Desember → berlaku lagi mulai Desember.
          await set(12, 300000);
          expect(limitIn(11), isNull);
          expect(limitIn(12), 300000);
        },
      );
    });
  });

  test('pengecek batas memakai anggaran yang terbawa', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSourceImpl(prefs));
    await repo.setBudget(
      categoryId: 'exp_food',
      year: 2026,
      month: 7,
      limit: 100000,
    );
    final tx = MoneyTransaction(
      id: 'new',
      type: TransactionType.expense,
      amount: 120000,
      categoryId: 'exp_food',
      walletId: 'cash',
      date: DateTime(2026, 9, 3),
    );
    final alert = BudgetThresholdChecker.check(
      transaction: tx,
      existingTransactions: const [],
      budgets: repo.getBudgetsForMonth(2026, 9),
    );
    expect(alert?.limit, 100000);
    expect(alert?.isExceeded, isTrue);
  });

  test('spending & summary provider menghitung terpakai vs anggaran', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Anggaran Makan Juli 2026 = 100.000
    container.read(budgetMonthProvider.notifier).state = DateTime(2026, 7);
    await container
        .read(monthlyBudgetsProvider.notifier)
        .setBudget('exp_food', 100000);

    // Dua pengeluaran Makan di Juli, satu di bulan lain (tidak dihitung).
    final txNotifier = container.read(transactionListProvider.notifier);
    await txNotifier.addTransaction(_food(DateTime(2026, 7, 5), 30000));
    await txNotifier.addTransaction(_food(DateTime(2026, 7, 20), 40000));
    await txNotifier.addTransaction(_food(DateTime(2026, 8, 1), 99000));

    final spending = container.read(monthlySpendingProvider);
    expect(spending['exp_food'], 70000);

    final summary = container.read(budgetSummaryProvider);
    expect(summary.totalBudget, 100000);
    expect(summary.totalSpent, 70000);
  });
}

MoneyTransaction _food(DateTime date, int amount) => MoneyTransaction(
  id: IdGenerator.generate(),
  type: TransactionType.expense,
  amount: amount,
  categoryId: 'exp_food',
  walletId: 'cash',
  date: date,
);
