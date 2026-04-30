import 'dart:convert';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';
import '../../../core/constants/constantes_app.dart';
import '../../../core/crypto/service_chiffrement.dart';
import '../../../core/database/service_base_de_donnees.dart';
import 'modeles.dart';
import 'depot_categories.dart';

class DepotTransactions {
  DepotTransactions._();
  static final DepotTransactions instance = DepotTransactions._();

  final _bdd = ServiceBaseDeDonnees.instance;
  final _crypto = ServiceChiffrement.instance;
  final _depotCat = DepotCategories.instance;
  final _uuid = const Uuid();

  Future<List<Transaction>> lireParMois(int annee, int mois) async {
    final db = await _bdd.base;
    final debut = DateTime(annee, mois, 1).toIso8601String();
    final fin = DateTime(annee, mois + 1, 0, 23, 59, 59).toIso8601String();

    final lignes = await db.query(
      ConstantesApp.tableTransactions,
      where: 'date_iso >= ? AND date_iso <= ?',
      whereArgs: [debut, fin],
      orderBy: 'date_iso DESC',
    );

    return Future.wait(lignes.map(_depuisMap));
  }

  Future<List<Transaction>> lireDernieres(int annee, int mois,
      {int limite = 5}) async {
    final db = await _bdd.base;
    final debut = DateTime(annee, mois, 1).toIso8601String();
    final fin = DateTime(annee, mois + 1, 0, 23, 59, 59).toIso8601String();

    final lignes = await db.query(
      ConstantesApp.tableTransactions,
      where: 'date_iso >= ? AND date_iso <= ?',
      whereArgs: [debut, fin],
      orderBy: 'date_iso DESC',
      limit: limite,
    );
    return Future.wait(lignes.map(_depuisMap));
  }

