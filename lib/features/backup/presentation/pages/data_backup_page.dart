import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/failures/backup_failure.dart';
import '../providers/data_backup_providers.dart';
import '../../../../core/l10n/app_strings.dart';

class DataBackupPage extends ConsumerStatefulWidget {
  const DataBackupPage({super.key});

  @override
  ConsumerState<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends ConsumerState<DataBackupPage> {
  bool _busy = false;

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
    final result = await fs.openFile(
      acceptedTypeGroups: const [
        fs.XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
      confirmButtonText: 'Pilih',
    );
    if (result == null) return;

    if (!mounted) return;
    final confirmed = await _confirmImport();
    if (!confirmed) return;

    await _runAction(() async {
      final raw = await _readPickedFile(result);
      await ref.read(backupRepositoryProvider).restoreFromJson(raw);
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlyBudgetsProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(monthlySpendingProvider);
      if (mounted) _showMessage(AppStrings.t.backupImported);
    });
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

  Future<String> _readPickedFile(fs.XFile file) {
    return file.readAsString();
  }

  Future<bool> _confirmImport() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(AppStrings.t.importQuestion, style: AppTextStyles.title),
        content: Text(AppStrings.t.importWarning, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: AppTextStyles.label.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.t.importBackup,
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
                _BackupInfoCard(busy: _busy),
                const SizedBox(height: AppDimens.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.exportBackup,
                    icon: Icons.ios_share_rounded,
                    color: AppColors.primary,
                    onPressed: _busy ? null : _exportBackup,
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ChunkyButton(
                    label: AppStrings.t.importBackup,
                    icon: Icons.upload_file_rounded,
                    color: AppColors.accent,
                    onPressed: _busy ? null : _importBackup,
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
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.ink,
              ),
            )
          : Icon(Icons.backup_rounded, color: AppColors.ink, size: 26),
    );
  }
}
