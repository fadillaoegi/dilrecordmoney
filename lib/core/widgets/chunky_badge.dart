import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Label kecil bergaya chunky (pill dengan garis tepi tebal).
class ChunkyBadge extends StatelessWidget {
  const ChunkyBadge({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
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
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
