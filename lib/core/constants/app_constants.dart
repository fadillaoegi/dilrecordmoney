/// Konstanta global aplikasi.
class AppConstants {
  AppConstants._();

  static const String appName = 'DilRecord Money';

  // Kunci penyimpanan lokal (SharedPreferences).
  static const String kOnboardingSeen = 'onboarding_seen';
  static const String kTransactions = 'transactions';
  static const String kBudgets = 'budgets';
  static const String kCustomCategories = 'custom_categories';
  static const String kLastAutoBackupDate = 'last_auto_backup_date';
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'app_locale';

  // Backup otomatis harian.
  static const String autoBackupFolderName = 'backup dilrecordmoney';
  static const String autoBackupFileName = 'dilrecordmoney-backup.json';

  // Durasi umum.
  static const Duration splashDuration = Duration(milliseconds: 2600);
}
