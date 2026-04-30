import 'package:sqflite/sqflite.dart';
import '../../../core/constants/constantes_app.dart';
import '../../../core/crypto/service_chiffrement.dart';
import '../../../core/database/service_base_de_donnees.dart';
import 'modeles.dart';

class DepotCategories {
  DepotCategories._();
  static final DepotCategories instance = DepotCategories._();

  final _bdd = ServiceBaseDeDonnees.instance;
  final _crypto = ServiceChiffrement.instance;

  Future<void> initialiserParDefaut() async {
    final db = await _bdd.base;
    final compte = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM ${ConstantesApp.tableCategories}'),
        ) ??
        0;
    if (compte > 0) return;

    final batch = db.batch();
    for (final cat in CategoriesParDefaut.toutes) {
      batch.insert(
        ConstantesApp.tableCategories,
        {
          'id': cat.id,
          'nom_chiffre': _crypto.chiffrer(cat.nom),
          'icone_code': cat.iconeCode,
          'couleur_hex': cat.couleurHex,
          'type': cat.type.valeurBdd,
          'est_defaut': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Categorie>> lireParType(TypeTransaction type) async {
    final db = await _bdd.base;
    final lignes = await db.query(
      ConstantesApp.tableCategories,
      where: 'type = ?',
      whereArgs: [type.valeurBdd],
      orderBy: 'est_defaut DESC, rowid ASC',
    );
    return lignes.map(_depuisMap).toList();
  }

  Future<List<Categorie>> lireTout() async {
    final db = await _bdd.base;
    final lignes = await db.query(ConstantesApp.tableCategories);
    return lignes.map(_depuisMap).toList();
  }

  Future<Categorie?> lireParId(String id) async {
    final db = await _bdd.base;
    final lignes = await db.query(
      ConstantesApp.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return lignes.isEmpty ? null : _depuisMap(lignes.first);
  }

  Future<void> inserer(Categorie cat) async {
    final db = await _bdd.base;
    await db.insert(
      ConstantesApp.tableCategories,
      {
        'id': cat.id,
        'nom_chiffre': _crypto.chiffrer(cat.nom),
        'icone_code': cat.iconeCode,
        'couleur_hex': cat.couleurHex,
        'type': cat.type.valeurBdd,
        'est_defaut': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mettreAJour(Categorie cat) async {
    final db = await _bdd.base;
    await db.update(
      ConstantesApp.tableCategories,
      {
        'nom_chiffre': _crypto.chiffrer(cat.nom),
        'icone_code': cat.iconeCode,
        'couleur_hex': cat.couleurHex,
        'type': cat.type.valeurBdd,
      },
      where: 'id = ?',
      whereArgs: [cat.id],
    );
  }

  Future<void> supprimer(String id) async {
    final db = await _bdd.base;
    await db.delete(
      ConstantesApp.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Categorie _depuisMap(Map<String, dynamic> m) {
    return Categorie(
      id: m['id'] as String,
      nom: _crypto.dechiffrer(m['nom_chiffre'] as String),
      iconeCode: m['icone_code'] as int,
      couleurHex: m['couleur_hex'] as String,
      type: TypeTransaction.depuisBdd(m['type'] as String),
      estDefaut: (m['est_defaut'] as int) == 1,
    );
  }
}
