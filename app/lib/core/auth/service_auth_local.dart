import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ServiceAuthLocal {
  ServiceAuthLocal._();
  static final ServiceAuthLocal instance = ServiceAuthLocal._();
  static const _cleComptes = 'comptes_locaux';

  Future<List<Map<String, dynamic>>> _lireComptes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cleComptes);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _ecrireComptes(List<Map<String, dynamic>> comptes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleComptes, jsonEncode(comptes));
  }

  Future<bool> inscrire({
    required String pseudo,
    required String motDePasse,
  }) async {
    final p = pseudo.trim().toLowerCase();
    final comptes = await _lireComptes();
    final existe = comptes.any((c) => (c['pseudo'] as String).toLowerCase() == p);
    if (existe) return false;
    comptes.add({
      'pseudo': pseudo.trim(),
      'motDePasse': motDePasse,
    });
    await _ecrireComptes(comptes);
    return true;
  }

  Future<bool> connecter({
    required String pseudo,
    required String motDePasse,
  }) async {
    final p = pseudo.trim().toLowerCase();
    final comptes = await _lireComptes();
    return comptes.any(
      (c) =>
          (c['pseudo'] as String).toLowerCase() == p &&
          (c['motDePasse'] as String) == motDePasse,
    );
  }
}
