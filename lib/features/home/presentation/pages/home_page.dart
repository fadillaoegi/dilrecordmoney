import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/chunky_badge.dart';
import '../../../../core/widgets/chunky_container.dart';

/// Home sementara: animasi "sedang dikembangkan" bergaya chunky 3D.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.ink, size: 22),
            const SizedBox(width: AppDimens.sm),
            Text('DilRecord', style: AppTextStyles.title),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _WrenchAnimation(),
              const SizedBox(height: AppDimens.xxl),
              const ChunkyBadge(
                text: 'SEDANG DIKEMBANGKAN',
                color: AppColors.accent,
                icon: Icons.construction_rounded,
              ),
              const SizedBox(height: AppDimens.lg),
              Text(
                'Segera Hadir!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'Fitur home sedang kami rakit dengan sepenuh hati. '
                'Nantikan pengalaman mencatat uang yang seru!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppDimens.xl),
              const _ChunkyProgressBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu chunky berisi kunci pas yang bergoyang & roda gigi berputar.
class _WrenchAnimation extends StatefulWidget {
  const _WrenchAnimation();

  @override
  State<_WrenchAnimation> createState() => _WrenchAnimationState();
}

class _WrenchAnimationState extends State<_WrenchAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _wrenchController;
  late final AnimationController _gearController;

  @override
  void initState() {
    super.initState();
    _wrenchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _wrenchController.dispose();
    _gearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChunkyContainer(
      width: 190,
      height: 190,
      color: AppColors.secondary,
      radius: AppDimens.radiusLg,
      depth: 10,
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Roda gigi berputar di pojok belakang.
          Positioned(
            right: 18,
            top: 18,
            child: AnimatedBuilder(
              animation: _gearController,
              builder: (context, _) => Transform.rotate(
                angle: _gearController.value * 2 * math.pi,
                child: const Icon(Icons.settings_rounded,
                    size: 44, color: AppColors.ink),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: AnimatedBuilder(
              animation: _gearController,
              builder: (context, _) => Transform.rotate(
                angle: -_gearController.value * 2 * math.pi,
                child: const Icon(Icons.settings_rounded,
                    size: 30, color: AppColors.ink),
              ),
            ),
          ),
          // Kunci pas bergoyang di tengah.
          AnimatedBuilder(
            animation: _wrenchController,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_wrenchController.value);
              return Transform.rotate(
                angle: -0.4 + t * 0.8,
                child: child,
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppDimens.borderWidthBold,
                ),
              ),
              child: const Icon(Icons.build_rounded, size: 52, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar chunky "tak tentu" yang bergerak maju-mundur.
class _ChunkyProgressBar extends StatefulWidget {
  const _ChunkyProgressBar();

  @override
  State<_ChunkyProgressBar> createState() => _ChunkyProgressBarState();
}

class _ChunkyProgressBarState extends State<_ChunkyProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const barWidth = 0.4; // 40% dari lebar total
          final maxTravel = constraints.maxWidth * (1 - barWidth);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Stack(
                children: [
                  Positioned(
                    left: t * maxTravel,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * barWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
