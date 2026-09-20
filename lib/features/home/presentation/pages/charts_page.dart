import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/l10n/app_strings.dart';
import '../widgets/home_charts.dart';

/// Halaman yang memuat grafik (donut & bar chart).
class ChartsPage extends ConsumerWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final maxContentWidth = ResponsiveLayout.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(AppStrings.t.chartTrend, style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppDimens.sm,
                horizontalPadding,
                AppDimens.xl,
              ),
              children: const [
                ExpenseDonutChart(),
                SizedBox(height: AppDimens.md),
                TransactionTrendChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
