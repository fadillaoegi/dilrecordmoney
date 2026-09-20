/// Nama path rute aplikasi.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String addTransaction = '/transaction/new';

  /// Path template untuk halaman edit. Gunakan [editTransactionPath] untuk
  /// membentuk path konkret berdasarkan id transaksi.
  static const String editTransaction = '/transaction/:id/edit';

  static String editTransactionPath(String id) => '/transaction/$id/edit';
  static const String budget = '/budget';
  static const String charts = '/charts';
  static const String backup = '/backup';
  static const String settings = '/settings';
}
