import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';

/// State formulir pencatatan transaksi (dikelola oleh [TransactionFormNotifier]).
@immutable
class TransactionFormState {
  const TransactionFormState({
    required this.date,
    this.type = TransactionType.expense,
    this.amount = 0,
    this.categoryId,
    this.walletId = 'cash',
    this.note = '',
  });

  final TransactionType type;

  /// Nominal dalam Rupiah utuh (positif). Dibangun lewat keypad.
  final int amount;

  /// Boleh null → nanti dipetakan ke kategori "Lainnya" saat disimpan.
  final String? categoryId;
  final String walletId;
  final DateTime date;
  final String note;

  /// Minimal syarat simpan: ada nominal. Kategori opsional (punya fallback).
  bool get isValid => amount > 0;

  TransactionFormState copyWith({
    TransactionType? type,
    int? amount,
    String? categoryId,
    bool clearCategory = false,
    String? walletId,
    DateTime? date,
    String? note,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}

class TransactionFormNotifier extends Notifier<TransactionFormState> {
  /// Batas nominal (di bawah 1 miliar) agar tampilan tidak meluap.
  static const int _maxAmount = 999999999;

  @override
  TransactionFormState build() => TransactionFormState(date: DateTime.now());

  void setType(TransactionType type) {
    if (type == state.type) return;
    // Kategori pemasukan & pengeluaran berbeda → reset saat ganti jenis.
    state = state.copyWith(type: type, clearCategory: true);
  }

  void appendDigit(int digit) {
    final next = state.amount * 10 + digit;
    if (next > _maxAmount) return;
    state = state.copyWith(amount: next);
  }

  /// Tombol "000" — menambah tiga nol sekaligus.
  void appendThousands() {
    if (state.amount == 0) return;
    final next = state.amount * 1000;
    if (next > _maxAmount) return;
    state = state.copyWith(amount: next);
  }

  void deleteDigit() {
    state = state.copyWith(amount: state.amount ~/ 10);
  }

  void setCategory(String id) => state = state.copyWith(categoryId: id);

  void setWallet(String id) => state = state.copyWith(walletId: id);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setNote(String note) => state = state.copyWith(note: note);
}

final transactionFormProvider =
    NotifierProvider<TransactionFormNotifier, TransactionFormState>(
  TransactionFormNotifier.new,
);
