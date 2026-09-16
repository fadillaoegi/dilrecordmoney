import 'dart:ui';

/// Bahasa yang didukung aplikasi. Default-nya [AppLocale.id].
enum AppLocale {
  id,
  en,
  zh,
  ja;

  /// Kode yang disimpan ke SharedPreferences (stabil, tidak ikut urutan enum).
  String get code => name;

  Locale get locale => switch (this) {
    AppLocale.id => const Locale('id'),
    AppLocale.en => const Locale('en'),
    AppLocale.zh => const Locale('zh'),
    AppLocale.ja => const Locale('ja'),
  };

  /// Nama bahasa dalam bahasanya sendiri (tidak perlu diterjemahkan).
  String get label => switch (this) {
    AppLocale.id => 'Bahasa Indonesia',
    AppLocale.en => 'English',
    AppLocale.zh => '中文',
    AppLocale.ja => '日本語',
  };

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppLocale.id,
    );
  }
}
