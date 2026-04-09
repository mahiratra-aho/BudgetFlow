import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/transaction.dart';

class RepoTransaction {
  final AppDatabase _baseDeDonnees;

  RepoTransaction(this._baseDeDonnees);

  Future<List<TransactionModele>> obtenirTous({
    bool inclureSupprimes = false,
  }) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final clauseWhere = inclureSupprimes ? null : AppDatabase.clauseNonSupprime;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableTransactions,
      where: clauseWhere,
      orderBy: 'date DESC',
    );
    return lignes.map(TransactionModele.fromMap).toList();
  }

  Future<List<TransactionModele>> obtenirParMois(int mois, int annee) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final debut = DateTime(annee, mois).millisecondsSinceEpoch;
    final fin = DateTime(annee, mois + 1).millisecondsSinceEpoch;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableTransactions,
      where: 'date >= ? AND date < ? AND ${AppDatabase.clauseNonSupprime}',
      whereArgs: [debut, fin],
      orderBy: 'date DESC',
    );
    return lignes.map(TransactionModele.fromMap).toList();
  }

  Future<List<TransactionModele>> obtenirParCategorie(
    String idCategorie,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableTransactions,
      where: 'category_id = ? AND ${AppDatabase.clauseNonSupprime}',
      whereArgs: [idCategorie],
      orderBy: 'date DESC',
    );
    return lignes.map(TransactionModele.fromMap).toList();
  }

  Future<double> sommeParTypeEtMois(
    TypeTransaction type,
    int mois,
    int annee,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final typeTexte = type == TypeTransaction.income ? 'income' : 'expense';
    final debut = DateTime(annee, mois).millisecondsSinceEpoch;
    final fin = DateTime(annee, mois + 1).millisecondsSinceEpoch;
    final resultat = await baseDeDonnees.rawQuery(
      '''SELECT COALESCE(SUM(amount), 0) AS total_montant
         FROM ${AppDatabase.tableTransactions}
         WHERE type = ? AND date >= ? AND date < ? AND ${AppDatabase.clauseNonSupprime}''',
      [typeTexte, debut, fin],
    );
    return (resultat.first['total_montant'] as num? ?? 0).toDouble();
  }

  Future<Map<String, double>> sommeParCategorie(
    TypeTransaction type,
    int mois,
    int annee,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final typeTexte = type == TypeTransaction.income ? 'income' : 'expense';
    final debut = DateTime(annee, mois).millisecondsSinceEpoch;
    final fin = DateTime(annee, mois + 1).millisecondsSinceEpoch;
    final resultat = await baseDeDonnees.rawQuery(
      '''SELECT category_id AS categorie_id, SUM(amount) AS total_montant
         FROM ${AppDatabase.tableTransactions}
         WHERE type = ? AND date >= ? AND date < ? AND ${AppDatabase.clauseNonSupprime}
         GROUP BY category_id''',
      [typeTexte, debut, fin],
    );
    return {
      for (final ligne in resultat)
        ligne['categorie_id'] as String:
            (ligne['total_montant'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> obtenirTendances(int nombreDeMois) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now();
    final resultats = <Map<String, dynamic>>[];

    for (int index = nombreDeMois - 1; index >= 0; index--) {
      final dateCourante = DateTime(maintenant.year, maintenant.month - index);
      final debut = DateTime(dateCourante.year, dateCourante.month)
          .millisecondsSinceEpoch;
      final fin = DateTime(
        dateCourante.year,
        dateCourante.month + 1,
      ).millisecondsSinceEpoch;

      final lignes = await baseDeDonnees.rawQuery(
        '''SELECT
             COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS revenus,
             COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS depenses
           FROM ${AppDatabase.tableTransactions}
           WHERE date >= ? AND date < ? AND ${AppDatabase.clauseNonSupprime}''',
        [debut, fin],
      );

      resultats.add({
        'month': dateCourante.month,
        'year': dateCourante.year,
        'income': (lignes.first['revenus'] as num).toDouble(),
        'expense': (lignes.first['depenses'] as num).toDouble(),
      });
    }

    return resultats;
  }

  Future<void> ajouter(TransactionModele transaction) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(TransactionModele transaction) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableTransactions,
      transaction.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableTransactions,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }
}
