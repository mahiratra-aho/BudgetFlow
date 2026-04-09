import 'package:uuid/uuid.dart';

typedef BudgetModel = BudgetModele;

/// Budget mensuel par catégorie
class BudgetModele {
  final String id;
  final String categoryId;
  final double amount;
  final int month; // 1–12
  final int year;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const BudgetModele({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory BudgetModele.create({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) {
    return BudgetModele(
      id: const Uuid().v4(),
      categoryId: categoryId,
      amount: amount,
      month: month,
      year: year,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory BudgetModele.fromMap(Map<String, dynamic> map) {
    return BudgetModele(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  BudgetModele copyWith({
    double? amount,
    DateTime? deletedAt,
  }) {
    return BudgetModele(
      id: id,
      categoryId: categoryId,
      amount: amount ?? this.amount,
      month: month,
      year: year,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BudgetModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
