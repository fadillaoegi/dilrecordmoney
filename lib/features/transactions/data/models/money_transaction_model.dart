import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/money_transaction.dart';

/// Model data transaksi: memperluas entitas domain dengan (de)serialisasi JSON.
class MoneyTransactionModel extends MoneyTransaction {
  const MoneyTransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.categoryId,
    required super.walletId,
    required super.date,
    super.note,
  });

  factory MoneyTransactionModel.fromEntity(MoneyTransaction t) {
    return MoneyTransactionModel(
      id: t.id,
      type: t.type,
      amount: t.amount,
      categoryId: t.categoryId,
      walletId: t.walletId,
      date: t.date,
      note: t.note,
    );
  }

  factory MoneyTransactionModel.fromJson(Map<String, dynamic> json) {
    return MoneyTransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromKey(json['type'] as String),
      amount: json['amount'] as int,
      categoryId: json['categoryId'] as String,
      walletId: json['walletId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.key,
      'amount': amount,
      'categoryId': categoryId,
      'walletId': walletId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}
