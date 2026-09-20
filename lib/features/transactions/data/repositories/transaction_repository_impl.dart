import '../../domain/entities/money_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../models/money_transaction_model.dart';

/// Implementasi [TransactionRepository] di atas sumber data lokal.
///
/// Menjaga daftar tetap terurut (terbaru dulu) dan memetakan entitas ↔ model.
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._local);

  final TransactionLocalDataSource _local;

  @override
  Future<List<MoneyTransaction>> getTransactions() async {
    final items = _local.readAll()..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Future<void> add(MoneyTransaction transaction) async {
    final items = _local.readAll()
      ..add(MoneyTransactionModel.fromEntity(transaction));
    await _local.writeAll(items);
  }

  @override
  Future<void> addAll(List<MoneyTransaction> transactions) async {
    if (transactions.isEmpty) return;
    final items = _local.readAll()
      ..addAll(transactions.map(MoneyTransactionModel.fromEntity));
    await _local.writeAll(items);
  }

  @override
  Future<void> update(MoneyTransaction transaction) async {
    final items = _local.readAll();
    final index = items.indexWhere((e) => e.id == transaction.id);
    if (index == -1) return;
    items[index] = MoneyTransactionModel.fromEntity(transaction);
    await _local.writeAll(items);
  }

  @override
  Future<void> delete(String id) async {
    final items = _local.readAll()..removeWhere((e) => e.id == id);
    await _local.writeAll(items);
  }
}
