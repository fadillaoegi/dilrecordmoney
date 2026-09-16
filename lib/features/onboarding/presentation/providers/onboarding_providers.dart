import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/onboarding_local_datasource.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../../../core/l10n/app_strings.dart';

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
  return [
    OnboardingSlide(
      title: AppStrings.t.slide1Title,
      description: AppStrings.t.slide1Body,
      icon: Icons.savings_rounded,
      color: AppColors.primary,
    ),
    OnboardingSlide(
      title: AppStrings.t.slide2Title,
      description: AppStrings.t.slide2Body,
      icon: Icons.pie_chart_rounded,
      color: AppColors.secondary,
    ),
    OnboardingSlide(
      title: AppStrings.t.slide3Title,
      description: AppStrings.t.slide3Body,
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
