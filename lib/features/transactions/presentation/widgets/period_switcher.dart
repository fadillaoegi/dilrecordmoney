import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/period_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/period_selection.dart';
import '../providers/period_providers.dart';

/// Pemilih periode: label besar + panah sebelum/sesudah, lalu tab
/// Harian/Mingguan/Bulanan/Tahunan. Dipakai beranda & halaman grafik supaya
/// keduanya selalu menunjukkan periode yang sama.
class PeriodSwitcher extends ConsumerWidget {
  const PeriodSwitcher({super.key, required this.period});

  final PeriodSelection period;

  String get _label => switch (period.type) {
    PeriodType.daily => DateFormatter.relative(period.anchor),
    PeriodType.weekly =>
      '${DateFormatter.short(period.start)} – ${DateFormatter.short(period.lastDay)}',
    PeriodType.monthly => DateFormatter.monthYear(period.anchor),
    PeriodType.yearly => '${period.anchor.year}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(periodSelectionProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label periode besar di kiri, panah berpasangan di kanan.
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _label,
                  style: AppTextStyles.headline.copyWith(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            _NavArrows(onPrevious: notifier.previous, onNext: notifier.next),
          ],
        ),
        const SizedBox(height: AppDimens.md - 4),
        // Tab periode: kotak bergaris, tab aktif terisi tinta.
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
              color: AppColors.ink,
              width: AppDimens.borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm - 1),
            child: Row(
              children: [
                for (final (i, type) in PeriodType.values.indexed) ...[
                  if (i > 0)
                    Container(width: AppDimens.hairline, color: AppColors.ink),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => notifier.setType(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        color: type == period.type
                            ? AppColors.ink
                            : Colors.transparent,
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Text(
                            type.label.toUpperCase(),
                            style: AppTextStyles.eyebrow.copyWith(
                              fontSize: 10.5,
                              color: type == period.type
                                  ? AppColors.white
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Panah sebelum/sesudah dalam satu kotak, dipisah garis — satu kontrol.
class _NavArrows extends StatelessWidget {
  const _NavArrows({required this.onPrevious, required this.onNext});

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback onTap) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 40, child: Icon(icon, color: AppColors.ink)),
    );

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left_rounded, onPrevious),
          Container(width: AppDimens.borderWidth, color: AppColors.ink),
          arrow(Icons.chevron_right_rounded, onNext),
        ],
      ),
    );
  }
}
