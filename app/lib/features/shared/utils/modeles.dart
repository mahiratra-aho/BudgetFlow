import 'package:flutter/material.dart';

// ─── Devise fixe ─────────────────────────────────────────────────────────────

class Devise {
  static const String symbole = 'Ar';
  static const String nom = 'Ariary';

  static String formater(double montant) {
    final entier = montant.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    int compteur = 0;
    for (int i = entier.length - 1; i >= 0; i--) {
      if (compteur > 0 && compteur % 3 == 0) buffer.write('\u202F');
      buffer.write(entier[i]);
      compteur++;
    }
    final formate = buffer.toString().split('').reversed.join();
    return '${montant < 0 ? '-' : ''}$formate ${Devise.symbole}';
  }
}

// ─── Type de transaction ─────────────────────────────────────────────────────

enum TypeTransaction {
  depense,
  revenu;

  String get libelle => this == depense ? 'Dépense' : 'Revenu';
  String get valeurBdd => name;

  static TypeTransaction depuisBdd(String valeur) =>
      TypeTransaction.values.firstWhere((e) => e.name == valeur);
}

// ─── Catégorie ────────────────────────────────────────────────────────────────

class Categorie {
  final String id;
  final String nom;
  final int iconeCode;
  final String couleurHex;
  final TypeTransaction type;
  final bool estDefaut;

  const Categorie({
    required this.id,
    required this.nom,
    required this.iconeCode,
    required this.couleurHex,
    required this.type,
    this.estDefaut = false,
  });

  Color get couleur => Color(int.parse('FF$couleurHex', radix: 16));
  IconData get icone => IconData(iconeCode, fontFamily: 'MaterialIcons');

  Categorie copyWith({
    String? nom,
    int? iconeCode,
    String? couleurHex,
    TypeTransaction? type,
    bool? estDefaut,
  }) {
    return Categorie(
      id: id,
      nom: nom ?? this.nom,
      iconeCode: iconeCode ?? this.iconeCode,
      couleurHex: couleurHex ?? this.couleurHex,
      type: type ?? this.type,
      estDefaut: estDefaut ?? this.estDefaut,
    );
  }
}

// ─── Catégories par défaut ────────────────────────────────────────────────────

class CategoriesParDefaut {
  static const List<Categorie> depenses = [
    Categorie(id: 'dep_alimentation', nom: 'Alimentation', iconeCode: 0xe56c, couleurHex: 'FF7043', type: TypeTransaction.depense, estDefaut: true),
    Categorie(id: 'dep_transport',    nom: 'Transport',    iconeCode: 0xe531, couleurHex: '42A5F5', type: TypeTransaction.depense, estDefaut: true),
    Categorie(id: 'dep_loisirs',      nom: 'Loisirs',      iconeCode: 0xe40a, couleurHex: 'AB47BC', type: TypeTransaction.depense, estDefaut: true),
    Categorie(id: 'dep_sante',        nom: 'Santé',        iconeCode: 0xe87e, couleurHex: 'EF5350', type: TypeTransaction.depense, estDefaut: true),
    Categorie(id: 'dep_logement',     nom: 'Logement',     iconeCode: 0xe318, couleurHex: '26A69A', type: TypeTransaction.depense, estDefaut: true),
    Categorie(id: 'dep_shopping',     nom: 'Shopping',     iconeCode: 0xe7c9, couleurHex: 'FEBC2A', type: TypeTransaction.depense, estDefaut: true),
  ];

  static const List<Categorie> revenus = [
    Categorie(id: 'rev_salaire',       nom: 'Salaire',       iconeCode: 0xe943, couleurHex: '8AA232', type: TypeTransaction.revenu, estDefaut: true),
    Categorie(id: 'rev_temps_partiel', nom: 'Temps partiel', iconeCode: 0xe614, couleurHex: '66BB6A', type: TypeTransaction.revenu, estDefaut: true),
  ];

  static List<Categorie> get toutes => [...depenses, ...revenus];
}

// ─── Transaction ─────────────────────────────────────────────────────────────

class Transaction {
  final String id;
  final String titre;
  final double montant;
  final TypeTransaction type;
  final Categorie categorie;
  final DateTime date;
  final String? note;
  final List<String> cheminImages;
  final List<String> membreIds;
  final String? moyenPaiementId;

  const Transaction({
    required this.id,
    required this.titre,
    required this.montant,
    required this.type,
    required this.categorie,
    required this.date,
    this.note,
    this.cheminImages = const [],
    this.membreIds = const [],
    this.moyenPaiementId,
  });

  Transaction copyWith({
    String? titre,
    double? montant,
    TypeTransaction? type,
    Categorie? categorie,
    DateTime? date,
    String? note,
    List<String>? cheminImages,
    List<String>? membreIds,
    String? moyenPaiementId,
  }) {
    return Transaction(
      id: id,
      titre: titre ?? this.titre,
      montant: montant ?? this.montant,
      type: type ?? this.type,
      categorie: categorie ?? this.categorie,
      date: date ?? this.date,
      note: note ?? this.note,
      cheminImages: cheminImages ?? this.cheminImages,
      membreIds: membreIds ?? this.membreIds,
      moyenPaiementId: moyenPaiementId ?? this.moyenPaiementId,
    );
  }
}

// ─── Utilisateur local ────────────────────────────────────────────────────────

class UtilisateurLocal {
  final String? uid;
  final String nomAffiche;

  const UtilisateurLocal({this.uid, this.nomAffiche = 'Utilisateur'});

  bool get estConnecte => uid != null;

  static const UtilisateurLocal anonyme = UtilisateurLocal();
}
