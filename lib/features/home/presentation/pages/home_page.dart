import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
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
import '../../../transactions/domain/entities/daily_transaction_group.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/transaction_summary.dart';
import '../../../transactions/presentation/providers/period_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/period_switcher.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';

/// Beranda: periode aktif, saldo, lalu buku catatan per hari.
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
        titleSpacing: horizontalPadding,
        title: Text(
          'DilRecord',
          style: AppTextStyles.headline.copyWith(fontSize: 24),
        ),
        actions: [
          _BarAction(
            icon: Icons.bar_chart_rounded,
            tooltip: AppStrings.t.chartTrend,
            onTap: () => context.push(AppRoutes.charts),
          ),
          _BarAction(
            icon: Icons.track_changes_rounded,
            tooltip: AppStrings.t.monthlyBudget,
            onTap: () => context.push(AppRoutes.budget),
          ),
          _BarAction(
            icon: Icons.tune_rounded,
            tooltip: AppStrings.t.settings,
            onTap: () => context.push(AppRoutes.settings),
          ),
          SizedBox(width: horizontalPadding - AppDimens.xs),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxButtonWidth),
          child: ChunkyButton(
            label: AppStrings.t.recordTransaction,
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
            child: Text(AppStrings.t.loadFailed, style: AppTextStyles.body),
          ),
          data: (_) => const _HomeContent(),
        ),
      ),
    );
  }
}

/// Tombol ikon persegi kecil di app bar — garis tipis, tanpa isi warna,
/// supaya tidak bersaing dengan kartu saldo.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.xs + 2),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
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
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
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
    final balance = ref.watch(runningBalanceProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppDimens.sm,
            horizontalPadding,
            AppDimens.md,
          ),
          sliver: SliverToBoxAdapter(child: PeriodSwitcher(period: period)),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: _BalanceCard(summary: summary, balance: balance),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppDimens.lg + AppDimens.xs,
            horizontalPadding,
            AppDimens.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.t.transactions.toUpperCase(),
                        style: AppTextStyles.eyebrow.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${transactions.length} ${AppStrings.t.recordsCount}',
                      style: AppTextStyles.eyebrow,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                // Pembatas tegas antara ringkasan dan daftar transaksi.
                Container(
                  key: const Key('transactions-divider'),
                  height: AppDimens.borderWidth,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              // Sisakan ruang di bawah agar teks tidak tertutup FAB.
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppDimens.sm,
                horizontalPadding,
                120,
              ),
              child: const _EmptyState(),
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

// ── Kartu saldo ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.summary, required this.balance});

  /// Pemasukan & pengeluaran periode aktif saja.
  final TransactionSummary summary;

  /// Saldo kumulatif sampai akhir periode aktif — sisa periode sebelumnya
  /// ikut terbawa, jadi tidak reset ke nol saat ganti bulan.
  final int balance;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _isBalanceObscured = true;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveLayout.isCompactWidth(context);
    final pad = compact ? 14.0 : AppDimens.md + 2;

    return ChunkyContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad - 4, pad - 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.t.totalBalance.toUpperCase(),
                    style: AppTextStyles.eyebrow,
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
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _isBalanceObscured
                    ? 'Rp ••••••••'
                    : CurrencyFormatter.rupiah(widget.balance),
                key: const Key('balance-value'),
                style: AppTextStyles.display.copyWith(
                  fontSize: compact ? 34 : 38,
                ),
              ),
            ),
          ),
          Container(height: AppDimens.borderWidth, color: AppColors.ink),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FlowStat(
                    label: AppStrings.t.income,
                    amount: widget.summary.totalIncome,
                    // Pemasukan ikut disamarkan bersama saldo; pengeluaran
                    // tetap terlihat supaya tetap bisa memantau belanja.
                    obscured: _isBalanceObscured,
                    valueKey: const Key('income-value'),
                    marker: '▲',
                    color: AppColors.positive,
                    padding: pad,
                  ),
                ),
                Container(width: AppDimens.borderWidth, color: AppColors.ink),
                Expanded(
                  child: _FlowStat(
                    label: AppStrings.t.expense,
                    amount: widget.summary.totalExpense,
                    valueKey: const Key('expense-value'),
                    marker: '▼',
                    color: AppColors.negative,
                    padding: pad,
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

/// Satu sel arus kas di kaki kartu saldo — teks saja, tanpa kotak bersarang.
class _FlowStat extends StatelessWidget {
  const _FlowStat({
    required this.label,
    required this.amount,
    required this.valueKey,
    required this.marker,
    this.obscured = false,
    required this.color,
    required this.padding,
  });

  final String label;
  final int amount;
  final Key valueKey;
  final String marker;
  final bool obscured;
  final Color color;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$marker ${label.toUpperCase()}',
            style: AppTextStyles.eyebrow.copyWith(color: color, fontSize: 10),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              obscured ? 'Rp ••••••' : CurrencyFormatter.rupiah(amount),
              key: valueKey,
              style: AppTextStyles.amount.copyWith(fontSize: 16),
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

    // Paginasi tetap per transaksi; pengelompokan per hari dilakukan pada
    // potongan yang terlihat saja.
    final groups = groupByDay(widget.transactions.take(visibleCount).toList());

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding,
        0,
        widget.horizontalPadding,
        100,
      ),
      sliver: SliverList.separated(
        itemCount: groups.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.md + 2),
        itemBuilder: (context, index) {
          if (index < groups.length) {
            return _DayGroup(group: groups[index]);
          }

          return ChunkyButton(
            key: const Key('load-more-transactions'),
            label: 'Muat $nextPageCount Lagi',
            icon: Icons.expand_more_rounded,
            color: AppColors.surface,
            depth: AppDimens.shadowOffsetSm,
            onPressed: _loadMore,
          );
        },
      ),
    );
  }
}

