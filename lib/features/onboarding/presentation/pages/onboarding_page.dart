import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_illustration.dart';
import '../../../../core/l10n/app_strings.dart';

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
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final maxContentWidth = ResponsiveLayout.contentMaxWidth(context);
    final compact = ResponsiveLayout.isCompactWidth(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppDimens.md,
                    horizontalPadding,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(currentPage + 1).toString().padLeft(2, '0')} / '
                        '${slides.length.toString().padLeft(2, '0')}',
                        style: AppTextStyles.eyebrow.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: isLast ? null : _finish,
                          child: Text(
                            AppStrings.t.skip,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) =>
                        ref.read(onboardingPageProvider.notifier).setPage(i),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact
                                  ? horizontalPadding
                                  : AppDimens.xl,
                              vertical: AppDimens.md,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight - AppDimens.md * 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OnboardingIllustration(
                                    icon: slide.icon,
                                    color: slide.color,
                                    step: index + 1,
                                  ),
                                  const SizedBox(height: AppDimens.xl),
                                  Text(
                                    slide.title,
                                    style: AppTextStyles.headline.copyWith(
                                      fontSize: compact ? 30 : 36,
                                      height: 1.05,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.md),
                                  Text(
                                    slide.description,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 16,
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
                // Bar langkah: segmen yang sudah dilewati terisi tinta.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    AppDimens.lg,
                  ),
                  child: Row(
                    children: List.generate(slides.length, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: EdgeInsets.only(
                            right: i == slides.length - 1 ? 0 : AppDimens.xs,
                          ),
                          height: 6,
                          color: i <= currentPage
                              ? AppColors.ink
                              : AppColors.chip,
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    AppDimens.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ChunkyButton(
                      label: isLast ? AppStrings.t.startNow : AppStrings.t.next,
                      icon: isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: slides[currentPage].color,
                      onPressed: _onNext,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
