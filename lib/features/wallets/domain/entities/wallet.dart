import 'package:flutter/material.dart';

/// Entitas dompet/akun tempat uang disimpan (tunai, bank, e-wallet).
///
/// Transaksi mengacu ke dompet lewat [id] sehingga saldo tiap dompet terpisah.
@immutable
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.initialBalance = 0,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  /// Saldo awal dompet dalam Rupiah (sebelum transaksi tercatat).
  final int initialBalance;
}
