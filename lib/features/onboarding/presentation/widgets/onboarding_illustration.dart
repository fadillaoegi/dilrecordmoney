import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Ilustrasi chunky 3D untuk tiap slide onboarding:
/// ikon besar mengambang naik-turun, dikelilingi bentuk dekoratif berputar.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cincin dekoratif berputar (bentuk-bentuk chunky mengorbit).
            AnimatedBuilder(
              animation: _spinController,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _spinController.value * 2 * math.pi,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _orbitShape(0, AppColors.accent, BoxShape.circle, 26),
                        _orbitShape(math.pi / 2, AppColors.purple, BoxShape.rectangle, 22),
                        _orbitShape(math.pi, AppColors.secondary, BoxShape.circle, 18),
                        _orbitShape(3 * math.pi / 2, AppColors.coral, BoxShape.rectangle, 24),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Kartu ikon utama yang mengambang.
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_floatController.value);
                return Transform.translate(
                  offset: Offset(0, -12 + t * 24),
                  child: child,
                );
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidthBold,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(0, 10),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 76, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orbitShape(double angle, Color color, BoxShape shape, double size) {
    const radius = 120.0;
    return Transform.translate(
      offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
      child: Transform.rotate(
        // Lawan rotasi induk agar bentuk tidak ikut miring berlebihan.
        angle: -_spinController.value * 2 * math.pi,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(6)
                : null,
            border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
          ),
        ),
      ),
    );
  }
}
