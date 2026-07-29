import 'package:flutter/foundation.dart';

import '../../../../core/enums/period_type.dart';

/// Rentang periode aktif = jenis periode + tanggal jangkar (anchor).
///
/// Menghitung [start] (inklusif) dan [end] (eksklusif) sehingga transaksi
/// bisa disaring dengan [contains].
@immutable
class PeriodSelection {
  const PeriodSelection({required this.type, required this.anchor});

  final PeriodType type;
  final DateTime anchor;

  DateTime get start => switch (type) {
        PeriodType.daily => DateTime(anchor.year, anchor.month, anchor.day),
        PeriodType.weekly => _startOfWeek(anchor),
        PeriodType.monthly => DateTime(anchor.year, anchor.month, 1),
        PeriodType.yearly => DateTime(anchor.year, 1, 1),
      };

  DateTime get end => switch (type) {
        PeriodType.daily => start.add(const Duration(days: 1)),
        PeriodType.weekly => start.add(const Duration(days: 7)),
        PeriodType.monthly => DateTime(anchor.year, anchor.month + 1, 1),
        PeriodType.yearly => DateTime(anchor.year + 1, 1, 1),
      };

  /// Hari terakhir dalam rentang (inklusif) — berguna untuk label.
  DateTime get lastDay => end.subtract(const Duration(days: 1));

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  PeriodSelection copyWith({PeriodType? type, DateTime? anchor}) {
    return PeriodSelection(type: type ?? this.type, anchor: anchor ?? this.anchor);
  }

  /// Menggeser jangkar maju/mundur satu satuan sesuai [type].
  PeriodSelection shift(int direction) {
    final a = anchor;
    final moved = switch (type) {
      PeriodType.daily => a.add(Duration(days: direction)),
      PeriodType.weekly => a.add(Duration(days: 7 * direction)),
      PeriodType.monthly => DateTime(a.year, a.month + direction, 1),
      PeriodType.yearly => DateTime(a.year + direction, 1, 1),
    };
    return copyWith(anchor: moved);
  }

  static DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1)); // Senin sebagai awal
  }
}
