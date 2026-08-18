// Menguji riwayat sugesti catatan yang di-derive dari transaksi.

import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/utils/id_generator.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/note_history_provider.dart';
import 'package:dilrecordmoney/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('filterNoteSuggestions', () {
    test('query kosong → seluruh riwayat (maks 6)', () {
      final history = List.generate(10, (i) => 'note $i');
      expect(filterNoteSuggestions(history, ''), hasLength(6));
    });

    test('filter substring case-insensitive', () {
      final history = ['Kopi Starbucks', 'Bakso Malang', 'Kopi Kenangan'];
      expect(
        filterNoteSuggestions(history, 'kopi'),
        ['Kopi Starbucks', 'Kopi Kenangan'],
      );
    });

    test('kecualikan yang sama persis dengan query', () {
      final history = ['Kopi', 'Kopi Susu'];
      expect(filterNoteSuggestions(history, 'kopi'), ['Kopi Susu']);
    });
  });

  test('noteHistoryProvider dedup + urut terbaru dulu', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionListProvider.notifier);
    await notifier.addTransaction(_expense(DateTime(2026, 7, 1), 'Kopi'));
    await notifier.addTransaction(_expense(DateTime(2026, 7, 15), 'Bakso'));
    // Kopi dipakai lagi lebih baru → harus muncul lebih dulu dari Bakso.
    await notifier.addTransaction(_expense(DateTime(2026, 7, 20), 'kopi'));
    // Catatan kosong tidak masuk riwayat.
    await notifier.addTransaction(_expense(DateTime(2026, 7, 25), null));

    final history = container.read(noteHistoryProvider);
    expect(history, ['kopi', 'Bakso']);
  });
}

MoneyTransaction _expense(DateTime date, String? note) => MoneyTransaction(
      id: IdGenerator.generate(),
      type: TransactionType.expense,
      amount: 5000,
      categoryId: 'exp_food',
      walletId: 'cash',
      date: date,
      note: note,
    );
