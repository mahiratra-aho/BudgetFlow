import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../data/database/app_database.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/repetitif.dart';
import '../../data/models/transaction.dart';
import 'encryption_service.dart';
import 'merge_service.dart';

class BackupPayload {
  final int version;
  final DateTime exportedAt;
  final List<TransactionModele> transactions;
  final List<CategorieModele> categories;
  final List<BudgetModele> budgets;
  final List<ObjectifModele> goals;
  final List<RecurrenceModele> recurring;

  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.transactions,
    required this.categories,
    required this.budgets,
    required this.goals,
    required this.recurring,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exported_at': exportedAt.toIso8601String(),
        'transactions': transactions.map((e) => e.toMap()).toList(),
        'categories': categories.map((e) => e.toMap()).toList(),
        'budgets': budgets.map((e) => e.toMap()).toList(),
        'goals': goals.map((e) => e.toMap()).toList(),
        'recurring': recurring.map((e) => e.toMap()).toList(),
      };

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      version: json['version'] as int? ?? 1,
      exportedAt: json['exported_at'] != null
          ? DateTime.parse(json['exported_at'] as String)
          : DateTime.now(),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => TransactionModele.fromMap(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => CategorieModele.fromMap(e as Map<String, dynamic>))
          .toList(),
      budgets: (json['budgets'] as List<dynamic>? ?? [])
          .map((e) => BudgetModele.fromMap(e as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((e) => ObjectifModele.fromMap(e as Map<String, dynamic>))
          .toList(),
      recurring: (json['recurring'] as List<dynamic>? ?? [])
          .map((e) => RecurrenceModele.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  final _encryption = EncryptionService.instance;
  final _merge = MergeService.instance;

  Future<BackupPayload> lireToutesLesDonnees(AppDatabase db) async {
    final database = await db.database;
    final txRows = await database.query(AppDatabase.tableTransactions);
    final catRows = await database.query(AppDatabase.tableCategories);
    final budgetRows = await database.query(AppDatabase.tableBudgets);
    final goalRows = await database.query(AppDatabase.tableObjectifs);
    final recurringRows = await database.query(AppDatabase.tableRepetitifs);
    return BackupPayload(
      version: 1,
      exportedAt: DateTime.now(),
      transactions: txRows.map(TransactionModele.fromMap).toList(),
      categories: catRows.map(CategorieModele.fromMap).toList(),
      budgets: budgetRows.map(BudgetModele.fromMap).toList(),
      goals: goalRows.map(ObjectifModele.fromMap).toList(),
      recurring: recurringRows.map(RecurrenceModele.fromMap).toList(),
    );
  }

  Future<List<int>> creerSauvegardeChiffree(
      BackupPayload payload, String password) async {
    final plaintext = utf8.encode(jsonEncode(payload.toJson()));
    final envelope = await _encryption.chiffrer(plaintext, password);
    return utf8.encode(jsonEncode(envelope));
  }

  Future<BackupPayload> dechiffrerSauvegarde(
      List<int> fileBytes, String password) async {
    final envelope = jsonDecode(utf8.decode(fileBytes)) as Map<String, dynamic>;
    final plaintext = await _encryption.dechiffrer(envelope, password);
    final payloadJson =
        jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    return BackupPayload.fromJson(payloadJson);
  }

  Future<MergeStats> fusionnerDansBase(
      AppDatabase db, BackupPayload incoming) async {
    final database = await db.database;
    final existingTx = await database
        .query(AppDatabase.tableTransactions)
        .then((rows) => rows.map(TransactionModele.fromMap).toList());
    final existingCat = await database
        .query(AppDatabase.tableCategories)
        .then((rows) => rows.map(CategorieModele.fromMap).toList());
    final existingBudgets = await database
        .query(AppDatabase.tableBudgets)
        .then((rows) => rows.map(BudgetModele.fromMap).toList());
    final existingGoals = await database
        .query(AppDatabase.tableObjectifs)
        .then((rows) => rows.map(ObjectifModele.fromMap).toList());
    final existingRecurring = await database
        .query(AppDatabase.tableRepetitifs)
        .then((rows) => rows.map(RecurrenceModele.fromMap).toList());

    final txToUpsert =
        _merge.mergeTransactions(existingTx, incoming.transactions);
    final catToUpsert =
        _merge.mergeCategories(existingCat, incoming.categories);
    final budgetsToUpsert =
        _merge.mergeBudgets(existingBudgets, incoming.budgets);
    final goalsToUpsert = _merge.mergeGoals(existingGoals, incoming.goals);
    final recurringToUpsert =
        _merge.mergeRecurring(existingRecurring, incoming.recurring);

    await database.transaction((txn) async {
      for (final item in txToUpsert) {
        await txn.insert(AppDatabase.tableTransactions, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in catToUpsert) {
        await txn.insert(AppDatabase.tableCategories, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in budgetsToUpsert) {
        await txn.insert(AppDatabase.tableBudgets, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in goalsToUpsert) {
        await txn.insert(AppDatabase.tableObjectifs, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in recurringToUpsert) {
        await txn.insert(AppDatabase.tableRepetitifs, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    return MergeStats(
      transactions: txToUpsert.length,
      categories: catToUpsert.length,
      budgets: budgetsToUpsert.length,
      goals: goalsToUpsert.length,
      recurring: recurringToUpsert.length,
    );
  }

  String nomFichierSauvegarde() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'budgetflow_backup_$date.bfbackup';
  }
}

class MergeStats {
  final int transactions;
  final int categories;
  final int budgets;
  final int goals;
  final int recurring;

  const MergeStats({
    this.transactions = 0,
    this.categories = 0,
    this.budgets = 0,
    this.goals = 0,
    this.recurring = 0,
  });

  int get total => transactions + categories + budgets + goals + recurring;
}
