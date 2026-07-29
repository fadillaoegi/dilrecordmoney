import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/onboarding_local_datasource.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';

// ── Dependency wiring (data → domain) ────────────────────────────────────────

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

// ── Konten onboarding ────────────────────────────────────────────────────────

final onboardingSlidesProvider = Provider<List<OnboardingSlide>>((ref) {
  return const [
    OnboardingSlide(
      title: 'Catat Setiap Rupiah',
      description:
          'Rekam pemasukan & pengeluaranmu secepat mengetik pesan. Nggak ada lagi uang yang hilang tanpa jejak.',
      icon: Icons.savings_rounded,
      color: AppColors.primary,
    ),
    OnboardingSlide(
      title: 'Lihat Ke Mana Uangmu Pergi',
      description:
          'Grafik warna-warni yang gampang dibaca. Tahu persis kategori mana yang paling bikin dompet tipis.',
      icon: Icons.pie_chart_rounded,
      color: AppColors.secondary,
    ),
    OnboardingSlide(
      title: 'Capai Target Menabung',
      description:
          'Pasang target, kejar setiap hari, dan rayakan saat tercapai. Menabung jadi terasa seperti main game.',
      icon: Icons.emoji_events_rounded,
      color: AppColors.coral,
    ),
  ];
});

// ── State halaman aktif ─────────────────────────────────────────────────────

/// Menyimpan indeks slide onboarding yang sedang tampil.
class OnboardingPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int index) => state = index;
}

final onboardingPageProvider = NotifierProvider<OnboardingPageNotifier, int>(
  OnboardingPageNotifier.new,
);

// ── Aksi menyelesaikan onboarding ────────────────────────────────────────────

/// Menandai onboarding selesai lewat repository.
final completeOnboardingProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(onboardingRepositoryProvider).markOnboardingSeen();
});
