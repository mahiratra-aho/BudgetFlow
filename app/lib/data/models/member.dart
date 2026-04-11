import 'package:uuid/uuid.dart';

class MembreModele {
  final String id;
  final String name;
  final int colorValue;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const MembreModele({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory MembreModele.create({
    required String name,
    required int colorValue,
    int sortOrder = 0,
  }) {
    return MembreModele(
      id: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      sortOrder: sortOrder,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory MembreModele.fromMap(Map<String, dynamic> map) {
    return MembreModele(
      id: map['id'] as String,
      name: map['name'] as String,
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
      'color_value': colorValue,
      'sort_order': sortOrder,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  MembreModele copyWith({
    String? name,
    int? colorValue,
    int? sortOrder,
    DateTime? deletedAt,
  }) {
    return MembreModele(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MembreModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
