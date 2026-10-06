import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_settings_providers.dart';

import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return const WalletRepositoryImpl();
});

/// Daftar dompet yang tersedia untuk dipilih saat mencatat transaksi.
final walletsProvider = Provider<List<Wallet>>((ref) {
  ref.watch(appearanceProvider); // nama & warna dompet ikut tema/bahasa
  return ref.watch(walletRepositoryProvider).getWallets();
});

/// Cari dompet berdasarkan id (untuk menampilkan nama/ikon di daftar transaksi).
final walletByIdProvider = Provider.family<Wallet?, String>((ref, id) {
  ref.watch(appearanceProvider);
  return ref.watch(walletRepositoryProvider).findById(id);
});
