import 'package:flutter/foundation.dart';

import '../../../../core/enums/transaction_type.dart';

/// Kategori yang ditemukan saat data eksternal diimpor.
///
/// ID dibuat deterministik dari jenis dan nama, supaya transaksi impor selalu
/// menunjuk ke kategori yang sama saat file yang sama diimpor kembali.
@immutable
class CategoryImport {
  const CategoryImport({required this.name, required this.type});

  final String name;
  final TransactionType type;

  String get id => customIdFor(name: name, type: type);

  static String customIdFor({
    required String name,
    required TransactionType type,
  }) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    // Nama kategori yang seluruhnya non-Latin tetap memperoleh ID stabil.
    final safeSlug = slug.isEmpty ? name.trim().runes.join('-') : slug;
    return 'custom_${type.key}_$safeSlug';
  }
}
