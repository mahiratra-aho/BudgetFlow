import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BudgetLocal {
  final String id;
  final String categorieId;
  final String categorieNom;
  final double montantTotal;
  final double montantDepense;

  const BudgetLocal({
    required this.id,
    required this.categorieId,
    required this.categorieNom,
    required this.montantTotal,
    this.montantDepense = 0,
  });

  BudgetLocal copyWith({
    String? categorieId,
    String? categorieNom,
    double? montantTotal,
    double? montantDepense,
  }) {
    return BudgetLocal(
      id: id,
      categorieId: categorieId ?? this.categorieId,
      categorieNom: categorieNom ?? this.categorieNom,
      montantTotal: montantTotal ?? this.montantTotal,
      montantDepense: montantDepense ?? this.montantDepense,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'categorieId': categorieId,
        'categorieNom': categorieNom,
        'montantTotal': montantTotal,
        'montantDepense': montantDepense,
      };

  static BudgetLocal fromMap(Map<String, dynamic> map) => BudgetLocal(
        id: map['id'] as String,
        categorieId: map['categorieId'] as String? ?? '',
        categorieNom: map['categorieNom'] as String? ?? (map['nom'] as String? ?? 'Budget'),
        montantTotal: (map['montantTotal'] as num).toDouble(),
        montantDepense: (map['montantDepense'] as num?)?.toDouble() ?? 0.0,
      );
}

class DepotBudgets {
  DepotBudgets._();
  static final DepotBudgets instance = DepotBudgets._();
  static const _cle = 'budgets_locaux';
  final _uuid = const Uuid();

  Future<List<BudgetLocal>> lireTous() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cle);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => BudgetLocal.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<BudgetLocal> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, jsonEncode(budgets.map((e) => e.toMap()).toList()));
  }

  Future<void> ajouter({
    required String categorieId,
    required String categorieNom,
    required double montantTotal,
  }) async {
    final budgets = await lireTous();
    budgets.add(
      BudgetLocal(
        id: _uuid.v4(),
        categorieId: categorieId,
        categorieNom: categorieNom,
        montantTotal: montantTotal,
      ),
    );
    await _save(budgets);
  }

  Future<void> mettreAJour(BudgetLocal budget) async {
    final budgets = await lireTous();
    final maj = budgets.map((b) => b.id == budget.id ? budget : b).toList();
    await _save(maj);
  }

  Future<void> supprimer(String id) async {
    final budgets = await lireTous();
    await _save(budgets.where((b) => b.id != id).toList());
  }

  Future<BudgetLocal?> lireParCategorie(String categorieId) async {
    final budgets = await lireTous();
    for (final b in budgets) {
      if (b.categorieId == categorieId) return b;
    }
    return null;
  }

  Future<void> ajouterDepense({
    required String categorieId,
    required double montant,
  }) async {
    final budget = await lireParCategorie(categorieId);
    if (budget == null) return;
    await mettreAJour(
      budget.copyWith(montantDepense: budget.montantDepense + montant),
    );
  }

  Future<void> retirerDepense({
    required String categorieId,
    required double montant,
  }) async {
    final budget = await lireParCategorie(categorieId);
    if (budget == null) return;
    final valeur = budget.montantDepense - montant;
    await mettreAJour(
      budget.copyWith(montantDepense: valeur < 0 ? 0 : valeur),
    );
  }
}
