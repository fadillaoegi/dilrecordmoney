/// Jenis transaksi: uang masuk (pemasukan) atau keluar (pengeluaran).
///
/// Diletakkan di `core` karena dipakai lintas fitur (kategori & transaksi).
enum TransactionType {
  income,
  expense;

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;

  String get label => switch (this) {
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Pengeluaran',
      };

  /// Untuk (de)serialisasi yang stabil (tidak bergantung urutan enum).
  String get key => name;

  static TransactionType fromKey(String key) => TransactionType.values.firstWhere(
        (e) => e.name == key,
        orElse: () => TransactionType.expense,
      );
}
