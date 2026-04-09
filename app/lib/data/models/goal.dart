import 'package:uuid/uuid.dart';

typedef GoalModel = ObjectifModele;

/// Objectif d'épargne
class ObjectifModele {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final int colorValue;
  final DateTime? deadline;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const ObjectifModele({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.colorValue,
    this.deadline,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  /// Borne la progression entre 0 et 1 pour simplifier l'affichage des jauges.
  double get progression =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get estAtteint => currentAmount >= targetAmount;

  factory ObjectifModele.create({
    required String name,
    required double targetAmount,
    required String icon,
    required int colorValue,
    DateTime? deadline,
    double currentAmount = 0.0,
  }) {
    return ObjectifModele(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      icon: icon,
      colorValue: colorValue,
      deadline: deadline,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory ObjectifModele.fromMap(Map<String, dynamic> map) {
    return ObjectifModele(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num? ?? 0).toDouble(),
      icon: map['icon'] as String,
      colorValue: map['color_value'] as int,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
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
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'icon': icon,
      'color_value': colorValue,
      'deadline': deadline?.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  ObjectifModele copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    int? colorValue,
    DateTime? deadline,
    DateTime? deletedAt,
  }) {
    return ObjectifModele(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      deadline: deadline ?? this.deadline,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ObjectifModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
