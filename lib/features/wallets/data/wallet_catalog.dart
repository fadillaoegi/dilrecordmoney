import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/wallet.dart';

/// Daftar dompet bawaan (preset) agar pengguna tidak mulai dari nol.
const List<Wallet> kDefaultWallets = [
  Wallet(
    id: 'cash',
    name: 'Tunai',
    icon: Icons.payments_rounded,
    color: AppColors.primary,
  ),
  Wallet(
    id: 'bank',
    name: 'Bank',
    icon: Icons.account_balance_rounded,
    color: AppColors.secondary,
  ),
  Wallet(
    id: 'ewallet',
    name: 'E-Wallet',
    icon: Icons.qr_code_rounded,
    color: AppColors.purple,
  ),
];
