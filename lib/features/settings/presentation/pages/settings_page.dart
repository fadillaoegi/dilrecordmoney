import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_theme_mode.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_providers.dart';
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
        Icon(icon, size: 18, color: AppColors.ink),
        const SizedBox(width: AppDimens.sm),
        Text(label, style: AppTextStyles.title.copyWith(fontSize: 16)),
      ],
    );
  }
}

/// Baris pilihan bergaya chunky dengan penanda terpilih di kanan.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ChunkyContainer(
        color: selected ? AppColors.chip : AppColors.surface,
        depth: selected ? AppDimens.shadowOffsetSm : 2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
