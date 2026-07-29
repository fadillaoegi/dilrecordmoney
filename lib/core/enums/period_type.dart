/// Granularitas periode untuk memfilter & meringkas transaksi.
enum PeriodType {
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
    PeriodType.daily => 'Harian',
    PeriodType.weekly => 'Mingguan',
    PeriodType.monthly => 'Bulanan',
    PeriodType.yearly => 'Tahunan',
  };
}
