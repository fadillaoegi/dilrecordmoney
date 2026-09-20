import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/category_import.dart';

/// Penyimpanan kategori yang berasal dari impor spreadsheet.
abstract interface class CustomCategoryLocalDataSource {
  List<CategoryImport> readAll();
  Future<void> writeAll(List<CategoryImport> categories);
}

class CustomCategoryLocalDataSourceImpl
    implements CustomCategoryLocalDataSource {
  const CustomCategoryLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  List<CategoryImport> readAll() {
    final raw = _prefs.getString(AppConstants.kCustomCategories);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) {
      final json = item as Map<String, dynamic>;
      return CategoryImport(
        name: json['name'] as String,
        type: TransactionType.fromKey(json['type'] as String),
      );
    }).toList();
  }

  @override
  Future<void> writeAll(List<CategoryImport> categories) {
    return _prefs.setString(
      AppConstants.kCustomCategories,
      jsonEncode([
        for (final category in categories)
          {'name': category.name, 'type': category.type.key},
      ]),
    );
  }
}
