import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class EntiteSimple {
  final String id;
  final String nom;
  final String? detail;

  const EntiteSimple({
    required this.id,
    required this.nom,
    this.detail,
  });

  EntiteSimple copyWith({String? nom, String? detail}) => EntiteSimple(
        id: id,
        nom: nom ?? this.nom,
        detail: detail ?? this.detail,
      );

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom, 'detail': detail};

  static EntiteSimple fromMap(Map<String, dynamic> map) => EntiteSimple(
        id: map['id'] as String,
        nom: map['nom'] as String,
        detail: map['detail'] as String?,
      );
}

class DepotEntitesSimples {
  DepotEntitesSimples._();
  static final DepotEntitesSimples instance = DepotEntitesSimples._();
  final _uuid = const Uuid();

  Future<List<EntiteSimple>> lireTous(String cle) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cle);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => EntiteSimple.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(String cle, List<EntiteSimple> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cle, jsonEncode(data.map((e) => e.toMap()).toList()));
  }

  Future<void> ajouter(String cle, String nom, {String? detail}) async {
    final data = await lireTous(cle);
    data.add(EntiteSimple(id: _uuid.v4(), nom: nom, detail: detail));
    await _save(cle, data);
  }

  Future<void> mettreAJour(String cle, EntiteSimple item) async {
    final data = await lireTous(cle);
    final maj = data.map((e) => e.id == item.id ? item : e).toList();
    await _save(cle, maj);
  }

  Future<void> supprimer(String cle, String id) async {
    final data = await lireTous(cle);
    await _save(cle, data.where((e) => e.id != id).toList());
  }
}
