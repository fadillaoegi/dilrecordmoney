import '../entities/money_transaction.dart';

/// Kontrak penyimpanan transaksi.
///
/// Layer domain hanya mendefinisikan operasinya; implementasi (SharedPreferences
/// sekarang, database nanti) berada di layer data dan bisa ditukar bebas.
abstract interface class TransactionRepository {
  /// Semua transaksi, terbaru lebih dulu.
  Future<List<MoneyTransaction>> getTransactions();

  Future<void> add(MoneyTransaction transaction);

  Future<void> update(MoneyTransaction transaction);

  Future<void> delete(String id);
}
