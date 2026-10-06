import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_theme_mode.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/chunky_container.dart';

/// Halaman pengaturan: pilih bahasa & mode tampilan (terang/gelap).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);
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
        title: Text(AppStrings.t.settings, style: AppTextStyles.title),
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
                AppDimens.lg,
              ),
              children: [
                _SectionTitle(
                  icon: Icons.language_rounded,
                  label: AppStrings.t.language,
                ),
                const SizedBox(height: AppDimens.sm),
                for (final option in AppLocale.values) ...[
                  _OptionRow(
                    label: option.label,
                    selected: option == locale,
                    onTap: () =>
                        ref.read(appLocaleProvider.notifier).set(option),
                  ),
                  const SizedBox(height: AppDimens.sm),
                ],
                const SizedBox(height: AppDimens.md),
                _SectionTitle(
                  icon: Icons.contrast_rounded,
                  label: AppStrings.t.appearance,
                ),
                const SizedBox(height: AppDimens.sm),
                for (final option in AppThemeMode.values) ...[
                  _OptionRow(
                    label: option.label,
                    selected: option == themeMode,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).set(option),
                  ),
                  const SizedBox(height: AppDimens.sm),
                ],
                const SizedBox(height: AppDimens.md),
                _SectionTitle(
                  icon: Icons.save_alt_rounded,
                  label: AppStrings.t.backupData,
                ),
                const SizedBox(height: AppDimens.sm),
                _OptionRow(
                  label:
                      '${AppStrings.t.exportBackup} · ${AppStrings.t.importCsv}',
                  trailing: Icons.chevron_right_rounded,
                  onTap: () => context.push(AppRoutes.backup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: AppDimens.xs + 2),
        Text(label.toUpperCase(), style: AppTextStyles.eyebrow),
      ],
    );
  }
}

/// Baris pilihan bergaya chunky dengan penanda terpilih di kanan.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Ikon kanan untuk baris navigasi; null → penanda pilihan.
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ChunkyContainer(
        color: AppColors.surface,
        depth: selected ? AppDimens.shadowOffsetSm : 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 20, color: AppColors.ink)
            else
              // Kotak centang persegi: terisi tinta saat terpilih.
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.white,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
