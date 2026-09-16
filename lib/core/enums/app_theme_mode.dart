import '../l10n/app_strings.dart';

/// Pilihan mode tampilan: ikut sistem, paksa terang, atau paksa gelap.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Kunci penyimpanan yang stabil (tidak bergantung urutan enum).
  String get key => name;

  String get label => switch (this) {
    AppThemeMode.system => AppStrings.t.themeSystem,
    AppThemeMode.light => AppStrings.t.themeLight,
    AppThemeMode.dark => AppStrings.t.themeDark,
  };

  static AppThemeMode fromKey(String? key) {
    return AppThemeMode.values.firstWhere(
      (e) => e.key == key,
      orElse: () => AppThemeMode.system,
    );
  }
}
