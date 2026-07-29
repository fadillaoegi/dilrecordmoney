import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_illustration.dart';

/// Halaman onboarding interaktif bergaya chunky 3D.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<OnboardingSlide> get _slides => ref.read(onboardingSlidesProvider);

  void _onNext() {
    final current = ref.read(onboardingPageProvider);
    if (current < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(completeOnboardingProvider)();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(onboardingSlidesProvider);
    final currentPage = ref.watch(onboardingPageProvider);
    final isLast = currentPage == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Baris atas: logo + tombol lewati ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.md,
                AppDimens.lg,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.ink,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Text('DilRecord', style: AppTextStyles.title),
                    ],
                  ),
                  AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: Text(
                        'Lewati',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ──
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) =>
                    ref.read(onboardingPageProvider.notifier).setPage(i),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  // Scroll-safe & tetap terpusat: memusat saat ada ruang,
                  // menggulir saat layar terlalu pendek (mis. perangkat kecil).
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.xl,
                          vertical: AppDimens.md,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - AppDimens.md * 2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OnboardingIllustration(
                                icon: slide.icon,
                                color: slide.color,
                              ),
                              const SizedBox(height: AppDimens.xl),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headline,
                              ),
                              const SizedBox(height: AppDimens.md),
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Indikator halaman ──
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) {
                  final active = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 30 : 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: active
                          ? slides[currentPage].color
                          : AppColors.chip,
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Aksi bawah ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.xl,
                0,
                AppDimens.xl,
                AppDimens.xl,
              ),
              child: ChunkyButton(
                label: isLast ? 'Mulai Sekarang' : 'Lanjut',
                icon: isLast
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                color: slides[currentPage].color,
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
