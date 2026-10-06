import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../providers/chart_providers.dart';

/// Distribusi pengeluaran per kategori sebagai daftar berperingkat.
///
/// Sengaja bukan donut: warna kategori adalah pastel pucat yang dipakai
/// berulang (dan jadi abu di mode gelap), sehingga irisan tidak bisa
/// dibedakan. Di sini kategori dikenali lewat ikon + nama, dan panjang
/// batang = porsi dari total pengeluaran.
class ExpenseBreakdownChart extends ConsumerWidget {
  const ExpenseBreakdownChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categorySlicesProvider);

    if (slices.isEmpty) {
      return _ChartCard(
        title: AppStrings.t.chartExpenseDistribution,
        child: _ChartEmptyState(message: AppStrings.t.chartNoData),
      );
    }

    final total = slices.fold<int>(0, (sum, s) => sum + s.total);

    return _ChartCard(
      title: AppStrings.t.chartExpenseDistribution,
      headline: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.rupiah(total),
              style: AppTextStyles.display.copyWith(fontSize: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${slices.length} ${AppStrings.t.categoriesCount}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      child: Column(
        children: [
          for (final (i, slice) in slices.indexed) ...[
            if (i > 0)
              Container(
                height: AppDimens.hairline,
                color: AppColors.ink.withValues(alpha: 0.15),
              ),
            _BreakdownRow(slice: slice),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.slice});

  final CategorySlice slice;

  @override
  Widget build(BuildContext context) {
    final share = (slice.percentage / 100).clamp(0.0, 1.0);
    final percentText = slice.percentage < 1
        ? '<1%'
        : '${slice.percentage.round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: slice.category.color,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(
                color: AppColors.ink,
                width: AppDimens.borderWidth,
              ),
            ),
            child: Icon(slice.category.icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slice.category.name,
                        style: AppTextStyles.label.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Text(
                      CurrencyFormatter.rupiah(slice.total),
                      style: AppTextStyles.amount.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(child: _ShareBar(share: share)),
                    SizedBox(
                      width: 44,
                      child: Text(
                        percentText,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.eyebrow.copyWith(
                          color: AppColors.ink,
                          letterSpacing: 0.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Batang porsi: lintasan bergaris tipis, isi tinta solid.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(1),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        // Minimal sedikit terlihat walau porsinya sangat kecil.
        widthFactor: math.max(share, 0.015),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

/// Batang pemasukan vs pengeluaran per hari (maks. 7 hari bertransaksi).
class TransactionTrendChart extends ConsumerWidget {
  const TransactionTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(barChartProvider);

    if (entries.isEmpty) {
      return _ChartCard(
        title: AppStrings.t.chartTrend,
        child: _ChartEmptyState(message: AppStrings.t.chartNoData),
      );
    }

    var maxAmount = 0;
    for (final e in entries) {
      maxAmount = math.max(maxAmount, math.max(e.income, e.expense));
    }
    // Sumbu Y dengan 4 garis di angka "bulat" (1/2/2,5/5 × 10ⁿ).
    final step = _niceStep(maxAmount / 4);
    final maxY = step * 4;
    final rodWidth = entries.length <= 3 ? 16.0 : 11.0;

    return _ChartCard(
      title: AppStrings.t.chartTrend,
      trailing: Wrap(
        spacing: 10,
        runSpacing: AppDimens.xs,
        children: [
          _Legend(color: AppColors.positive, label: AppStrings.t.income),
          _Legend(color: AppColors.negative, label: AppStrings.t.expense),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppDimens.md, bottom: 4),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: AppDimens.radiusSm,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = entries[groupIndex];
                    return BarTooltipItem(
                      '${entry.label}\n',
                      AppTextStyles.eyebrow.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.rupiah(rod.toY.round()),
                          style: AppTextStyles.amount.copyWith(
                            fontSize: 13,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: step,
                    getTitlesWidget: (value, meta) {
                      // Label hanya di garis bantu, bukan di nilai maks.
                      // yang dihitung fl_chart sendiri.
                      if (value % step != 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          CurrencyFormatter.compact(value.round()),
                          style: _axisStyle,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(entries[index].label, style: _axisStyle),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
              ),
              barGroups: [
                for (final (index, entry) in entries.indexed)
                  BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      _rod(entry.income, AppColors.positive, rodWidth),
                      _rod(entry.expense, AppColors.negative, rodWidth),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle get _axisStyle => AppTextStyles.caption.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  BarChartRodData _rod(int value, Color color, double width) {
    return BarChartRodData(
      toY: value.toDouble(),
      color: color,
      width: width,
      borderRadius: BorderRadius.zero,
      // Garis tinta hanya bila batangnya ada, supaya nilai 0 tidak
      // meninggalkan garis tipis di dasar.
      borderSide: value > 0
          ? BorderSide(color: AppColors.ink, width: 1.5)
          : BorderSide.none,
    );
  }

  /// Kelipatan "enak dibaca" terdekat di atas [raw]: 1, 2, 2,5, 5 × 10ⁿ.
  static double _niceStep(double raw) {
    if (raw <= 0) return 1000;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
  }
}

// ── Bagian bersama ───────────────────────────────────────────────────────────

/// Kartu grafik: judul kecil berhuruf kapital (+ elemen kanan opsional),
/// angka utama opsional, lalu isi.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.headline,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? headline;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ChunkyContainer(
      depth: AppDimens.shadowOffsetSm,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        14,
        AppDimens.md,
        AppDimens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap: di layar sempit legenda turun ke baris kedua.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimens.md,
            runSpacing: AppDimens.xs + 2,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.eyebrow.copyWith(color: AppColors.ink),
              ),
              ?trailing,
            ],
          ),
          if (headline != null) ...[
            const SizedBox(height: AppDimens.sm),
            headline!,
            const SizedBox(height: AppDimens.sm),
          ],
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
      child: Text(message, style: AppTextStyles.caption),
    );
  }
}
