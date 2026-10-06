import 'package:flutter/material.dart';

import '../../../core/enums/transaction_type.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/category.dart';

/// Katalog kategori bawaan (preset).
///
/// ID kategori dibuat stabil (string tetap) agar transaksi lama tetap terhubung
/// meski label/ikon diubah di kemudian hari.
///
/// Berupa *getter* (bukan list statis) supaya nama ikut bahasa aktif dan
/// warna ikut palet aktif setiap kali dibaca — list statis akan "membeku"
/// di palet/bahasa saat pertama kali diakses.
class CategoryCatalog {
  CategoryCatalog._();

  static List<Category> get expense => _expenseFor(AppStrings.t);

  static List<Category> get income => _incomeFor(AppStrings.t);

  /// Peta "jenis:nama huruf kecil" → id untuk nama kategori bawaan di
  /// **semua** bahasa. Dipakai impor supaya laporan berbahasa Indonesia tetap
  /// cocok ke kategori bawaan walau aplikasi sedang berbahasa Inggris.
  static Map<String, String> get nameAliases => {
    for (final locale in AppLocale.values)
      for (final c in [
        ..._expenseFor(AppStrings.forLocale(locale)),
        ..._incomeFor(AppStrings.forLocale(locale)),
      ])
        aliasKey(c.name, c.type): c.id,
  };

  static String aliasKey(String name, TransactionType type) =>
      '${type.key}:${name.trim().toLowerCase()}';

  static List<Category> _expenseFor(AppStrings t) {
    return [
      _expense(
        'exp_food',
        t.catFood,
        Icons.restaurant_rounded,
        AppColors.coral,
      ),
      _expense(
        'exp_transport',
        t.catTransport,
        Icons.directions_bus_rounded,
        AppColors.secondary,
      ),
      _expense(
        'exp_shopping',
        t.catShopping,
        Icons.shopping_bag_rounded,
        AppColors.purple,
      ),
      _expense(
        'exp_bills',
        t.catBills,
        Icons.receipt_long_rounded,
        AppColors.accent,
      ),
      _expense(
        'exp_entertainment',
        t.catEntertainment,
        Icons.movie_rounded,
        AppColors.primary,
      ),
      _expense(
        'exp_health',
        t.catHealth,
        Icons.favorite_rounded,
        AppColors.coral,
      ),
      _expense(
        'exp_education',
        t.catEducation,
        Icons.school_rounded,
        AppColors.secondary,
      ),
      _expense(
        'exp_digital',
        'Digital',
        Icons.devices_rounded,
        AppColors.purple,
      ),
      _expense(
        'exp_game',
        'Game',
        Icons.sports_esports_rounded,
        AppColors.primary,
      ),
      _expense(
        'exp_sports',
        t.catSports,
        Icons.fitness_center_rounded,
        AppColors.accent,
      ),
      _expense(
        'exp_vape',
        t.catVape,
        Icons.smoking_rooms_rounded,
        AppColors.purple,
      ),
      _expense(
        expenseFallbackId,
        t.catOther,
        Icons.more_horiz_rounded,
        AppColors.chip,
      ),
    ];
  }

  static List<Category> _incomeFor(AppStrings t) {
    return [
      _income('inc_salary', t.catSalary, Icons.work_rounded, AppColors.primary),
      _income(
        'inc_bonus',
        t.catBonus,
        Icons.card_giftcard_rounded,
        AppColors.accent,
      ),
      _income(
        'inc_business',
        t.catBusiness,
        Icons.storefront_rounded,
        AppColors.secondary,
      ),
      _income(
        'inc_freelance',
        t.catFreelance,
        Icons.laptop_mac_rounded,
        AppColors.coral,
      ),
      _income('inc_gift', t.catGift, Icons.redeem_rounded, AppColors.purple),
      _income(
        'inc_refund',
        t.catRefund,
        Icons.replay_rounded,
        AppColors.accent,
      ),
      _income(
        incomeFallbackId,
        t.catOther,
        Icons.more_horiz_rounded,
        AppColors.chip,
      ),
    ];
  }

  static const String expenseFallbackId = 'exp_other';
  static const String incomeFallbackId = 'inc_other';

  static List<Category> get all => [...expense, ...income];

  static Category _expense(String id, String name, IconData icon, Color c) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: c,
        type: TransactionType.expense,
      );

  static Category _income(String id, String name, IconData icon, Color c) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        color: c,
        type: TransactionType.income,
      );
}
