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
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../budgets/domain/services/budget_threshold_checker.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../../domain/entities/money_transaction.dart';
import '../providers/note_history_provider.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transaction_providers.dart';

/// Halaman input transaksi (uang masuk/keluar) bergaya chunky 3D.
///
/// Dua mode:
/// - **Tambah**: [initial] = null. Form kosong, tombol "Simpan" akan `add`.
/// - **Edit**:   [initial] = transaksi yang mau diubah. Form terisi, tombol
///               "Simpan" akan `update`, ada tombol "Hapus".
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.initial});

  final MoneyTransaction? initial;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(transactionFormProvider);
      final initial = widget.initial;
      if (initial != null) {
        ref.read(transactionFormProvider.notifier).loadFrom(initial);
        _noteController.text = initial.note ?? '';
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Buka bottom sheet berisi keypad chunky. Muncul HANYA saat user tap area
  /// nominal — bukan sistem keyboard (nominal dibangun lewat keypad kustom).
  Future<void> _openNumpad(BuildContext context, Color accent) async {
    // Tutup keyboard sistem bila catatan sempat difokuskan.
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NumpadSheet(accent: accent),
    );
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
      id: form.editingId ?? IdGenerator.generate(),
      type: form.type,
      amount: form.amount,
      categoryId: categoryId,
      walletId: form.walletId,
      date: form.date,
      note: form.note.trim().isEmpty ? null : form.note.trim(),
    );

    final existingTransactions = await ref
        .read(transactionRepositoryProvider)
        .getTransactions();
    final budgets = ref
        .read(budgetRepositoryProvider)
        .getBudgetsForMonth(transaction.date.year, transaction.date.month);
    final budgetAlert = BudgetThresholdChecker.check(
      transaction: transaction,
      existingTransactions: existingTransactions,
      budgets: budgets,
    );

    final notifier = ref.read(transactionListProvider.notifier);
    if (form.isEditing) {
      await notifier.updateTransaction(transaction);
    } else {
      await notifier.addTransaction(transaction);
    }
    if (!mounted) return;

    final savedMessage = form.isEditing
        ? 'Transaksi diperbarui!'
        : 'Transaksi tersimpan!';
    if (budgetAlert == null) {
      _showSnack(savedMessage);
    } else {
      final categoryName = ref
          .read(categoryRepositoryProvider)
          .findById(budgetAlert.categoryId)
          ?.name;
      _showBudgetAlert(
        alert: budgetAlert,
        categoryName: categoryName ?? 'kategori ini',
        savedMessage: savedMessage,
      );
    }
    context.pop();
  }

  Future<void> _delete() async {
    final id = ref.read(transactionFormProvider).editingId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: const BorderSide(
            color: AppColors.ink,
            width: AppDimens.borderWidthBold,
          ),
        ),
        title: Text('Hapus transaksi ini?', style: AppTextStyles.title),
        content: Text(
          'Data yang sudah dihapus tidak bisa dipulihkan.',
          style: AppTextStyles.body.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: AppTextStyles.label.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Hapus',
              style: AppTextStyles.label.copyWith(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(transactionListProvider.notifier).deleteTransaction(id);
    if (!mounted) return;

    _showSnack('Transaksi dihapus');
    context.pop();
  }

  void _showBudgetAlert({
    required BudgetThresholdAlert alert,
    required String categoryName,
    required String savedMessage,
  }) {
    final detail = alert.isExceeded
        ? 'Anggaran $categoryName terlampaui: '
              '${CurrencyFormatter.rupiah(alert.spendingAfter)} dari '
              '${CurrencyFormatter.rupiah(alert.limit)}.'
        : 'Batas anggaran $categoryName tercapai: '
              '${CurrencyFormatter.rupiah(alert.limit)}.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.negative,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.white),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  '$savedMessage $detail',
                  key: const Key('budget-limit-notification'),
                  style: AppTextStyles.label.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            message,
            style: AppTextStyles.label.copyWith(color: AppColors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(transactionFormProvider);
    final accent = form.type.isExpense ? AppColors.coral : AppColors.primary;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final maxContentWidth = ResponsiveLayout.contentMaxWidth(context);
    final tablet = ResponsiveLayout.isTabletWidth(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          form.isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
          style: AppTextStyles.title,
        ),
        actions: [
          if (form.isEditing)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_rounded, color: AppColors.negative),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        _TypeToggle(
                          type: form.type,
                          onChanged: (t) => ref
                              .read(transactionFormProvider.notifier)
                              .setType(t),
                        ),
                        SizedBox(height: tablet ? AppDimens.xl : AppDimens.lg),
                        _AmountDisplay(
                          amount: form.amount,
                          color: accent,
                          onTap: () => _openNumpad(context, accent),
                        ),
                        SizedBox(height: tablet ? AppDimens.xl : AppDimens.lg),
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
                          onNote: (v) => ref
                              .read(transactionFormProvider.notifier)
                              .setNote(v),
                        ),
                        const SizedBox(height: AppDimens.md),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppDimens.sm,
                    horizontalPadding,
                    AppDimens.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: tablet ? 520 : double.infinity,
                    ),
                    child: ChunkyButton(
                      label: form.isEditing ? 'Perbarui' : 'Simpan',
                      icon: Icons.check_rounded,
                      color: accent,
                      onPressed: form.isValid ? _save : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final compact = ResponsiveLayout.isCompactWidth(context);

    return Container(
      padding: const EdgeInsets.all(AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        children: [
          _segment(
            TransactionType.expense,
            'Pengeluaran',
            AppColors.coral,
            compact,
          ),
          _segment(
            TransactionType.income,
            'Pemasukan',
            AppColors.primary,
            compact,
          ),
        ],
      ),
    );
  }

  Widget _segment(
    TransactionType value,
    String label,
    Color color,
    bool compact,
  ) {
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
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.ink : AppColors.muted,
                fontSize: compact ? 14 : 15,
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
  const _AmountDisplay({required this.amount, required this.color, this.onTap});

  final int amount;
  final Color color;

  /// Tap di mana saja pada area nominal → buka keypad kustom.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveLayout.isCompactWidth(context);
    final digitSize = compact ? 44.0 : 52.0;

    final digitsOnly = CurrencyFormatter.rupiah(amount, withSymbol: false);
    final empty = amount == 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        // Kartu chunky mengelilingi nominal, memberi sinyal visual "ini bisa
        // ditap untuk mengetik".
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, AppDimens.shadowOffsetSm),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NOMINAL', style: AppTextStyles.caption),
                const SizedBox(width: AppDimens.xs),
                const Icon(
                  Icons.dialpad_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.xs),
            FittedBox(
              child: Text.rich(
                TextSpan(
                  style: AppTextStyles.display.copyWith(
                    fontSize: digitSize,
                    color: empty ? AppColors.muted : color,
                    letterSpacing: 1,
                  ),
                  children: [
                    TextSpan(
                      text: 'Rp ',
                      style: TextStyle(
                        fontSize: digitSize * 0.55,
                        color: AppColors.muted,
                        letterSpacing: 0,
                      ),
                    ),
                    ..._buildDigitSpans(digitsOnly, digitSize),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            if (amount >= 1000)
              Text(
                _magnitudeLabel(amount),
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              )
            else if (empty)
              Text(
                'Ketuk untuk mengetik nominal',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  /// Membuat span per karakter: titik ribuan diberi warna [AppColors.ink]
  /// dan sedikit lebih besar/tebal supaya jelas sebagai pemisah.
  List<InlineSpan> _buildDigitSpans(String text, double baseSize) {
    return [
      for (final char in text.split(''))
        if (char == '.')
          TextSpan(
            text: char,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: baseSize * 1.15,
              fontWeight: FontWeight.w900,
              // Napas kecil di sekitar titik.
              letterSpacing: 2,
            ),
          )
        else
          TextSpan(text: char),
    ];
  }

  String _magnitudeLabel(int amount) {
    if (amount >= 1000000000) return 'miliaran';
    if (amount >= 1000000) {
      final juta = amount ~/ 1000000;
      return '$juta juta${amount % 1000000 == 0 ? '' : ' lebih'}';
    }
    final ribu = amount ~/ 1000;
    return '$ribu ribu${amount % 1000 == 0 ? '' : ' lebih'}';
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
        Text('Metode Pembayaran', style: AppTextStyles.caption),
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
    final compact = ResponsiveLayout.isCompactWidth(context);

    final dateButton = GestureDetector(
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
          mainAxisSize: MainAxisSize.min,
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
    );

    final noteField = _NoteField(controller: controller, onNote: onNote);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dateButton,
          const SizedBox(height: AppDimens.sm),
          noteField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        dateButton,
        const SizedBox(width: AppDimens.sm),
        Expanded(child: noteField),
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

// ── Bottom sheet keypad ──────────────────────────────────────────────────────

/// Sheet chunky yang muncul saat user tap area nominal.
/// Berisi preview nominal (live) + keypad + tombol "Selesai".
class _NumpadSheet extends ConsumerWidget {
  const _NumpadSheet({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(transactionFormProvider.select((s) => s.amount));
    final notifier = ref.read(transactionFormProvider.notifier);
    final formatted = CurrencyFormatter.rupiah(amount);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusLg),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.ink,
              width: AppDimens.borderWidthBold,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.lg,
          AppDimens.md,
          AppDimens.lg,
          AppDimens.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar visual sheet.
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            // Preview nominal live saat mengetik.
            FittedBox(
              child: Text(
                formatted,
                style: AppTextStyles.display.copyWith(
                  fontSize: 36,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            _Numpad(
              onDigit: notifier.appendDigit,
              onThousands: notifier.appendThousands,
              onDelete: notifier.deleteDigit,
            ),
            const SizedBox(height: AppDimens.md),
            ChunkyButton(
              label: 'Selesai',
              icon: Icons.keyboard_hide_rounded,
              color: accent,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field catatan + sugesti riwayat ──────────────────────────────────────────

/// TextField catatan yang menampilkan dropdown chunky berisi catatan yang
/// pernah dipakai pengguna sebelumnya. Sugesti diambil dari
/// [noteHistoryProvider] (di-derive dari transaksi tersimpan).
class _NoteField extends ConsumerStatefulWidget {
  const _NoteField({required this.controller, required this.onNote});

  final TextEditingController controller;
  final ValueChanged<String> onNote;

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Rebuild saat fokus berubah agar sugesti (yang bergantung pada fokus &
    // isi field) ikut ter-refresh.
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});
  void _onTextChange() => setState(() {});

  void _apply(String value) {
    widget.controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    widget.onNote(value);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(noteHistoryProvider);
    final suggestions = filterNoteSuggestions(history, widget.controller.text);
    final showDropdown = _focusNode.hasFocus && suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
              color: AppColors.ink,
              width: AppDimens.borderWidth,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onNote,
            maxLines: 1,
            style: AppTextStyles.body.copyWith(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Catatan (opsional)',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.md,
                vertical: AppDimens.sm + 4,
              ),
              border: InputBorder.none,
              suffixIcon: widget.controller.text.isEmpty
                  ? (history.isNotEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(right: AppDimens.sm),
                            child: Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          )
                        : null)
                  : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onPressed: () => _apply(''),
                    ),
            ),
          ),
        ),
        if (showDropdown) ...[
          const SizedBox(height: AppDimens.sm),
          _SuggestionList(
            suggestions: suggestions,
            onPick: (value) {
              _apply(value);
              _focusNode.unfocus();
            },
          ),
        ],
      ],
    );
  }
}

/// Daftar chip sugesti catatan. Ditampilkan sebagai kartu chunky yang
/// menempel di bawah field, bukan overlay — agar lebih ramah ke layout
/// scroll form dan tidak bertabrakan dengan bottom sheet numpad.
class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppDimens.xs),
              Text(
                'RIWAYAT CATATAN',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xs + 2),
          Wrap(
            spacing: AppDimens.xs + 2,
            runSpacing: AppDimens.xs + 2,
            children: [
              for (final note in suggestions)
                _SuggestionChip(text: note, onTap: () => onPick(note)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(
            color: AppColors.ink,
            width: AppDimens.borderWidth,
          ),
        ),
        // Batasi lebar agar catatan panjang tetap muat dalam wrap.
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.ink,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
