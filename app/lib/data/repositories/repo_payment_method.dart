import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/payment_method.dart';

class RepoMoyenPaiement {
  final AppDatabase _baseDeDonnees;

  RepoMoyenPaiement(this._baseDeDonnees);

  Future<List<MoyenPaiementModele>> obtenirTous({
    bool inclureSupprimees = false,
  }) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final clauseWhere =
        inclureSupprimees ? null : AppDatabase.clauseNonSupprime;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableMoyensPaiement,
      where: clauseWhere,
      orderBy: 'sort_order ASC',
    );
    return lignes.map(MoyenPaiementModele.fromMap).toList();
  }

  Future<MoyenPaiementModele?> obtenirParId(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableMoyensPaiement,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
    if (lignes.isEmpty) return null;
    return MoyenPaiementModele.fromMap(lignes.first);
  }

  Future<void> ajouter(MoyenPaiementModele moyen) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableMoyensPaiement,
      moyen.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(MoyenPaiementModele moyen) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableMoyensPaiement,
      moyen.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [moyen.id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableMoyensPaiement,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }

  /// Réordonne la liste des moyens de paiement.
  ///
  /// [ordreIds] est la liste des identifiants dans le nouvel ordre souhaité.
  Future<void> reordonner(List<String> ordreIds) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    final batch = baseDeDonnees.batch();
    for (int i = 0; i < ordreIds.length; i++) {
      batch.update(
        AppDatabase.tableMoyensPaiement,
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
