import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/wallet.dart';
import '../../../core/l10n/app_strings.dart';

/// Daftar dompet bawaan (preset) agar pengguna tidak mulai dari nol.
///
/// Berupa getter (bukan `const`) karena warnanya ikut palet aktif — lihat
/// [AppColors].
List<Wallet> get kDefaultWallets => [
  Wallet(
    id: 'cash',
    name: AppStrings.t.walletCash,
    icon: Icons.payments_rounded,
    color: AppColors.primary,
  ),
  Wallet(
    id: 'bank',
    name: AppStrings.t.walletBank,
    icon: Icons.account_balance_rounded,
    color: AppColors.secondary,
  ),
  Wallet(
    id: 'ewallet',
    name: AppStrings.t.walletEwallet,
    icon: Icons.qr_code_rounded,
    color: AppColors.purple,
  ),
];
