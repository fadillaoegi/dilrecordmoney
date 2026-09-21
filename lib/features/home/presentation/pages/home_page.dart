import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/period_type.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/period_selection.dart';
import '../../../transactions/domain/entities/transaction_summary.dart';
import '../../../transactions/presentation/providers/period_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';

/// Beranda: kartu saldo + daftar transaksi terbaru.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final maxButtonWidth = ResponsiveLayout.isTabletWidth(context)
        ? 420.0
        : 560.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
             Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.ink,
              size: 22,
            ),
             SizedBox(width: AppDimens.sm),
            Text('DilRecord', style: AppTextStyles.title),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.sm),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.backup),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child:  Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.sm),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.budget),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child:  Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxButtonWidth),
          child: ChunkyButton(
            label: 'Catat Transaksi',
            icon: Icons.add_rounded,
            color: AppColors.primary,
            onPressed: () => context.push(AppRoutes.addTransaction),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        top: false,
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Gagal memuat data', style: AppTextStyles.body),
          ),
          data: (_) => const _HomeContent(),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(periodSelectionProvider);
    final summary = ref.watch(filteredSummaryProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppDimens.md,
            horizontalPadding,
            AppDimens.sm,
          ),
          sliver: SliverToBoxAdapter(child: _PeriodFilter(period: period)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            AppDimens.sm,
          ),
          sliver: SliverToBoxAdapter(child: _BalanceCard(summary: summary)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppDimens.sm,
            horizontalPadding,
            AppDimens.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaksi', style: AppTextStyles.title),
                Text(
                  '${transactions.length} catatan',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              // Sisakan ruang di bawah agar teks tidak tertutup FAB.
              padding: EdgeInsets.only(bottom: 120),
              child: _EmptyState(
                message:
                    'Belum ada transaksi di periode ini.\n'
                    'Ketuk "Catat Transaksi" untuk menambah.',
              ),
            ),
          )
        else
          _PaginatedTransactionList(
            key: ValueKey((period.type, period.start)),
            transactions: transactions,
            horizontalPadding: horizontalPadding,
          ),
      ],
    );
  }
}

// ── Filter periode ───────────────────────────────────────────────────────────

class _PeriodFilter extends ConsumerWidget {
  const _PeriodFilter({required this.period});

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
      children: [
        // Segmented: Harian / Mingguan / Bulanan / Tahunan
        Container(
          padding: const EdgeInsets.all(AppDimens.xs),
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: AppColors.ink,
              width: AppDimens.borderWidth,
            ),
          ),
          child: Row(
            children: [
              for (final type in PeriodType.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.setType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.sm,
                      ),
                      decoration: BoxDecoration(
                        color: type == period.type
                            ? AppColors.secondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: type == period.type
                            ? Border.all(
                                color: AppColors.ink,
                                width: AppDimens.borderWidth,
                              )
                            : null,
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            type.label,
                            style: AppTextStyles.caption.copyWith(
                              color: type == period.type
                                  ? AppColors.ink
                                  : AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        // Navigasi periode: ‹ label ›
        Row(
          children: [
            _NavArrow(
              icon: Icons.chevron_left_rounded,
              onTap: notifier.previous,
            ),
            Expanded(
              child: Center(child: Text(_label, style: AppTextStyles.label)),
            ),
            _NavArrow(icon: Icons.chevron_right_rounded, onTap: notifier.next),
          ],
        ),
      ],
    );
  }
}

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
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

// ── Kartu saldo ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.summary});

  final TransactionSummary summary;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _isBalanceObscured = true;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveLayout.isCompactWidth(context);

