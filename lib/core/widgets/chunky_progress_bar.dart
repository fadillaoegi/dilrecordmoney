import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Progress bar bergaya chunky (determinate). Nilai > 1 berarti melewati batas
/// dan bar diwarnai [overColor].
class ChunkyProgressBar extends StatelessWidget {
  const ChunkyProgressBar({
    super.key,
    required this.value,
    this.color,
    this.overColor,
    this.height = 22,
  });

  /// Rasio 0..1 (boleh melebihi 1 untuk kondisi over-budget).
  final double value;

  /// Null → ikut palet aktif ([AppColors.primary] / [AppColors.negative]).
  final Color? color;
  final Color? overColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final over = value > 1;
    final clamped = value.clamp(0.0, 1.0);
    final fillColor = over
        ? (overColor ?? AppColors.negative)
        : (color ?? AppColors.primary);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * clamped;
          return Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: width,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    border: width > 6
                        ? Border.all(color: AppColors.ink, width: 2)
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
