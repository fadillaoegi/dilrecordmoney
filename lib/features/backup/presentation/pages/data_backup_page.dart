import 'dart:async';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/enums/period_type.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../export/domain/entities/spreadsheet_import_result.dart';
import '../../../export/domain/enums/export_format.dart';
import '../../../export/presentation/providers/export_providers.dart';
import '../../../transactions/domain/entities/period_selection.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../../domain/failures/backup_failure.dart';
import '../providers/data_backup_providers.dart';

/// Sentinel: gunakan null untuk "Semua Transaksi" (tidak difilter).
class DataBackupPage extends ConsumerStatefulWidget {
  const DataBackupPage({super.key});

  @override
  ConsumerState<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends ConsumerState<DataBackupPage> {
  bool _busy = false;

  // ── JSON Backup ──────────────────────────────────────────────────────────

  Future<void> _exportBackup() async {
    await _runAction(() async {
      final repo = ref.read(backupRepositoryProvider);
      final snapshot = repo.createSnapshot();
      final file = await repo.writeSnapshotToFile(snapshot);
      await SharePlus.instance.share(
        ShareParams(
          title: AppStrings.t.backupShareTitle,
          subject: AppStrings.t.backupShareTitle,
          text: AppStrings.t.backupFileDesc,
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );
    });
  }

  Future<void> _importBackup() async {
    final result = await _pickFile(_jsonTypes);
    if (result == null) return;

    if (!mounted) return;
    final confirmed = await _confirmDialog(
      title: AppStrings.t.importQuestion,
      content: AppStrings.t.importWarning,
      confirmLabel: AppStrings.t.importBackup,
    );
    if (!confirmed) return;

    await _runAction(() async {
      final raw = await result.readAsString();
      await ref.read(backupRepositoryProvider).restoreFromJson(raw);
      ref.invalidate(transactionListProvider);
      ref.invalidate(customCategoriesProvider);
      ref.invalidate(monthlyBudgetsProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(monthlySpendingProvider);
      if (mounted) _showMessage(AppStrings.t.backupImported);
    });
  }

  // ── Multi-format Export ──────────────────────────────────────────────────

  /// Tampilkan period picker bottom sheet, lalu jalankan export.
  Future<void> _exportFormat(ExportFormat format) async {
    // Sheet ditutup tanpa memilih → batal. `pick.period == null` = semua.
    final pick = await _showPeriodPicker();
    if (pick == null || !mounted) return;
    final period = pick.period;

    await _runAction(() async {
      final exportRepo = ref.read(exportRepositoryProvider);
      final allTransactions =
          ref.read(transactionListProvider).asData?.value ?? [];

      if (allTransactions.isEmpty) {
        throw const BackupFailure('Belum ada transaksi untuk diekspor.');
      }

      // Filter transaksi berdasarkan periode (null = semua)
      final transactions = period == null
          ? allTransactions
          : allTransactions.where((t) => period.contains(t.date)).toList();

      if (transactions.isEmpty) {
        throw const BackupFailure(
          'Tidak ada transaksi dalam periode yang dipilih.',
        );
      }

      final allCategories = [
        ...ref.read(categoriesByTypeProvider(TransactionType.income)),
        ...ref.read(categoriesByTypeProvider(TransactionType.expense)),
      ];
      final wallets = ref.read(walletsProvider);

      final file = switch (format) {
        ExportFormat.pdf => await exportRepo.exportToPdf(
          transactions: transactions,
          categories: allCategories,
          wallets: wallets,
        ),
        ExportFormat.csv => await exportRepo.exportToCsv(
          transactions: transactions,
          categories: allCategories,
          wallets: wallets,
        ),
        ExportFormat.xls => await exportRepo.exportToXls(
          transactions: transactions,
          categories: allCategories,
          wallets: wallets,
        ),
      };

      await SharePlus.instance.share(
        ShareParams(
          title: 'DilRecord Money — Export ${format.label}',
          subject: 'DilRecord Money — Export ${format.label}',
          files: [XFile(file.path, mimeType: format.mimeType)],
        ),
      );

      if (mounted) _showMessage(AppStrings.t.exportSuccess);
    });
  }

  /// Tampilkan bottom sheet period picker.
  ///   - null → sheet ditutup (batal)
  ///   - `_PickResult(period: null)` → semua transaksi
  ///   - `_PickResult(period: ...)` → periode tertentu
  Future<_PickResult?> _showPeriodPicker() {
    return showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PeriodPickerSheet(),
    );
  }

  // ── Spreadsheet Import ───────────────────────────────────────────────────

  Future<void> _importCsv() async {
    final result = await _pickFile(_spreadsheetTypes);
    if (result == null) return;

    if (!mounted) return;
    final confirmed = await _confirmDialog(
      title: AppStrings.t.importCsv,
      content: AppStrings.t.importWarningCsv,
      confirmLabel: AppStrings.t.importCsv,
    );
    if (!confirmed) return;

    await _runAction(() async {
      final extension = result.name.contains('.')
          ? result.name.split('.').last.toLowerCase()
          : '';
      final categories = [
        ...ref.read(categoriesByTypeProvider(TransactionType.income)),
        ...ref.read(categoriesByTypeProvider(TransactionType.expense)),
      ];
      final SpreadsheetImportResult imported;
      try {
        imported = await ref
            .read(exportRepositoryProvider)
            .importFromSpreadsheet(
              bytes: await result.readAsBytes(),
              extension: extension,
              existingCategories: categories,
              existingTransactions:
                  ref.read(transactionListProvider).asData?.value ?? const [],
            );
      } on FormatException catch (e) {
        throw BackupFailure(e.message);
      }

      if (imported.transactions.isEmpty) {
        throw BackupFailure(AppStrings.t.importNothingNew);
      }

      await ref
          .read(customCategoriesProvider.notifier)
          .addImported(imported.newCategories);
      await ref
          .read(transactionListProvider.notifier)
          .addAll(imported.transactions);

      if (mounted) {
        final skipped = imported.skippedDuplicates + imported.skippedInvalid;
        _showMessage(
          '${imported.transactions.length} ${AppStrings.t.importSuccessCsv}'
          '${skipped > 0 ? ' $skipped ${AppStrings.t.importRowsSkipped}' : ''}',
        );
      }
    });
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Membuka pemilih file. Error platform (mis. filter tipe yang ditolak)
  /// ditampilkan sebagai pesan, bukan dibiarkan diam-diam gagal.
  Future<fs.XFile?> _pickFile(List<fs.XTypeGroup> types) async {
    try {
      return await fs.openFile(
        acceptedTypeGroups: types,
        confirmButtonText: AppStrings.t.pickFile,
      );
    } on Object {
      if (mounted) _showMessage(AppStrings.t.filePickerFailed);
      return null;
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on BackupFailure catch (e) {
      if (mounted) _showMessage(e.message);
    } on Object {
      if (mounted) _showMessage(AppStrings.t.backupActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.title),
        content: Text(content, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.t.cancel,
              style: AppTextStyles.label.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: AppTextStyles.label.copyWith(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message) {
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
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final maxContentWidth = ResponsiveLayout.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: _busy ? null : () => context.pop(),
        ),
        title: Text(AppStrings.t.backupData, style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppDimens.md,
                horizontalPadding,
                AppDimens.xl,
              ),
              children: [
                // ── Info card ───────────────────────────────────────────────
                _BackupInfoCard(busy: _busy),
                const SizedBox(height: AppDimens.lg),

                // ── JSON Backup section ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.backup_rounded,
                  label: AppStrings.t.backupData,
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.exportBackup,
                    icon: Icons.ios_share_rounded,
                    color: AppColors.primary,
                    onPressed: _busy ? null : _exportBackup,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.importBackup,
                    icon: Icons.upload_file_rounded,
                    color: AppColors.accent,
                    onPressed: _busy ? null : _importBackup,
                  ),
                ),

                const SizedBox(height: AppDimens.xl),
                const _Divider(),
                const SizedBox(height: AppDimens.lg),

                // ── Export Laporan section ──────────────────────────────────
                _SectionHeader(
                  icon: Icons.table_chart_rounded,
                  label: AppStrings.t.exportReport,
                ),
                const SizedBox(height: AppDimens.xs),
                Text(
                  AppStrings.t.exportPeriod,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.exportPdf,
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.coral,
                    onPressed: _busy
                        ? null
                        : () => _exportFormat(ExportFormat.pdf),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.exportCsv,
                    icon: Icons.grid_on_rounded,
                    color: AppColors.accent,
                    onPressed: _busy
                        ? null
                        : () => _exportFormat(ExportFormat.csv),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.exportXls,
                    icon: Icons.table_rows_rounded,
                    color: AppColors.purple,
                    onPressed: _busy
                        ? null
                        : () => _exportFormat(ExportFormat.xls),
                  ),
                ),

                const SizedBox(height: AppDimens.xl),
                const _Divider(),
                const SizedBox(height: AppDimens.lg),

                // ── Import CSV section ──────────────────────────────────────
                _SectionHeader(
                  icon: Icons.upload_rounded,
                  label: AppStrings.t.importCsv,
                ),
                const SizedBox(height: AppDimens.xs),
                Text(
                  AppStrings.t.importWarningCsv,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.importCsv,
                    icon: Icons.file_upload_outlined,
                    color: AppColors.primary,
                    onPressed: _busy ? null : _importCsv,
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

// ── Internal helpers ──────────────────────────────────────────────────────────

// Filter file picker per platform: Android memakai `mimeTypes` (MIME CSV
// berbeda-beda antar penyedia file), iOS wajib `uniformTypeIdentifiers` —
// tanpanya `openFile` langsung melempar ArgumentError di iPhone.
const _jsonTypes = [
  fs.XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json', 'text/plain', 'application/octet-stream'],
    uniformTypeIdentifiers: ['public.json', 'public.text', 'public.data'],
  ),
];

const _spreadsheetTypes = [
  fs.XTypeGroup(
    label: 'CSV / Excel',
    extensions: ['csv', 'xls', 'xlsx'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'application/csv',
      'text/plain',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/octet-stream',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.plain-text',
      'com.microsoft.excel.xls',
      'org.openxmlformats.spreadsheetml.sheet',
    ],
  ),
];

/// Wrapper agar bisa membedakan "Semua" (period=null) vs cancel (sheet=null).
class _PickResult {
  const _PickResult({this.period});
  final PeriodSelection? period;
}

// ── Period Picker Bottom Sheet ────────────────────────────────────────────────

class _PeriodPickerSheet extends StatefulWidget {
  const _PeriodPickerSheet();

  @override
  State<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<_PeriodPickerSheet> {
  /// null = Semua Transaksi
  PeriodType? _selectedType;

  /// Anchor untuk periode yang dipilih.
  DateTime _anchor = DateTime.now();

  PeriodSelection get _currentPeriod => PeriodSelection(
    type: _selectedType ?? PeriodType.monthly,
    anchor: _anchor,
  );

  String get _periodLabel {
    if (_selectedType == null) return AppStrings.t.allPeriods;
    return switch (_selectedType!) {
      PeriodType.daily => DateFormatter.relative(_anchor),
      PeriodType.weekly =>
        '${DateFormatter.short(_currentPeriod.start)} – ${DateFormatter.short(_currentPeriod.lastDay)}',
      PeriodType.monthly => DateFormatter.monthYear(_anchor),
      PeriodType.yearly => '${_anchor.year}',
    };
  }

  void _shiftAnchor(int direction) {
    if (_selectedType == null) return;
    setState(() {
      _anchor = _currentPeriod.shift(direction).anchor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.md,
            AppDimens.md,
            AppDimens.md,
            AppDimens.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),

              // Title
              Text(AppStrings.t.exportPeriod, style: AppTextStyles.title),
              const SizedBox(height: AppDimens.md),

              // ── Tipe periode chips ──────────────────────────────────────
              _PeriodTypeChips(
                selected: _selectedType,
                onChanged: (type) => setState(() {
                  _selectedType = type;
                  _anchor = DateTime.now();
                }),
              ),
              const SizedBox(height: AppDimens.md),

              // ── Navigator ‹ label › ─────────────────────────────────────
              AnimatedOpacity(
                opacity: _selectedType == null ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: _PeriodNavigator(
                  label: _periodLabel,
                  onPrev: _selectedType == null ? null : () => _shiftAnchor(-1),
                  onNext: _selectedType == null ? null : () => _shiftAnchor(1),
                ),
              ),
              const SizedBox(height: AppDimens.lg),

              // ── Tombol Pilih ────────────────────────────────────────────
              ChunkyButton(
                label: AppStrings.t.choose,
                icon: Icons.check_rounded,
                color: AppColors.primary,
                onPressed: () => Navigator.of(context).pop(
                  _PickResult(
                    period: _selectedType == null
                        ? null
                        : PeriodSelection(
                            type: _selectedType!,
                            anchor: _anchor,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Period Type Chips ─────────────────────────────────────────────────────────

class _PeriodTypeChips extends StatelessWidget {
  const _PeriodTypeChips({required this.selected, required this.onChanged});

  final PeriodType? selected;
  final void Function(PeriodType?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimens.xs,
      runSpacing: AppDimens.xs,
      children: [
        // "Semua" chip
        _Chip(
          label: AppStrings.t.allPeriods,
          active: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final type in PeriodType.values)
          _Chip(
            label: type.label,
            active: selected == type,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sm + 2,
          vertical: AppDimens.xs + 2,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.chip,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.ink,
            width: active ? AppDimens.borderWidth : 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: AppColors.ink,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Period Navigator ──────────────────────────────────────────────────────────

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: Center(child: Text(label, style: AppTextStyles.label)),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surface : AppColors.chip,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: onTap != null ? AppColors.ink : AppColors.muted,
            width: AppDimens.borderWidth,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppColors.ink : AppColors.muted,
          size: 18,
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.ink),
        const SizedBox(width: AppDimens.xs),
        Text(label, style: AppTextStyles.title),
      ],
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.borderWidth,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
    );
  }
}

// ── BackupInfoCard ────────────────────────────────────────────────────────────

class _BackupInfoCard extends StatelessWidget {
  const _BackupInfoCard({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveLayout.isCompactWidth(context);

    return ChunkyContainer(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            _BackupIconBadge(busy: busy),
            const SizedBox(height: AppDimens.sm),
            Text(AppStrings.t.safeToSwitchPhone, style: AppTextStyles.title),
          ] else
            Row(
              children: [
                _BackupIconBadge(busy: busy),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    AppStrings.t.safeToSwitchPhone,
                    style: AppTextStyles.title,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppDimens.md),
          Text(
            AppStrings.t.backupExplain,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BackupIconBadge extends StatelessWidget {
  const _BackupIconBadge({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.ink, width: AppDimens.borderWidth),
      ),
      child: busy
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.ink,
              ),
            )
          : Icon(Icons.backup_rounded, color: AppColors.ink, size: 26),
    );
  }
}
