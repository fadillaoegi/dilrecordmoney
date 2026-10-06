import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Label kecil bergaya cap/stempel: kotak bersudut tegas, huruf kapital.
class ChunkyBadge extends StatelessWidget {
  const ChunkyBadge({super.key, required this.text, this.color, this.icon});

  final String text;

  /// Null → ikut palet aktif ([AppColors.accent]).
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm + 2,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.accent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.ink),
            const SizedBox(width: AppDimens.xs + 2),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
