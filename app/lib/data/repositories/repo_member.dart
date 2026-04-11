import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/member.dart';

class RepoMembre {
  final AppDatabase _baseDeDonnees;

  RepoMembre(this._baseDeDonnees);

  Future<List<MembreModele>> obtenirTous({
    bool inclureSupprimees = false,
  }) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final clauseWhere =
        inclureSupprimees ? null : AppDatabase.clauseNonSupprime;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableMembres,
      where: clauseWhere,
      orderBy: 'sort_order ASC',
    );
    return lignes.map(MembreModele.fromMap).toList();
  }

  Future<MembreModele?> obtenirParId(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableMembres,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
    if (lignes.isEmpty) return null;
    return MembreModele.fromMap(lignes.first);
  }

  Future<void> ajouter(MembreModele membre) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableMembres,
      membre.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(MembreModele membre) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableMembres,
      membre.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [membre.id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableMembres,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }

  /// Réordonne la liste des membres.
  ///
  /// [ordreIds] est la liste des identifiants dans le nouvel ordre souhaité.
  Future<void> reordonner(List<String> ordreIds) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    final batch = baseDeDonnees.batch();
    for (int i = 0; i < ordreIds.length; i++) {
      batch.update(
        AppDatabase.tableMembres,
        {
          'sort_order': i,
          AppDatabase.colonneMisAJourLe: maintenant,
        },
        where: '${AppDatabase.colonneId} = ?',
        whereArgs: [ordreIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }
}