  Future<Transaction?> lireParId(String id) async {
    final db = await _bdd.base;
    final lignes = await db.query(
      ConstantesApp.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (lignes.isEmpty) return null;
    return _depuisMap(lignes.first);
  }

  Future<List<Transaction>> lireEntre(DateTime debut, DateTime fin) async {
    final db = await _bdd.base;
    final lignes = await db.query(
      ConstantesApp.tableTransactions,
      where: 'date_iso >= ? AND date_iso <= ?',
      whereArgs: [debut.toIso8601String(), fin.toIso8601String()],
      orderBy: 'date_iso DESC',
    );
    return Future.wait(lignes.map(_depuisMap));
  }

  Future<Transaction> inserer({
    required String titre,
    required double montant,
    required TypeTransaction type,
    required Categorie categorie,
    required DateTime date,
    String? note,
    List<String> cheminImages = const [],
    List<String> membreIds = const [],
    String? moyenPaiementId,
  }) async {
    final db = await _bdd.base;
    final id = _uuid.v4();

    await db.insert(ConstantesApp.tableTransactions, {
      'id': id,
      'titre_chiffre': _crypto.chiffrer(titre),
      'montant_chiffre': _crypto.chiffrerDouble(montant),
      'type': type.valeurBdd,
      'categorie_id': categorie.id,
      'date_iso': date.toIso8601String(),
      'note_chiffree': note != null ? _crypto.chiffrer(note) : null,
      'membres_json_chiffre': membreIds.isEmpty
          ? null
          : _crypto.chiffrer(jsonEncode(membreIds)),
      'moyen_paiement_id_chiffre': moyenPaiementId == null
          ? null
          : _crypto.chiffrer(moyenPaiementId),
    });

    if (cheminImages.isNotEmpty) {
      final batch = db.batch();
      for (int i = 0; i < cheminImages.length; i++) {
        batch.insert(ConstantesApp.tableImages, {
          'id': _uuid.v4(),
          'transaction_id': id,
          'chemin_chiffre': _crypto.chiffrer(cheminImages[i]),
          'ordre': i,
        });
      }
      await batch.commit(noResult: true);
    }

    return Transaction(
      id: id,
      titre: titre,
      montant: montant,
      type: type,
      categorie: categorie,
      date: date,
      note: note,
      cheminImages: cheminImages,
      membreIds: membreIds,
      moyenPaiementId: moyenPaiementId,
    );
  }

  Future<void> mettre_a_jour(Transaction t) async {
    final db = await _bdd.base;
    await db.update(
      ConstantesApp.tableTransactions,
      {
        'titre_chiffre': _crypto.chiffrer(t.titre),
        'montant_chiffre': _crypto.chiffrerDouble(t.montant),
        'type': t.type.valeurBdd,
        'categorie_id': t.categorie.id,
        'date_iso': t.date.toIso8601String(),
        'note_chiffree': t.note != null ? _crypto.chiffrer(t.note!) : null,
        'membres_json_chiffre': t.membreIds.isEmpty
            ? null
            : _crypto.chiffrer(jsonEncode(t.membreIds)),
        'moyen_paiement_id_chiffre': t.moyenPaiementId == null
            ? null
            : _crypto.chiffrer(t.moyenPaiementId!),
      },
      where: 'id = ?',
      whereArgs: [t.id],
    );

    await db.delete(
      ConstantesApp.tableImages,
      where: 'transaction_id = ?',
      whereArgs: [t.id],
    );
    if (t.cheminImages.isNotEmpty) {
      final batch = db.batch();
      for (int i = 0; i < t.cheminImages.length; i++) {
        batch.insert(ConstantesApp.tableImages, {
          'id': const Uuid().v4(),
          'transaction_id': t.id,
          'chemin_chiffre': _crypto.chiffrer(t.cheminImages[i]),
          'ordre': i,
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> supprimer(String id) async {
    final db = await _bdd.base;
    await db.delete(
      ConstantesApp.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> supprimerTous() async {
    final db = await _bdd.base;
    await db.delete(ConstantesApp.tableImages);
    await db.delete(ConstantesApp.tableTransactions);
  }

  Future<double> totalParType(TypeTransaction type, int annee, int mois) async {
    final List<Transaction> transactions = await lireParMois(annee, mois);
    final filtered = transactions.where((t) => t.type == type);
    double total = 0.0;
    for (final t in filtered) {
      total += t.montant;
    }
    return total;
  }

  Future<Transaction> _depuisMap(Map<String, dynamic> m) async {
    final cat = await _depotCat.lireParId(m['categorie_id'] as String);
    final images = await _lireImages(m['id'] as String);
    final membreIds = _lireMembreIds(m['membres_json_chiffre'] as String?);

    return Transaction(
      id: m['id'] as String,
      titre: _crypto.dechiffrer(m['titre_chiffre'] as String),
      montant: _crypto.dechiffrerDouble(m['montant_chiffre'] as String),
      type: TypeTransaction.depuisBdd(m['type'] as String),
      categorie: cat ?? CategoriesParDefaut.toutes.first,
      date: DateTime.parse(m['date_iso'] as String),
      note: m['note_chiffree'] != null
          ? _crypto.dechiffrer(m['note_chiffree'] as String)
          : null,
      cheminImages: images,
      membreIds: membreIds,
      moyenPaiementId:
          _lireMoyenPaiementId(m['moyen_paiement_id_chiffre'] as String?),
    );
  }

  String? _lireMoyenPaiementId(String? moyenPaiementIdChiffre) {
    if (moyenPaiementIdChiffre == null || moyenPaiementIdChiffre.isEmpty) {
      return null;
    }
    try {
      return _crypto.dechiffrer(moyenPaiementIdChiffre);
    } catch (_) {
      return null;
    }
  }

  List<String> _lireMembreIds(String? membresJsonChiffre) {
    if (membresJsonChiffre == null || membresJsonChiffre.isEmpty) return const [];
    try {
      final jsonTexte = _crypto.dechiffrer(membresJsonChiffre);
      final items = jsonDecode(jsonTexte) as List<dynamic>;
      return items.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _lireImages(String transactionId) async {
    final db = await _bdd.base;
    final lignes = await db.query(
      ConstantesApp.tableImages,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'ordre ASC',
    );
    return lignes
        .map((m) => _crypto.dechiffrer(m['chemin_chiffre'] as String))
        .toList();
  }
}
