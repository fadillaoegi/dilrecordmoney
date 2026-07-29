import '../../domain/entities/budget.dart';

/// Model data anggaran dengan (de)serialisasi JSON.
class BudgetModel extends Budget {
  const BudgetModel({
    required super.id,
    required super.categoryId,
    required super.year,
    required super.month,
    required super.limit,
  });

  factory BudgetModel.fromEntity(Budget b) => BudgetModel(
        id: b.id,
        categoryId: b.categoryId,
        year: b.year,
        month: b.month,
        limit: b.limit,
      );

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        limit: json['limit'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'year': year,
        'month': month,
        'limit': limit,
      };
}
