import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../../domain/entities/money_transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transaction_providers.dart';

/// Halaman input transaksi (uang masuk/keluar) bergaya chunky 3D.
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mulai dengan formulir kosong setiap kali halaman dibuka.
    Future.microtask(() => ref.invalidate(transactionFormProvider));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = ref.read(transactionFormProvider).date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(transactionFormProvider.notifier).setDate(picked);
    }
  }

  Future<void> _save() async {
    final form = ref.read(transactionFormProvider);
    final categoryId =
        form.categoryId ??
        ref.read(categoryRepositoryProvider).fallbackFor(form.type).id;

    final transaction = MoneyTransaction(
      id: IdGenerator.generate(),
      type: form.type,
      amount: form.amount,
      categoryId: categoryId,
      walletId: form.walletId,
      date: form.date,
      note: form.note.trim().isEmpty ? null : form.note.trim(),
    );

    await ref
        .read(transactionListProvider.notifier)
        .addTransaction(transaction);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'Transaksi tersimpan!',
            style: AppTextStyles.label.copyWith(color: AppColors.white),
          ),
        ),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(transactionFormProvider);
    final accent = form.type.isExpense ? AppColors.coral : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text('Catat Transaksi', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Area atas (dapat digulir bila layar pendek) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                child: Column(
                  children: [
                    _TypeToggle(
                      type: form.type,
                      onChanged: (t) =>
                          ref.read(transactionFormProvider.notifier).setType(t),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    _AmountDisplay(amount: form.amount, color: accent),
                    const SizedBox(height: AppDimens.lg),
                    _CategorySelector(
                      type: form.type,
                      selectedId: form.categoryId,
                    ),
                    const SizedBox(height: AppDimens.md),
                    const _WalletSelector(),
                    const SizedBox(height: AppDimens.md),
                    _DateAndNote(
                      date: form.date,
                      controller: _noteController,
                      onPickDate: _pickDate,
                      onNote: (v) =>
                          ref.read(transactionFormProvider.notifier).setNote(v),
                    ),
                    const SizedBox(height: AppDimens.md),
                  ],
                ),
              ),
            ),

            // ── Keypad + tombol simpan (tetap di bawah) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.sm,
                AppDimens.lg,
                AppDimens.md,
              ),
              child: Column(
                children: [
                  _Numpad(
                    onDigit: (d) => ref
                        .read(transactionFormProvider.notifier)
                        .appendDigit(d),
                    onThousands: () => ref
                        .read(transactionFormProvider.notifier)
                        .appendThousands(),
                    onDelete: () => ref
                        .read(transactionFormProvider.notifier)
                        .deleteDigit(),
                  ),
                  const SizedBox(height: AppDimens.md),
                  ChunkyButton(
                    label: 'Simpan',
                    icon: Icons.check_rounded,
                    color: accent,
                    onPressed: form.isValid ? _save : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle jenis: Pengeluaran / Pemasukan ────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        children: [
          _segment(TransactionType.expense, 'Pengeluaran', AppColors.coral),
          _segment(TransactionType.income, 'Pemasukan', AppColors.primary),
        ],
      ),
    );
  }

  Widget _segment(TransactionType value, String label, Color color) {
    final selected = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm + 4),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: selected
                ? Border.all(color: AppColors.ink, width: AppDimens.borderWidth)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tampilan nominal besar ───────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amount, required this.color});

  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('NOMINAL', style: AppTextStyles.caption),
        const SizedBox(height: AppDimens.xs),
        FittedBox(
          child: Text(
            CurrencyFormatter.rupiah(amount),
            style: AppTextStyles.display.copyWith(fontSize: 48, color: color),
          ),
        ),
      ],
    );
  }
}

// ── Pemilih kategori ─────────────────────────────────────────────────────────

class _CategorySelector extends ConsumerWidget {
  const _CategorySelector({required this.type, required this.selectedId});

  final TransactionType type;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesByTypeProvider(type));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.caption),
        const SizedBox(height: AppDimens.sm),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryChip(
                category: category,
                selected: category.id == selectedId,
                onTap: () => ref
                    .read(transactionFormProvider.notifier)
                    .setCategory(category.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 78,
        transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: selected ? category.color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, selected ? 5 : 3),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.sm,
          horizontal: 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: AppColors.ink, size: 26),
            const SizedBox(height: AppDimens.xs),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ink,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pemilih dompet ───────────────────────────────────────────────────────────

class _WalletSelector extends ConsumerWidget {
  const _WalletSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final selectedId = ref.watch(
      transactionFormProvider.select((s) => s.walletId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dompet', style: AppTextStyles.caption),
        const SizedBox(height: AppDimens.sm),
        Row(
          children: [
            for (final wallet in wallets) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => ref
                      .read(transactionFormProvider.notifier)
                      .setWallet(wallet.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: wallet.id == selectedId
                          ? wallet.color
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(wallet.icon, color: AppColors.ink, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          wallet.name,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (wallet != wallets.last) const SizedBox(width: AppDimens.sm),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Tanggal + catatan ────────────────────────────────────────────────────────

class _DateAndNote extends StatelessWidget {
  const _DateAndNote({
    required this.date,
    required this.controller,
    required this.onPickDate,
    required this.onNote,
  });

  final DateTime date;
  final TextEditingController controller;
  final VoidCallback onPickDate;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tombol tanggal
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.sm + 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(
                color: AppColors.ink,
                width: AppDimens.borderWidth,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.ink,
                ),
                const SizedBox(width: AppDimens.sm),
                Text(
                  DateFormatter.relative(date),
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        // Catatan
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(
                color: AppColors.ink,
                width: AppDimens.borderWidth,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onNote,
              maxLines: 1,
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Catatan (opsional)',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimens.md,
                  vertical: AppDimens.sm + 4,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Keypad angka ─────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onDigit,
    required this.onThousands,
    required this.onDelete,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onThousands;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          _row(row.map((d) => _digitKey(d)).toList()),
        _row([
          _specialKey('000', onThousands),
          _digitKey(0),
          _specialKey(null, onDelete, icon: Icons.backspace_rounded),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            Expanded(child: keys[i]),
            if (i != keys.length - 1) const SizedBox(width: AppDimens.sm),
          ],
        ],
      ),
    );
  }

  Widget _digitKey(int digit) {
    return _NumpadKey(label: '$digit', onTap: () => onDigit(digit));
  }

  Widget _specialKey(String? label, VoidCallback onTap, {IconData? icon}) {
    return _NumpadKey(
      label: label,
      icon: icon,
      color: AppColors.chip,
      onTap: onTap,
    );
  }
}

class _NumpadKey extends StatefulWidget {
  const _NumpadKey({
    this.label,
    this.icon,
    required this.onTap,
    this.color = AppColors.surface,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _pressed = false;
  static const double _depth = 4;

  @override
  Widget build(BuildContext context) {
    final travel = _pressed ? _depth : 0.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: 52,
        transform: Matrix4.translationValues(0, travel, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, _depth - travel),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(widget.icon, color: AppColors.ink, size: 22)
            : Text(
                widget.label ?? '',
                style: AppTextStyles.title.copyWith(fontSize: 22),
              ),
      ),
    );
  }
}
