import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../wallet_catalog.dart';

/// Implementasi [WalletRepository] berbasis preset bawaan.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl();

  @override
  List<Wallet> getWallets() => kDefaultWallets;

  @override
  Wallet? findById(String id) {
    for (final wallet in kDefaultWallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }
}
