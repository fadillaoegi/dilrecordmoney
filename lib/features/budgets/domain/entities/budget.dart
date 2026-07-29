import 'package:flutter/foundation.dart';

/// Anggaran satu kategori untuk satu bulan tertentu.
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limit,
  });

  final String id;
  final String categoryId;
  final int year;

  /// 1–12.
  final int month;

  /// Batas anggaran dalam Rupiah utuh.
  final int limit;

  bool isForMonth(int year, int month) => this.year == year && this.month == month;

  Budget copyWith({int? limit}) {
    return Budget(
      id: id,
      categoryId: categoryId,
      year: year,
      month: month,
      limit: limit ?? this.limit,
    );
  }
}
