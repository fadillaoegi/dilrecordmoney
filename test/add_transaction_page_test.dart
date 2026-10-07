import 'package:dilrecordmoney/core/enums/transaction_type.dart';
import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/core/theme/app_colors.dart';
import 'package:dilrecordmoney/features/transactions/domain/entities/money_transaction.dart';
import 'package:dilrecordmoney/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Add transaction page responsif di phone kecil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Catat Transaksi'), findsOneWidget);
    expect(find.text('Catatan (opsional)'), findsOneWidget);
  });

  testWidgets('Add transaction page responsif di tablet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Catat Transaksi'), findsOneWidget);
  });

  group('kategori hasil impor data lama', () {
    Future<void> pump(WidgetTester tester, {MoneyTransaction? initial}) async {
      SharedPreferences.setMockInitialValues({
        'custom_categories': '[{"name":"Motor","type":"expense"}]',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(home: AddTransactionPage(initial: initial)),
        ),
      );
      await tester.pump();
    }

    Finder chipNamed(String name) => find.descendant(
      of: find.byType(ListView).first,
      matching: find.text(name),
    );

    testWidgets('tidak ditawarkan saat mencatat transaksi baru', (
      tester,
    ) async {
      await pump(tester);
      await tester.dragUntilVisible(
        chipNamed('Lainnya'),
        find.byType(ListView).first,
        const Offset(-300, 0),
      );
      expect(chipNamed('Lainnya'), findsOneWidget);
      expect(chipNamed('Motor'), findsNothing);
    });

    testWidgets('tetap tampil saat mengedit transaksi lama', (tester) async {
      await pump(
        tester,
        initial: MoneyTransaction(
          id: 'old',
          type: TransactionType.expense,
          amount: 12500,
          categoryId: 'custom_expense_motor',
          walletId: 'cash',
          date: DateTime(2024, 4, 11),
        ),
      );
      await tester.dragUntilVisible(
        chipNamed('Motor'),
        find.byType(ListView).first,
        const Offset(-300, 0),
      );
      expect(chipNamed('Motor'), findsOneWidget);
    });
  });

  testWidgets('nominal di numpad berwarna tinta (hitam)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.dialpad_rounded));
    await tester.pumpAndSettle();

    final preview = tester.widget<Text>(
      find.byKey(const Key('numpad-amount-preview')),
    );
    expect(preview.style?.color, AppColors.ink);
  });
}
