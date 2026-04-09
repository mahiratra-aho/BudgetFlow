import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/category.dart';

class RepoCategorie {
  final AppDatabase _baseDeDonnees;

  RepoCategorie(this._baseDeDonnees);

  Future<List<CategorieModele>> obtenirToutes({
    bool inclureSupprimees = false,
  }) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final clauseWhere =
        inclureSupprimees ? null : AppDatabase.clauseNonSupprime;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableCategories,
      where: clauseWhere,
      orderBy: 'sort_order ASC',
    );
    return lignes.map(CategorieModele.fromMap).toList();
  }

  Future<CategorieModele?> obtenirParId(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableCategories,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
    if (lignes.isEmpty) return null;
    return CategorieModele.fromMap(lignes.first);
  }

  Future<List<CategorieModele>> obtenirParType(String typeCategorie) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableCategories,
      where: "(type = ? OR type = 'both') AND ${AppDatabase.clauseNonSupprime}",
      whereArgs: [typeCategorie],
      orderBy: 'sort_order ASC',
    );
    return lignes.map(CategorieModele.fromMap).toList();
  }

  Future<void> ajouter(CategorieModele categorie) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableCategories,
      categorie.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(CategorieModele categorie) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableCategories,
      categorie.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [categorie.id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableCategories,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }
}
