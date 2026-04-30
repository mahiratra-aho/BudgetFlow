import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../constants/constantes_app.dart';

class ServiceBaseDeDonnees {
  ServiceBaseDeDonnees._();
  static final ServiceBaseDeDonnees instance = ServiceBaseDeDonnees._();

  sqflite.Database? _base;

  Future<sqflite.Database> get base async {
    _base ??= await _ouvrir();
    return _base!;
  }

  Future<sqflite.Database> _ouvrir() async {
    final cheminDossier = await sqflite.getDatabasesPath();
    final chemin = join(cheminDossier, ConstantesApp.nomBdd);

    return sqflite.openDatabase(
      chemin,
      version: ConstantesApp.versionBdd,
      onCreate: _creerTables,
      onUpgrade: _migrer,
    );
  }

  Future<void> _creerTables(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${ConstantesApp.tableCategories} (
        id          TEXT PRIMARY KEY,
        nom_chiffre TEXT NOT NULL,
        icone_code  INTEGER NOT NULL,
        couleur_hex TEXT NOT NULL,
        type        TEXT NOT NULL,
        est_defaut  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${ConstantesApp.tableTransactions} (
        id               TEXT PRIMARY KEY,
        titre_chiffre    TEXT NOT NULL,
        montant_chiffre  TEXT NOT NULL,
        type             TEXT NOT NULL,
        categorie_id     TEXT NOT NULL,
        date_iso         TEXT NOT NULL,
        note_chiffree    TEXT,
        membres_json_chiffre TEXT,
        moyen_paiement_id_chiffre TEXT,
        FOREIGN KEY (categorie_id) REFERENCES ${ConstantesApp.tableCategories}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${ConstantesApp.tableImages} (
        id               TEXT PRIMARY KEY,
        transaction_id   TEXT NOT NULL,
        chemin_chiffre   TEXT NOT NULL,
        ordre            INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES ${ConstantesApp.tableTransactions}(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date
        ON ${ConstantesApp.tableTransactions}(date_iso)
    ''');
  }

  Future<void> _migrer(
      sqflite.Database db, int ancienneVersion, int nouvelleVersion) async {
    if (ancienneVersion < 2) {
      await db.execute('''
        ALTER TABLE ${ConstantesApp.tableTransactions}
        ADD COLUMN membres_json_chiffre TEXT
      ''');
    }
    if (ancienneVersion < 3) {
      await db.execute('''
        ALTER TABLE ${ConstantesApp.tableTransactions}
        ADD COLUMN moyen_paiement_id_chiffre TEXT
      ''');
    }
  }

  Future<void> fermer() async {
    await _base?.close();
    _base = null;
  }
}
