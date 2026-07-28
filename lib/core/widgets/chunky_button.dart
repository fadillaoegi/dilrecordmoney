import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Tombol chunky 3D dengan efek "ditekan": saat disentuh, tombol turun
/// mengikuti bayangannya sehingga terasa benar-benar ditekan.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.primary,
    this.textColor = AppColors.ink,
    this.icon,
    this.expand = true,
    this.depth = AppDimens.shadowOffset,
    this.radius = AppDimens.radiusMd,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimens.lg,
      vertical: AppDimens.md,
    ),
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool expand;
  final double depth;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final travel = _pressed ? widget.depth : 0.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, travel, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
          color: _enabled ? widget.color : AppColors.chip,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, widget.depth - travel),
              blurRadius: 0,
            ),
          ],
        ),
        padding: widget.padding,
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 22),
              const SizedBox(width: AppDimens.sm),
            ],
            Text(
              widget.label,
              style: AppTextStyles.label.copyWith(
                color: _enabled ? widget.textColor : AppColors.muted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol ikon bulat bergaya chunky (mis. tombol "next" pada onboarding).
class ChunkyIconButton extends StatefulWidget {
  const ChunkyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = AppColors.accent,
    this.iconColor = AppColors.ink,
    this.size = 64,
    this.depth = AppDimens.shadowOffset,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color iconColor;
  final double size;
  final double depth;

  @override
  State<ChunkyIconButton> createState() => _ChunkyIconButtonState();
}

class _ChunkyIconButtonState extends State<ChunkyIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final travel = _pressed ? widget.depth : 0.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, travel, 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          border: Border.all(color: AppColors.ink, width: AppDimens.borderWidthBold),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, widget.depth - travel),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(widget.icon, color: widget.iconColor, size: widget.size * 0.42),
      ),
    );
  }
}
