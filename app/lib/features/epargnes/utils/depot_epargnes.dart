import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class EpargneObjectif {
  final String id;
  final String nom;
  final double objectif;
  final double montantActuel;
  final DateTime creeLe;
  final List<String> transactionIds;

  const EpargneObjectif({
    required this.id,
    required this.nom,
    required this.objectif,
    required this.montantActuel,
    required this.creeLe,
    this.transactionIds = const [],
  });

  EpargneObjectif copyWith({
    String? nom,
    double? objectif,
    double? montantActuel,
    List<String>? transactionIds,
  }) {
    return EpargneObjectif(
      id: id,
      nom: nom ?? this.nom,
      objectif: objectif ?? this.objectif,
      montantActuel: montantActuel ?? this.montantActuel,
      creeLe: creeLe,
      transactionIds: transactionIds ?? this.transactionIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'objectif': objectif,
        'montantActuel': montantActuel,
        'creeLe': creeLe.toIso8601String(),
        'transactionIds': transactionIds,
      };

  static EpargneObjectif fromMap(Map<String, dynamic> map) => EpargneObjectif(
        id: map['id'] as String,
        nom: map['nom'] as String,
        objectif: (map['objectif'] as num).toDouble(),
        montantActuel: (map['montantActuel'] as num).toDouble(),
        creeLe: DateTime.parse(map['creeLe'] as String),
        transactionIds:
            (map['transactionIds'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

class DepotEpargnes {
  DepotEpargnes._();
  static final DepotEpargnes instance = DepotEpargnes._();
  static const _cle = 'epargnes_objectifs';
  final _uuid = const Uuid();

  Future<List<EpargneObjectif>> lireTous() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString(_cle);
    if (brut == null || brut.isEmpty) return [];
    final liste = (jsonDecode(brut) as List<dynamic>)
        .map((e) => EpargneObjectif.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    liste.sort((a, b) => b.creeLe.compareTo(a.creeLe));
    return liste;
  }

  Future<void> _sauvegarder(List<EpargneObjectif> epargnes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cle,
      jsonEncode(epargnes.map((e) => e.toMap()).toList()),
    );
  }

  Future<EpargneObjectif> ajouter({
    required String nom,
    required double objectif,
  }) async {
    final existants = await lireTous();
    final epargne = EpargneObjectif(
      id: _uuid.v4(),
      nom: nom,
      objectif: objectif,
      montantActuel: 0,
      creeLe: DateTime.now(),
    );
    await _sauvegarder([epargne, ...existants]);
    return epargne;
  }

  Future<void> mettreAJour(EpargneObjectif epargne) async {
    final existants = await lireTous();
    final maj = existants.map((e) => e.id == epargne.id ? epargne : e).toList();
    await _sauvegarder(maj);
  }

  Future<void> supprimer(String id) async {
    final existants = await lireTous();
    await _sauvegarder(existants.where((e) => e.id != id).toList());
  }

  Future<void> supprimerTous() async {
    await _sauvegarder([]);
  }
}
