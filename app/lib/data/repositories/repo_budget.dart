import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/budget.dart';

class RepoBudget {
  final AppDatabase _baseDeDonnees;

  RepoBudget(this._baseDeDonnees);

  Future<List<BudgetModele>> obtenirParMois(int mois, int annee) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableBudgets,
      where: 'month = ? AND year = ? AND ${AppDatabase.clauseNonSupprime}',
      whereArgs: [mois, annee],
    );
    return lignes.map(BudgetModele.fromMap).toList();
  }

  Future<BudgetModele?> obtenirParCategorieEtMois(
    String idCategorie,
    int mois,
    int annee,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableBudgets,
      where:
          'category_id = ? AND month = ? AND year = ? AND ${AppDatabase.clauseNonSupprime}',
      whereArgs: [idCategorie, mois, annee],
      limit: 1,
    );
    if (lignes.isEmpty) return null;
    return BudgetModele.fromMap(lignes.first);
  }

  Future<void> ajouter(BudgetModele budget) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableBudgets,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(BudgetModele budget) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableBudgets,
      budget.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableBudgets,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }
}
