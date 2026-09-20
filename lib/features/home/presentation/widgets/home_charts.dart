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

/// Donut chart menampilkan distribusi pengeluaran.
class ExpenseDonutChart extends ConsumerWidget {
  const ExpenseDonutChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categorySlicesProvider);

    if (slices.isEmpty) {
      return _ChartEmptyState(message: AppStrings.t.chartNoData);
    }

    return ChunkyContainer(
      color: AppColors.surface,
      depth: AppDimens.shadowOffsetSm,
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: AppColors.ink),
              const SizedBox(width: AppDimens.xs),
              Text(
                AppStrings.t.chartExpenseDistribution,
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: slices.map((s) {
                            return PieChartSectionData(
                              color: s.category.color,
                              value: s.percentage,
                              title: '${s.percentage.toStringAsFixed(1)}%',
                              radius: 35,
                              titleStyle: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Center Icon
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.ink.withValues(alpha: 0.2),
                        size: 32,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  flex: 3,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: slices.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = slices[i];
                      return Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: s.category.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.ink,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.category.name,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.rupiah(
                              s.total,
                              withSymbol: false,
                            ),
                            style: AppTextStyles.label.copyWith(
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart menampilkan tren transaksi (pemasukan vs pengeluaran).
class TransactionTrendChart extends ConsumerWidget {
  const TransactionTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(barChartProvider);

    if (entries.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data to not clutter
    }

    // Cari nilai maksimum untuk scale Y
    int maxAmount = 0;
    for (final e in entries) {
      if (e.income > maxAmount) maxAmount = e.income;
      if (e.expense > maxAmount) maxAmount = e.expense;
    }

    // Fallback jika max 0
    if (maxAmount == 0) maxAmount = 100;

    // Bulatkan ke atas ke kelipatan 10/100/1000 dsb.
    double maxY = (maxAmount * 1.2).toDouble();

    return ChunkyContainer(
      color: AppColors.surface,
      depth: AppDimens.shadowOffsetSm,
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.ink),
              const SizedBox(width: AppDimens.xs),
              Text(
                AppStrings.t.chartTrend,
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
              const Spacer(),
              _Legend(color: AppColors.positive, label: AppStrings.t.income),
              const SizedBox(width: 8),
              _Legend(color: AppColors.negative, label: AppStrings.t.expense),
            ],
          ),
          const SizedBox(height: AppDimens.lg),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            entries[index].label,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // Sembunyikan axis Y agar bersih
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.muted.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.income.toDouble(),
                        color: AppColors.positive,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      BarChartRodData(
                        toY: entry.expense.toDouble(),
                        color: AppColors.negative,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ChunkyContainer(
      color: AppColors.surface,
      depth: AppDimens.shadowOffsetSm,
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.insert_chart_outlined, size: 32, color: AppColors.muted),
            const SizedBox(height: AppDimens.sm),
            Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