// ── Grup per hari ────────────────────────────────────────────────────────────

/// Satu "halaman buku": judul hari + total bersih, lalu baris-baris transaksi
/// dalam satu kartu yang dipisah garis tipis.
class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group});

  final DailyTransactionGroup group;

  @override
  Widget build(BuildContext context) {
    final net = group.totalIncome - group.totalExpense;
    final relative = DateFormatter.relative(group.date);
    final isNamedDay =
        relative == AppStrings.t.today || relative == AppStrings.t.yesterday;
    final dayLabel = isNamedDay
        ? '$relative · ${DateFormatter.short(group.date)}'
        : DateFormatter.withDay(group.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.sm - 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${net >= 0 ? '+' : '−'}${CurrencyFormatter.rupiah(net.abs())}',
                style: AppTextStyles.eyebrow.copyWith(
                  letterSpacing: 0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        ChunkyContainer(
          depth: AppDimens.shadowOffsetSm,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd - 2),
            child: Column(
              children: [
                for (final (i, t) in group.transactions.indexed) ...[
                  if (i > 0)
                    Container(
                      height: AppDimens.hairline,
                      margin: const EdgeInsets.only(left: 62),
                      color: AppColors.ink.withValues(alpha: 0.25),
                    ),
                  _TransactionTile(transaction: t),
                ],
              ],
            ),
          ),
        ),
      ],
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
    final sign = isIncome ? '+' : '−';

    final categoryName = category?.name ?? 'Lainnya';
    final note = transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    // Catatan lebih bermakna daripada nama kategori; kategori turun jadi
    // keterangan kecil di bawahnya.
    final title = hasNote ? note : categoryName;
    final subtitle = [
      if (hasNote) categoryName,
      wallet?.name,
    ].whereType<String>().join(' · ');

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.lg),
        color: AppColors.negative,
        child: Icon(Icons.delete_outline_rounded, color: AppColors.white),
      ),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () =>
              context.push(AppRoutes.editTransactionPath(transaction.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Text(
                  '$sign${CurrencyFormatter.rupiah(transaction.amount)}',
                  style: AppTextStyles.amount.copyWith(color: amountColor),
                ),
              ],
            ),
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
          content: Text(AppStrings.t.transactionDeleted),
          action: SnackBarAction(
            label: AppStrings.t.undo,
            textColor: AppColors.primary,
            onPressed: () => ref
                .read(transactionListProvider.notifier)
                .addTransaction(transaction),
          ),
        ),
      );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

/// Halaman kosong bergaris seperti buku tulis — bukan ikon besar di tengah.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: 0.35),
          width: AppDimens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.t.noTransactionsTitle, style: AppTextStyles.title),
          const SizedBox(height: AppDimens.xs + 2),
          Text(
            AppStrings.t.noTransactionsBody,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppDimens.md),
          // Tiga baris kosong ala buku kas.
          for (var i = 0; i < 3; i++)
            Container(
              height: 28,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    width: AppDimens.hairline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
