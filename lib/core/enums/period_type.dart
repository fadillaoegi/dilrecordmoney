import '../l10n/app_strings.dart';

/// Granularitas periode untuk memfilter & meringkas transaksi.
enum PeriodType {
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
    PeriodType.daily => AppStrings.t.daily,
    PeriodType.weekly => AppStrings.t.weekly,
    PeriodType.monthly => AppStrings.t.monthly,
    PeriodType.yearly => AppStrings.t.yearly,
  };
}
