import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/budget_model.dart';

/// Sumber data lokal anggaran (SharedPreferences JSON). Bisa ditukar ke DB.
abstract interface class BudgetLocalDataSource {
  List<BudgetModel> readAll();
  Future<void> writeAll(List<BudgetModel> budgets);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  const BudgetLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  List<BudgetModel> readAll() {
    final raw = _prefs.getString(AppConstants.kBudgets);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> writeAll(List<BudgetModel> budgets) {
    final encoded = jsonEncode(budgets.map((e) => e.toJson()).toList());
    return _prefs.setString(AppConstants.kBudgets, encoded);
  }
}
