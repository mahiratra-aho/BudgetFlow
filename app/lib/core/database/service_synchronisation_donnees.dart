import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constantes_app.dart';
import 'service_base_de_donnees.dart';

class ServiceSynchronisationDonnees {
  ServiceSynchronisationDonnees._();
  static final ServiceSynchronisationDonnees instance =
      ServiceSynchronisationDonnees._();

  final _bdd = ServiceBaseDeDonnees.instance;

  String _cleSnapshot(String uid) => '${ConstantesApp.cleSnapshotComptePrefix}$uid';

  Future<Map<String, dynamic>> _exporterDepuisBdd() async {
    final db = await _bdd.base;
    final categories = await db.query(ConstantesApp.tableCategories);
    final transactions = await db.query(ConstantesApp.tableTransactions);
    final images = await db.query(ConstantesApp.tableImages);
    return {
      'categories': categories,
      'transactions': transactions,
      'images': images,
    };
  }

  Future<void> _importerVersBdd(Map<String, dynamic> snapshot) async {
    final db = await _bdd.base;
    await db.transaction((txn) async {
      await txn.delete(ConstantesApp.tableImages);
      await txn.delete(ConstantesApp.tableTransactions);
      await txn.delete(ConstantesApp.tableCategories);

      final categories = (snapshot['categories'] as List<dynamic>? ?? const []);
      final transactions =
          (snapshot['transactions'] as List<dynamic>? ?? const []);
      final images = (snapshot['images'] as List<dynamic>? ?? const []);

      for (final c in categories) {
        await txn.insert(ConstantesApp.tableCategories, Map<String, dynamic>.from(c));
      }
      for (final t in transactions) {
        await txn.insert(
            ConstantesApp.tableTransactions, Map<String, dynamic>.from(t));
      }
      for (final img in images) {
        await txn.insert(ConstantesApp.tableImages, Map<String, dynamic>.from(img));
      }
    });
  }

  Future<void> sauvegarderCompte(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _exporterDepuisBdd();
    await prefs.setString(_cleSnapshot(uid), jsonEncode(snapshot));
  }

  Future<void> connecterCompte(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotExistantTexte = prefs.getString(_cleSnapshot(uid));
    final snapshotExistant = snapshotExistantTexte == null
        ? null
        : jsonDecode(snapshotExistantTexte) as Map<String, dynamic>;

    if (snapshotExistant != null) {
      await _importerVersBdd(snapshotExistant);
    } else {
      final localAvantConnexion = await _exporterDepuisBdd();
      // S'il y avait des données locales avant connexion et que le compte est vide,
      // on les associe au compte connecté.
      final aDuLocal = (localAvantConnexion['transactions'] as List).isNotEmpty ||
          (localAvantConnexion['categories'] as List).isNotEmpty;
      if (aDuLocal) {
        await _importerVersBdd(localAvantConnexion);
        await prefs.setString(_cleSnapshot(uid), jsonEncode(localAvantConnexion));
      } else {
        await viderDonneesLocales();
      }
    }
  }

  Future<void> viderDonneesLocales() async {
    final db = await _bdd.base;
    await db.transaction((txn) async {
      await txn.delete(ConstantesApp.tableImages);
      await txn.delete(ConstantesApp.tableTransactions);
      await txn.delete(ConstantesApp.tableCategories);
    });
  }

}
