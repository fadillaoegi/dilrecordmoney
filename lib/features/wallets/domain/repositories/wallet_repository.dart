import '../entities/wallet.dart';

/// Kontrak akses data dompet.
///
/// Saat ini hanya baca (preset bawaan). Nanti bisa diperluas dengan
/// tambah/ubah/hapus dompet kustom tanpa mengubah layer presentasi.
abstract interface class WalletRepository {
  List<Wallet> getWallets();
  Wallet? findById(String id);
}
