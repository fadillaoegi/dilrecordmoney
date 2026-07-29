import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../../../../core/widgets/chunky_progress_bar.dart';
import '../../../categories/data/category_catalog.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';

/// Halaman anggaran bulanan per kategori (chunky 3D).
class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final budgets = ref.watch(monthlyBudgetsProvider);
    final spending = ref.watch(monthlySpendingProvider);
    final summary = ref.watch(budgetSummaryProvider);

    final budgetByCategory = {for (final b in budgets) b.categoryId: b};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text('Anggaran Bulanan', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Navigasi bulan
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg, AppDimens.sm, AppDimens.lg, AppDimens.sm,
              ),
              child: Row(
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: ref.read(budgetMonthProvider.notifier).previous,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(DateFormatter.monthYear(month),
                          style: AppTextStyles.label),
                    ),
                  ),
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: ref.read(budgetMonthProvider.notifier).next,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: _SummaryCard(
                totalBudget: summary.totalBudget,
                totalSpent: summary.totalSpent,
              ),
            ),
            const SizedBox(height: AppDimens.md),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.lg, 0, AppDimens.lg, AppDimens.lg,
                ),
                itemCount: CategoryCatalog.expense.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppDimens.sm),
                itemBuilder: (context, index) {
                  final category = CategoryCatalog.expense[index];
                  return _BudgetRow(
                    category: category,
                    budget: budgetByCategory[category.id],
                    spent: spending[category.id] ?? 0,
                    onTap: () => _editBudget(
                      context,
                      ref,
                      category,
                      budgetByCategory[category.id],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Budget? current,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _SetBudgetDialog(category: category, current: current?.limit),
    );
    if (result != null) {
      await ref.read(monthlyBudgetsProvider.notifier).setBudget(category.id, result);
    }
  }
}

// ── Kartu ringkasan anggaran ─────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalBudget, required this.totalSpent});

  final int totalBudget;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    final ratio = totalBudget == 0 ? 0.0 : totalSpent / totalBudget;
    final remaining = totalBudget - totalSpent;
    final over = remaining < 0;

    return ChunkyContainer(
      color: AppColors.accent,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terpakai', style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
              Text('Anggaran', style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: AppDimens.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CurrencyFormatter.rupiah(totalSpent), style: AppTextStyles.title),
              Text(CurrencyFormatter.rupiah(totalBudget), style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          ChunkyProgressBar(value: ratio),
          const SizedBox(height: AppDimens.sm),
          Text(
            over
                ? 'Lebih ${CurrencyFormatter.rupiah(-remaining)} dari anggaran!'
                : 'Sisa ${CurrencyFormatter.rupiah(remaining)}',
            style: AppTextStyles.label.copyWith(
              color: over ? AppColors.negative : AppColors.ink,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Baris anggaran per kategori ──────────────────────────────────────────────

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  final Category category;
  final Budget? budget;
  final int spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null;
    final limit = budget?.limit ?? 0;
    final ratio = hasBudget && limit > 0 ? spent / limit : 0.0;
    final over = hasBudget && spent > limit;

    return GestureDetector(
      onTap: onTap,
      child: ChunkyContainer(
        depth: AppDimens.shadowOffsetSm,
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
                  ),
                  child: Icon(category.icon, color: AppColors.ink, size: 22),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(child: Text(category.name, style: AppTextStyles.body)),
                if (hasBudget)
                  Text(
                    '${CurrencyFormatter.rupiah(spent)} / ${CurrencyFormatter.rupiah(limit)}',
                    style: AppTextStyles.caption.copyWith(
                      color: over ? AppColors.negative : AppColors.muted,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text('Atur', style: AppTextStyles.label.copyWith(
                          color: AppColors.secondary, fontSize: 14)),
                      const Icon(Icons.add_rounded, size: 18, color: AppColors.secondary),
                    ],
                  ),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: AppDimens.sm),
              ChunkyProgressBar(value: ratio, height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Dialog atur anggaran ─────────────────────────────────────────────────────

class _SetBudgetDialog extends StatefulWidget {
  const _SetBudgetDialog({required this.category, this.current});

  final Category category;
  final int? current;

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.current != null && widget.current! > 0)
          ? widget.current.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim()) ?? 0;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: const BorderSide(color: AppColors.ink, width: AppDimens.borderWidthBold),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anggaran ${widget.category.name}', style: AppTextStyles.title),
            const SizedBox(height: AppDimens.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
              child: Row(
                children: [
                  Text('Rp', style: AppTextStyles.title),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.title,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              'Kosongkan / isi 0 untuk menghapus anggaran.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppDimens.lg),
            Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    label: 'Batal',
                    color: AppColors.chip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: ChunkyButton(
                    label: 'Simpan',
                    color: AppColors.primary,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tombol panah navigasi ────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}
