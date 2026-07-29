import 'package:flutter/foundation.dart';

import '../../../../core/enums/transaction_type.dart';

/// Entitas satu catatan uang masuk/keluar.
///
/// Bernama `MoneyTransaction` (bukan `Transaction`) agar tidak bentrok dengan
/// tipe `Transaction` milik paket database saat nanti dipakai.
@immutable
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
  });

  final String id;
  final TransactionType type;

  /// Nominal dalam Rupiah utuh, selalu positif. Arah (masuk/keluar)
  /// ditentukan oleh [type], bukan tanda nominal.
  final int amount;

  final String categoryId;
  final String walletId;
  final DateTime date;
  final String? note;

  /// Nominal bertanda untuk perhitungan saldo: pengeluaran negatif.
  int get signedAmount => type.isExpense ? -amount : amount;

  MoneyTransaction copyWith({
    String? id,
    TransactionType? type,
    int? amount,
    String? categoryId,
    String? walletId,
    DateTime? date,
    String? note,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
