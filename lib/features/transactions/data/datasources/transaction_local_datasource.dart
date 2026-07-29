import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/money_transaction_model.dart';

/// Sumber data lokal untuk transaksi.
///
/// Implementasi awal menyimpan seluruh daftar sebagai JSON di SharedPreferences.
/// Cukup untuk MVP; bisa diganti sqflite/drift/isar tanpa mengubah repository.
abstract interface class TransactionLocalDataSource {
  List<MoneyTransactionModel> readAll();
  Future<void> writeAll(List<MoneyTransactionModel> transactions);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'transactions';

  @override
  List<MoneyTransactionModel> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MoneyTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> writeAll(List<MoneyTransactionModel> transactions) {
    final encoded = jsonEncode(transactions.map((e) => e.toJson()).toList());
    return _prefs.setString(_key, encoded);
  }
}
