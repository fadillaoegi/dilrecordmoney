/// Kontrak (abstraksi) untuk status onboarding.
///
/// Layer domain hanya mendefinisikan "apa", implementasinya ada di layer data.
abstract interface class OnboardingRepository {
  /// Apakah pengguna sudah menyelesaikan onboarding sebelumnya.
  bool isOnboardingSeen();

  /// Menandai onboarding sebagai selesai.
  Future<void> markOnboardingSeen();
}
