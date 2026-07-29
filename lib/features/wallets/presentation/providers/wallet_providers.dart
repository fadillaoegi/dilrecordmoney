import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return const WalletRepositoryImpl();
});

/// Daftar dompet yang tersedia untuk dipilih saat mencatat transaksi.
final walletsProvider = Provider<List<Wallet>>((ref) {
  return ref.watch(walletRepositoryProvider).getWallets();
});

/// Cari dompet berdasarkan id (untuk menampilkan nama/ikon di daftar transaksi).
final walletByIdProvider = Provider.family<Wallet?, String>((ref, id) {
  return ref.watch(walletRepositoryProvider).findById(id);
});