    return ChunkyContainer(
      color: AppColors.primary,
      depth: AppDimens.shadowOffsetSm,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: compact ? 12 : AppDimens.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Saldo',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink),
                ),
              ),
              IconButton(
                key: const Key('balance-visibility-toggle'),
                tooltip: _isBalanceObscured
                    ? 'Tampilkan saldo'
                    : 'Sembunyikan saldo',
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                iconSize: 20,
                onPressed: () {
                  setState(() => _isBalanceObscured = !_isBalanceObscured);
                },
                icon: Icon(
                  _isBalanceObscured
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          FittedBox(
            child: Text(
              _isBalanceObscured
                  ? 'Rp ••••••••'
                  : CurrencyFormatter.rupiah(widget.summary.balance),
              key: const Key('balance-value'),
              style: AppTextStyles.display.copyWith(
                fontSize: compact ? 30 : 34,
              ),
            ),
          ),
          SizedBox(height: compact ? AppDimens.sm : 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Pemasukan',
                  amount: widget.summary.totalIncome,
                  icon: Icons.south_west_rounded,
                  color: AppColors.surface,
                  compact: compact,
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: _MiniStat(
                  label: 'Pengeluaran',
                  amount: widget.summary.totalExpense,
                  icon: Icons.north_east_rounded,
                  color: AppColors.surface,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 12,
        vertical: compact ? 6 : AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 15 : 17, color: AppColors.ink),
          SizedBox(width: compact ? AppDimens.xs : AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                FittedBox(
                  child: Text(
                    CurrencyFormatter.rupiah(amount),
                    style: AppTextStyles.label.copyWith(
                      fontSize: compact ? 12 : 13,
                    ),
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

// ── Pagination transaksi ─────────────────────────────────────────────────────

class _PaginatedTransactionList extends StatefulWidget {
  const _PaginatedTransactionList({
    super.key,
    required this.transactions,
    required this.horizontalPadding,
  });

  final List<MoneyTransaction> transactions;
  final double horizontalPadding;

  @override
  State<_PaginatedTransactionList> createState() =>
      _PaginatedTransactionListState();
}

class _PaginatedTransactionListState extends State<_PaginatedTransactionList> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  void _loadMore() {
    setState(() => _visibleCount += _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = widget.transactions.length < _visibleCount
        ? widget.transactions.length
        : _visibleCount;
    final remainingCount = widget.transactions.length - visibleCount;
    final hasMore = remainingCount > 0;
    final nextPageCount = remainingCount < _pageSize
        ? remainingCount
        : _pageSize;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding,
        AppDimens.sm,
        widget.horizontalPadding,
        100,
      ),
      sliver: SliverList.separated(
        itemCount: visibleCount + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.sm),
        itemBuilder: (context, index) {
          if (index < visibleCount) {
            return _TransactionTile(transaction: widget.transactions[index]);
          }

          return ChunkyButton(
            key: const Key('load-more-transactions'),
            label: 'Muat $nextPageCount Lagi',
            icon: Icons.expand_more_rounded,
            color: AppColors.secondary,
            onPressed: _loadMore,
          );
        },
      ),
    );
  }
}

// ── Baris transaksi ──────────────────────────────────────────────────────────

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final wallet = ref.watch(walletByIdProvider(transaction.walletId));
    final isIncome = transaction.type.isIncome;
    final amountColor = isIncome ? AppColors.positive : AppColors.negative;
    final sign = isIncome ? '+' : '-';
    final compact = ResponsiveLayout.isCompactWidth(context);

    final title = category?.name ?? 'Lainnya';
    final subtitle = [
      wallet?.name,
      DateFormatter.relative(transaction.date),
    ].whereType<String>().join(' • ');

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.lg),
        decoration: BoxDecoration(
          color: AppColors.negative,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
        ),
        child:  Icon(Icons.delete_rounded, color: AppColors.white),
      ),
      child: GestureDetector(
        onTap: () =>
            context.push(AppRoutes.editTransactionPath(transaction.id)),
        child: ChunkyContainer(
          depth: AppDimens.shadowOffsetSm,
          padding: const EdgeInsets.all(AppDimens.sm + 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category?.color ?? AppColors.chip,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: Icon(
                  category?.icon ?? Icons.help_outline_rounded,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      Text(
                        title,
                        style: AppTextStyles.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sign${CurrencyFormatter.rupiah(transaction.amount)}',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          color: amountColor,
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Text(
                            '$sign${CurrencyFormatter.rupiah(transaction.amount)}',
                            style: AppTextStyles.title.copyWith(
                              fontSize: 16,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                    if (transaction.note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note!,
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref
        .read(transactionListProvider.notifier)
        .deleteTransaction(transaction.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'Transaksi dihapus',
            style: AppTextStyles.label.copyWith(color: AppColors.white),
          ),
          action: SnackBarAction(
            label: 'URUNGKAN',
            textColor: AppColors.accent,
            onPressed: () => ref
                .read(transactionListProvider.notifier)
                .addTransaction(transaction),
          ),
        ),
      );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppDimens.borderWidthBold,
                ),
                boxShadow:  [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child:  Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text('Belum ada transaksi', style: AppTextStyles.title),
            const SizedBox(height: AppDimens.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
