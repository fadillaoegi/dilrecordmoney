import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';

/// Entitas kategori transaksi (mis. Makan, Transport, Gaji).
///
/// Kategori dipisah per [type]: kategori pemasukan berbeda dari pengeluaran.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;
}
