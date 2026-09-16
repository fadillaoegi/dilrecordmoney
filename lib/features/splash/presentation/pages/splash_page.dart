import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../backup/presentation/providers/auto_backup_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../../core/l10n/app_strings.dart';

/// Splash interaktif: logo chunky memantul & berputar masuk, lalu meneruskan
/// ke onboarding atau home tergantung status pengguna.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _wobbleController;

  late final Animation<double> _scale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _scale = CurvedAnimation(
      parent: _introController,
      curve: Curves.elasticOut,
    );
    _logoRotate = Tween<double>(begin: -0.35, end: 0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1, curve: Curves.easeIn),
    );

    _introController.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    // Jalan bareng delay splash normal — backup harian cuma baca/tulis satu
    // file kecil jadi jauh lebih cepat dari durasi splash itu sendiri.
    // Kegagalan backup (storage penuh, dsb.) tidak boleh menahan navigasi.
    await Future.wait([
      Future<void>.delayed(AppConstants.splashDuration),
      ref.read(autoBackupProvider.future).then((_) {}, onError: (_) {}),
    ]);
    if (!mounted) return;

    final seen = ref.read(onboardingRepositoryProvider).isOnboardingSeen();
    context.go(seen ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _introController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backupLabel = ref
        .watch(autoBackupProvider)
        .when(
          data: (outcome) => switch (outcome) {
            AutoBackupOutcome.restored => AppStrings.t.restoringBackup,
            AutoBackupOutcome.backedUp => AppStrings.t.savingDailyBackup,
            AutoBackupOutcome.idle => null,
          },
          loading: () => AppStrings.t.preparingBackup,
          error: (_, _) => null,
        );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo chunky yang memantul masuk lalu bergoyang halus.
            AnimatedBuilder(
              animation: Listenable.merge([
                _introController,
                _wobbleController,
              ]),
              builder: (context, child) {
                final wobble = (_wobbleController.value - 0.5) * 0.12;
                return Transform.scale(
                  scale: _scale.value,
                  child: Transform.rotate(
                    angle: _logoRotate.value + wobble,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidthBold,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(0, 10),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 64,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xl),
            FadeTransition(
              opacity: _fade,
              child: Text(
                AppConstants.appName,
                style: AppTextStyles.display.copyWith(fontSize: 34),
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            FadeTransition(
              opacity: _fade,
              child: Text(
                AppStrings.t.appTagline,
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
              ),
            ),
            const SizedBox(height: AppDimens.xxl),
            FadeTransition(opacity: _fade, child: const _ChunkyLoader()),
            if (backupLabel != null) ...[
              const SizedBox(height: AppDimens.md),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  backupLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loader tiga titik chunky yang memantul bergantian.
class _ChunkyLoader extends StatefulWidget {
  const _ChunkyLoader();

  @override
  State<_ChunkyLoader> createState() => _ChunkyLoaderState();
}

class _ChunkyLoaderState extends State<_ChunkyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.coral, AppColors.secondary, AppColors.surface];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.2) % 1.0;
            final bounce = (0.5 - (phase - 0.5).abs()) * 2; // 0→1→0
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -10 * bounce),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppDimens.borderWidth,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
