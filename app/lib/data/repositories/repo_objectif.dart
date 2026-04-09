import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/goal.dart';

class RepoObjectif {
  final AppDatabase _baseDeDonnees;

  RepoObjectif(this._baseDeDonnees);

  Future<List<ObjectifModele>> obtenirTous() async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableObjectifs,
      where: AppDatabase.clauseNonSupprime,
      orderBy: '${AppDatabase.colonneMisAJourLe} DESC',
    );
    return lignes.map(ObjectifModele.fromMap).toList();
  }

  Future<ObjectifModele?> obtenirParId(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableObjectifs,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
    if (lignes.isEmpty) return null;
    return ObjectifModele.fromMap(lignes.first);
  }

  Future<void> ajouter(ObjectifModele objectif) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableObjectifs,
      objectif.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(ObjectifModele objectif) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableObjectifs,
      objectif.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [objectif.id],
    );
  }

  Future<void> ajouterMontant(String id, double montant) async {
    final objectif = await obtenirParId(id);
    if (objectif == null) return;
    final objectifMisAJour = objectif.copyWith(
      currentAmount: objectif.currentAmount + montant,
    );
    await mettreAJour(objectifMisAJour);
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableObjectifs,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }
}
