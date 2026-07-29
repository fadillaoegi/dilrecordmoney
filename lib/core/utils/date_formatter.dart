/// Format tanggal ringkas berbahasa Indonesia tanpa dependency `intl`.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _monthsFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _days = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  /// Contoh: `"28 Jul 2026"`.
  static String short(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Contoh: `"Sen, 28 Jul 2026"`.
  static String withDay(DateTime date) {
    return '${_days[date.weekday - 1]}, ${short(date)}';
  }

  /// Contoh: `"Juli 2026"`.
  static String monthYear(DateTime date) {
    return '${_monthsFull[date.month - 1]} ${date.year}';
  }

  /// Label relatif untuk tanggal umum: "Hari ini" / "Kemarin".
  static String relative(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final target = _dateOnly(date);
    final diff = today.difference(target).inDays;
    return switch (diff) {
      0 => 'Hari ini',
      1 => 'Kemarin',
      _ => short(date),
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
