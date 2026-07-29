import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/chunky_button.dart';
import '../../../../core/widgets/chunky_container.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/data_backup_service.dart';
import '../providers/data_backup_providers.dart';

class DataBackupPage extends ConsumerStatefulWidget {
  const DataBackupPage({super.key});

  @override
  ConsumerState<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends ConsumerState<DataBackupPage> {
  bool _busy = false;

  Future<void> _exportBackup() async {
    await _runAction(() async {
      final file = await ref.read(dataBackupServiceProvider).createBackupFile();
      await SharePlus.instance.share(
        ShareParams(
          title: 'Backup DilRecord Money',
          subject: 'Backup DilRecord Money',
          text: 'File backup data DilRecord Money.',
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );
    });
  }

  Future<void> _importBackup() async {
    final result = await fs.openFile(
      acceptedTypeGroups: const [
        fs.XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
        ),
      ],
      confirmButtonText: 'Pilih',
    );
    if (result == null) return;

    if (!mounted) return;
    final confirmed = await _confirmImport();
    if (!confirmed) return;

    await _runAction(() async {
      final raw = await _readPickedFile(result);
      await ref.read(dataBackupServiceProvider).restoreBackupJson(raw);
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlyBudgetsProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(monthlySpendingProvider);
      if (mounted) _showMessage('Backup berhasil di-import.');
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on BackupDataException catch (e) {
      if (mounted) _showMessage(e.message);
    } on Object {
      if (mounted) _showMessage('Aksi backup gagal. Coba lagi ya.');
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
        title: Text('Import backup?', style: AppTextStyles.title),
        content: Text(
          'Data transaksi dan anggaran di HP ini akan diganti dengan isi file backup.',
          style: AppTextStyles.body,
        ),
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
              'Import',
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: _busy ? null : () => context.pop(),
        ),
        title: Text('Backup Data', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.lg,
            AppDimens.md,
            AppDimens.lg,
            AppDimens.xl,
          ),
          children: [
            _BackupInfoCard(busy: _busy),
            const SizedBox(height: AppDimens.lg),
            ChunkyButton(
              label: 'Export Backup',
              icon: Icons.ios_share_rounded,
              color: AppColors.primary,
              onPressed: _busy ? null : _exportBackup,
            ),
            const SizedBox(height: AppDimens.md),
            ChunkyButton(
              label: 'Import Backup',
              icon: Icons.upload_file_rounded,
              color: AppColors.accent,
              onPressed: _busy ? null : _importBackup,
            ),
          ],
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
    return ChunkyContainer(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.ink,
                        ),
                      )
                    : const Icon(
                        Icons.backup_rounded,
                        color: AppColors.ink,
                        size: 26,
                      ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Text('Pindah HP jadi aman', style: AppTextStyles.title),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            'Export membuat file JSON berisi transaksi, anggaran, dan status onboarding. Import akan memulihkan data dari file itu di perangkat baru.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
