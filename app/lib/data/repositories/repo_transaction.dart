import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../models/transaction_attachment.dart';

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

  // ── Membres ────────────────────────────────────────────────────────────────

  /// Ajoute un membre à une transaction (lien dans la table de jointure).
  Future<void> ajouterMembre(String transactionId, String membreId) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableMembresTransaction,
      {'transaction_id': transactionId, 'member_id': membreId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Supprime un membre d'une transaction.
  Future<void> supprimerMembre(String transactionId, String membreId) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.delete(
      AppDatabase.tableMembresTransaction,
      where: 'transaction_id = ? AND member_id = ?',
      whereArgs: [transactionId, membreId],
    );
  }

  /// Remplace tous les membres d'une transaction par [membreIds].
  Future<void> definirMembres(
    String transactionId,
    List<String> membreIds,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.delete(
      AppDatabase.tableMembresTransaction,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    final batch = baseDeDonnees.batch();
    for (final membreId in membreIds) {
      batch.insert(
        AppDatabase.tableMembresTransaction,
        {'transaction_id': transactionId, 'member_id': membreId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Retourne les membres associés à une transaction.
  Future<List<MembreModele>> obtenirMembres(String transactionId) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.rawQuery(
      '''SELECT m.*
         FROM ${AppDatabase.tableMembres} m
         JOIN ${AppDatabase.tableMembresTransaction} tm
           ON m.id = tm.member_id
         WHERE tm.transaction_id = ?
           AND m.${AppDatabase.colonneSupprimeLe} IS NULL''',
      [transactionId],
    );
    return lignes.map(MembreModele.fromMap).toList();
  }

  // ── Pièces jointes ─────────────────────────────────────────────────────────

  /// Enregistre une pièce jointe liée à une transaction.
  Future<void> ajouterPieceJointe(PieceJointeModele pieceJointe) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tablePiecesJointes,
      pieceJointe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Supprime une pièce jointe par son identifiant.
  Future<void> supprimerPieceJointe(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.delete(
      AppDatabase.tablePiecesJointes,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }

  /// Retourne les pièces jointes d'une transaction.
  Future<List<PieceJointeModele>> obtenirPiecesJointes(
    String transactionId,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tablePiecesJointes,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'created_at ASC',
    );
    return lignes.map(PieceJointeModele.fromMap).toList();
  }
}
