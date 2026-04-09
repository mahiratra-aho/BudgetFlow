// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Base de données SQLite locale pour BudgetFlow.
///
/// Stockage:
/// - Android/iOS : fichier SQLite natif
/// - Desktop     : SQLite via `sqflite_common_ffi`
/// - Web         : SQLite via `sqflite_common_ffi_web` sans worker dédié
///                 (stockage navigateur/IndexedDB)
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Sur le Web, éviter la dépendance au worker partagé tout en gardant SQLite.
      return _openWithFactory(
        databaseFactoryFfiWebNoWebWorker,
        'budgetflow_web.db',
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'budgetflow.db');

    try {
      final isDesktop = defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (isDesktop) {
        sqfliteFfiInit();
        return _openWithFactory(databaseFactoryFfi, dbPath);
      }
    } catch (_) {
      // Sur Android/iOS, sqflite natif est utilisé ci-dessous.
    }

    final db = await openDatabase(
      dbPath,
      version: _kVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _ensureDatabaseReady(db);
    return db;
  }

  Future<Database> _openWithFactory(
    DatabaseFactory factory,
    String path,
  ) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _kVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    await _ensureDatabaseReady(db);
    return db;
  }

  Future<void> _ensureDatabaseReady(Database db) async {
    await _createTables(db);

    final result =
        await db.rawQuery('SELECT COUNT(*) AS count FROM categories');
    final count = Sqflite.firstIntValue(result) ?? 0;
    if (count == 0) {
      await _seedDefaultCategories(db);
    }
  }

  static const int _kVersion = 1;

  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableBudgets = 'budgets';
  static const String tableObjectifs = 'goals';
  static const String tableRepetitifs = 'recurring';
  static const String tableRecurrences = tableRepetitifs;

  static const String colonneId = 'id';
  static const String colonneMisAJourLe = 'updated_at';
  static const String colonneSupprimeLe = 'deleted_at';
  static const String colonneEstRepetitif = 'is_recurring';
  static const String colonneIdRepetition = 'recurring_id';
  static const String clauseNonSupprime = '$colonneSupprimeLe IS NULL';

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Futures migrations ici
  }

  Future<void> _createTables(Database db) async {
    // Table catégories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        icon        TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        type        TEXT NOT NULL DEFAULT 'both',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        updated_at  INTEGER NOT NULL,
        deleted_at  INTEGER,
        version     INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Table transactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id                      TEXT PRIMARY KEY,
        title                   TEXT NOT NULL,
        amount                  REAL NOT NULL,
        type                    TEXT NOT NULL,
        category_id             TEXT NOT NULL,
        note                    TEXT,
        date                    INTEGER NOT NULL,
        $colonneEstRepetitif    INTEGER NOT NULL DEFAULT 0,
        $colonneIdRepetition    TEXT,
        updated_at              INTEGER NOT NULL,
        deleted_at              INTEGER,
        version                 INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Table budgets
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id          TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount      REAL NOT NULL,
        month       INTEGER NOT NULL,
        year        INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        deleted_at  INTEGER,
        version     INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Table objectifs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id             TEXT PRIMARY KEY,
        name           TEXT NOT NULL,
        target_amount  REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        icon           TEXT NOT NULL,
        color_value    INTEGER NOT NULL,
        deadline       INTEGER,
        updated_at     INTEGER NOT NULL,
        deleted_at     INTEGER,
        version        INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Table répétitifs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRepetitifs (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        amount      REAL NOT NULL,
        type        TEXT NOT NULL,
        category_id TEXT NOT NULL,
        frequency   TEXT NOT NULL,
        interval    INTEGER NOT NULL DEFAULT 1,
        start_date  INTEGER NOT NULL,
        end_date    INTEGER,
        next_date   INTEGER NOT NULL,
        note        TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1,
        updated_at  INTEGER NOT NULL,
        deleted_at  INTEGER,
        version     INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Index
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions (date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions (category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_month ON budgets (year, month)',
    );
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final categories = [
      // Dépenses
      _cat('cat_food', 'Alimentation', 'restaurant', 0xFFFF69B4, 'expense', 0,
          now),
      _cat('cat_transport', 'Transport', 'directions_car', 0xFF87CEFA,
          'expense', 1, now),
      _cat('cat_shopping', 'Shopping', 'shopping_bag', 0xFFDDA0DD, 'expense', 2,
          now),
      _cat('cat_health', 'Santé', 'favorite', 0xFFFF8A80, 'expense', 3, now),
      _cat('cat_leisure', 'Loisirs', 'sports_esports', 0xFFB39DDB, 'expense', 4,
          now),
      _cat('cat_home', 'Logement', 'home', 0xFF80CBC4, 'expense', 5, now),
      _cat('cat_education', 'Éducation', 'school', 0xFFFFCC80, 'expense', 6,
          now),
      _cat('cat_subscriptions', 'Abonnements', 'subscriptions', 0xFFA5D6A7,
          'expense', 7, now),
      // Revenus
      _cat('cat_salary', 'Salaire', 'work', 0xFF4CAF82, 'income', 8, now),
      _cat(
          'cat_freelance', 'Freelance', 'laptop', 0xFF81C784, 'income', 9, now),
      _cat('cat_investment', 'Investissements', 'trending_up', 0xFF64B5F6,
          'income', 10, now),
      // Les deux
      _cat('cat_other', 'Autres', 'more_horiz', 0xFF90A4AE, 'both', 11, now),
    ];

    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Map<String, dynamic> _cat(
    String id,
    String name,
    String icon,
    int colorValue,
    String type,
    int sortOrder,
    int now,
  ) {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color_value': colorValue,
      'type': type,
      'sort_order': sortOrder,
      'updated_at': now,
      'version': 1,
    };
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
