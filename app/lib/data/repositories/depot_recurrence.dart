import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/repetitif.dart';

class DepotRecurrence {
  final AppDatabase _baseDeDonnees;

  DepotRecurrence(this._baseDeDonnees);

  Future<List<RecurrenceModele>> obtenirToutes({
    bool activesSeulement = true,
  }) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final clauseWhere = activesSeulement
        ? '${AppDatabase.clauseNonSupprime} AND is_active = 1'
        : AppDatabase.clauseNonSupprime;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableRepetitifs,
      where: clauseWhere,
      orderBy: 'next_date ASC',
    );
    return lignes.map(RecurrenceModele.fromMap).toList();
  }

  Future<RecurrenceModele?> obtenirParId(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final lignes = await baseDeDonnees.query(
      AppDatabase.tableRepetitifs,
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
    if (lignes.isEmpty) return null;
    return RecurrenceModele.fromMap(lignes.first);
  }

  Future<void> ajouter(RecurrenceModele recurrence) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.insert(
      AppDatabase.tableRepetitifs,
      recurrence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(RecurrenceModele recurrence) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableRepetitifs,
      recurrence.toMap(),
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [recurrence.id],
    );
  }

  Future<void> mettreAJourProchaineDate(
    String id,
    DateTime prochaineDate,
  ) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    await baseDeDonnees.update(
      AppDatabase.tableRepetitifs,
      {
        'next_date': prochaineDate.millisecondsSinceEpoch,
        AppDatabase.colonneMisAJourLe: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> supprimerLogiquement(String id) async {
    final baseDeDonnees = await _baseDeDonnees.database;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    await baseDeDonnees.update(
      AppDatabase.tableRepetitifs,
      {
        AppDatabase.colonneSupprimeLe: maintenant,
        AppDatabase.colonneMisAJourLe: maintenant,
      },
      where: '${AppDatabase.colonneId} = ?',
      whereArgs: [id],
    );
  }
}
