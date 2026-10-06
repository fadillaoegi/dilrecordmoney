import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Ilustrasi slide onboarding: dua "kartu kertas" bertumpuk — kartu belakang
/// sedikit miring, kartu depan memuat ikon + nomor langkah besar. Statis,
/// tanpa ornamen mengambang; satu gerak masuk kecil saat slide tampil.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
    required this.color,
    required this.step,
  });

  final IconData icon;
  final Color color;

  /// Nomor langkah (1-based), dicetak besar di pojok kartu.
  final int step;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(step),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.rotate(
        angle: (1 - t) * 0.06,
        child: Opacity(opacity: t, child: child),
      ),
      child: SizedBox(
        width: 220,
        height: 200,
        child: Stack(
          children: [
            // Kartu belakang, miring — memberi kedalaman tanpa dekorasi.
            Positioned(
              left: 18,
              top: 14,
              child: Transform.rotate(
                angle: -0.07,
                child: _card(color: AppColors.surface, child: null),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: _card(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.toString().padLeft(2, '0'),
                        style: AppTextStyles.display.copyWith(fontSize: 44),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(icon, size: 56, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Color color, required Widget? child}) {
    return Container(
      width: 190,
      height: 170,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(
              AppDimens.shadowOffset,
              AppDimens.shadowOffset,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
