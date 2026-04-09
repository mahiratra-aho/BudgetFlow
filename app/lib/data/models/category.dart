import 'package:uuid/uuid.dart';

typedef CategoryModel = CategorieModele;

class CategorieModele {
  final String id;
  final String name;
  final String icon; // nom icône Material (ex: 'restaurant')
  final int colorValue; // Color.value int
  final String type; // 'income' | 'expense' | 'both'
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const CategorieModele({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.type,
    required this.sortOrder,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory CategorieModele.create({
    required String name,
    required String icon,
    required int colorValue,
    required String type,
    int sortOrder = 0,
  }) {
    return CategorieModele(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      colorValue: colorValue,
      type: type,
      sortOrder: sortOrder,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory CategorieModele.fromMap(Map<String, dynamic> map) {
    return CategorieModele(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['color_value'] as int,
      type: map['type'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int,
      ),
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
      'icon': icon,
      'color_value': colorValue,
      'type': type,
      'sort_order': sortOrder,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  CategorieModele copyWith({
    String? name,
    String? icon,
    int? colorValue,
    String? type,
    int? sortOrder,
    DateTime? deletedAt,
  }) {
    return CategorieModele(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CategorieModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
