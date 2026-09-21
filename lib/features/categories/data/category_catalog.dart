import 'package:flutter/material.dart';

import '../../../core/enums/transaction_type.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/category.dart';

/// Katalog kategori bawaan (preset).
///
/// ID kategori dibuat stabil (string tetap) agar transaksi lama tetap terhubung
/// meski label/ikon diubah di kemudian hari.
class CategoryCatalog {
  CategoryCatalog._();

  static  List<Category> expense = [
    Category(
      id: 'exp_food',
      name: 'Makan & Minum',
      icon: Icons.restaurant_rounded,
      color: AppColors.coral,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_transport',
      name: 'Transport',
      icon: Icons.directions_bus_rounded,
      color: AppColors.secondary,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_shopping',
      name: 'Belanja',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.purple,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_bills',
      name: 'Tagihan',
      icon: Icons.receipt_long_rounded,
      color: AppColors.accent,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_entertainment',
      name: 'Hiburan',
      icon: Icons.movie_rounded,
      color: AppColors.primary,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_health',
      name: 'Kesehatan',
      icon: Icons.favorite_rounded,
      color: AppColors.coral,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_education',
      name: 'Pendidikan',
      icon: Icons.school_rounded,
      color: AppColors.secondary,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_digital',
      name: 'Digital',
      icon: Icons.devices_rounded,
      color: AppColors.purple,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_game',
      name: 'Game',
      icon: Icons.sports_esports_rounded,
      color: AppColors.primary,
      type: TransactionType.expense,
    ),
    Category(
      id: 'exp_other',
      name: 'Lainnya',
      icon: Icons.more_horiz_rounded,
      color: AppColors.muted,
      type: TransactionType.expense,
    ),
  ];

  static  List<Category> income = [
    Category(
      id: 'inc_salary',
      name: 'Gaji',
      icon: Icons.work_rounded,
      color: AppColors.primary,
      type: TransactionType.income,
    ),
    Category(
      id: 'inc_bonus',
      name: 'Bonus',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.accent,
      type: TransactionType.income,
    ),
    Category(
      id: 'inc_business',
      name: 'Usaha',
      icon: Icons.storefront_rounded,
      color: AppColors.secondary,
      type: TransactionType.income,
    ),
    Category(
      id: 'inc_gift',
      name: 'Hadiah',
      icon: Icons.redeem_rounded,
      color: AppColors.purple,
      type: TransactionType.income,
    ),
    Category(
      id: 'inc_refund',
      name: 'Pengembalian Dana',
      icon: Icons.replay_rounded,
      color: AppColors.accent,
      type: TransactionType.income,
    ),
    Category(
      id: 'inc_other',
      name: 'Lainnya',
      icon: Icons.more_horiz_rounded,
      color: AppColors.muted,
      type: TransactionType.income,
    ),
  ];

  static const String expenseFallbackId = 'exp_other';
  static const String incomeFallbackId = 'inc_other';

  static List<Category> get all => [...expense, ...income];
}
