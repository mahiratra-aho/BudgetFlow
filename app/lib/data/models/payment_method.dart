import 'package:uuid/uuid.dart';

class MoyenPaiementModele {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const MoyenPaiementModele({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.sortOrder,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory MoyenPaiementModele.create({
    required String name,
    required String icon,
    required int colorValue,
    int sortOrder = 0,
  }) {
    return MoyenPaiementModele(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      colorValue: colorValue,
      sortOrder: sortOrder,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory MoyenPaiementModele.fromMap(Map<String, dynamic> map) {
    return MoyenPaiementModele(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['color_value'] as int,
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
      'sort_order': sortOrder,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  MoyenPaiementModele copyWith({
    String? name,
    String? icon,
    int? colorValue,
    int? sortOrder,
    DateTime? deletedAt,
  }) {
    return MoyenPaiementModele(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoyenPaiementModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
