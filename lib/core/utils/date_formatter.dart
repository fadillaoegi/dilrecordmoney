import '../l10n/app_strings.dart';

/// Format tanggal ringkas tanpa dependency `intl`.
///
/// Nama bulan & hari diambil dari [AppStrings] sehingga ikut bahasa aktif.
class DateFormatter {
  DateFormatter._();

  /// Contoh (id): `"28 Jul 2026"`.
  static String short(DateTime date) {
    return '${date.day} ${AppStrings.t.months[date.month - 1]} ${date.year}';
  }

  /// Contoh (id): `"Sen, 28 Jul 2026"`.
  static String withDay(DateTime date) {
    return '${AppStrings.t.days[date.weekday - 1]}, ${short(date)}';
  }

  /// Contoh (id): `"Juli 2026"`.
  static String monthYear(DateTime date) {
    return '${AppStrings.t.monthsFull[date.month - 1]} ${date.year}';
  }

  /// Label relatif untuk tanggal umum: "Hari ini" / "Kemarin".
  static String relative(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final target = _dateOnly(date);
    final diff = today.difference(target).inDays;
    return switch (diff) {
      0 => AppStrings.t.today,
      1 => AppStrings.t.yesterday,
      _ => short(date),
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
