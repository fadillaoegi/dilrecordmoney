import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mengatur apakah nominal Total Saldo & Pemasukan disamarkan.
///
/// Pengeluaran sengaja selalu terlihat — nominal yang biasanya "sensitif"
/// buat dilihat orang lain adalah seberapa banyak uang yang dimiliki/masuk,
/// bukan seberapa banyak yang dikeluarkan.
class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final balanceVisibilityProvider =
    NotifierProvider<BalanceVisibilityNotifier, bool>(
      BalanceVisibilityNotifier.new,
    );
