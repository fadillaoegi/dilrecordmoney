import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Kontainer dasar bergaya chunky 3D: latar solid, garis tepi tebal,
/// dan hard-shadow (bayangan solid tanpa blur) untuk kesan timbul.
class ChunkyContainer extends StatelessWidget {
  const ChunkyContainer({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.ink,
    this.shadowColor = AppColors.shadow,
    this.radius = AppDimens.radiusMd,
    this.borderWidth = AppDimens.borderWidth,
    this.depth = AppDimens.shadowOffset,
    this.padding = const EdgeInsets.all(AppDimens.md),
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double radius;
  final double borderWidth;

  /// Seberapa "timbul" kartu (offset hard-shadow).
  final double depth;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(0, depth),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
