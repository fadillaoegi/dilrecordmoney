/// Konstanta global aplikasi.
class AppConstants {
  AppConstants._();

  static const String appName = 'DilRecord Money';

  // Kunci penyimpanan lokal (SharedPreferences).
  static const String kOnboardingSeen = 'onboarding_seen';
  static const String kTransactions = 'transactions';
  static const String kBudgets = 'budgets';

  // Durasi umum.
  static const Duration splashDuration = Duration(milliseconds: 2600);
}
