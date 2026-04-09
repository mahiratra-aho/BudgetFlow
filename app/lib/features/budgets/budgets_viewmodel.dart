import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../core/providers/repositories.dart';

typedef BudgetWithSpent = BudgetAvecDepenses;

class BudgetAvecDepenses {
  final BudgetModele budget;
  final double spent;
  final CategorieModele? category;

  const BudgetAvecDepenses({
    required this.budget,
    required this.spent,
    this.category,
  });

  double get reste => (budget.amount - spent).clamp(0, double.infinity);

  /// Borne la progression entre 0 et 1 pour garder les indicateurs stables.
  double get progression =>
      budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

  bool get depasseBudget => spent > budget.amount;
}

typedef BudgetsState = EtatBudgets;

class EtatBudgets {
  final List<BudgetAvecDepenses> items;
  final List<CategorieModele> categories;
  final int month;
  final int year;
  final bool isLoading;
  final String? error;

  const EtatBudgets({
    this.items = const [],
    this.categories = const [],
    required this.month,
    required this.year,
    this.isLoading = false,
    this.error,
  });

  double get totalBudget => items.fold(0, (sum, b) => sum + b.budget.amount);
  double get totalSpent => items.fold(0, (sum, b) => sum + b.spent);
}

class BudgetsViewModel extends AsyncNotifier<EtatBudgets> {
  @override
  Future<EtatBudgets> build() async {
    final dateCourante = DateTime.now();
    return _chargerDonnees(dateCourante.month, dateCourante.year);
  }

  Future<EtatBudgets> _chargerDonnees(int mois, int annee) async {
    final repoBudgets = ref.read(repoBudgetProvider);
    final repoCategories = ref.read(repoCategorieProvider);
    final repoTransactions = ref.read(repoTransactionProvider);

    final resultats = await Future.wait([
      repoBudgets.obtenirParMois(mois, annee),
      repoCategories.obtenirToutes(),
      repoTransactions.sommeParCategorie(TypeTransaction.expense, mois, annee),
    ]);

    final budgets = resultats[0] as List<BudgetModele>;
    final categories = resultats[1] as List<CategorieModele>;
    final depensesParCategorie = resultats[2] as Map<String, double>;
    final categoriesParId = {
      for (final categorie in categories) categorie.id: categorie
    };

    final elementsBudget = budgets.map((budget) {
      return BudgetAvecDepenses(
        budget: budget,
        spent: depensesParCategorie[budget.categoryId] ?? 0,
        category: categoriesParId[budget.categoryId],
      );
    }).toList();

    return EtatBudgets(
      items: elementsBudget,
      categories: categories,
      month: mois,
      year: annee,
    );
  }

  Future<void> refresh() async {
    final etatCourant = state.valueOrNull;
    final dateCourante = DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _chargerDonnees(
        etatCourant?.month ?? dateCourante.month,
        etatCourant?.year ?? dateCourante.year,
      ),
    );
  }

  Future<void> changeMonth(int month, int year) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _chargerDonnees(month, year));
  }

  Future<void> addOrUpdateBudget(BudgetModele budget) async {
    final repoBudgets = ref.read(repoBudgetProvider);
    final budgetExistant = await repoBudgets.obtenirParCategorieEtMois(
      budget.categoryId,
      budget.month,
      budget.year,
    );
    if (budgetExistant != null) {
      await repoBudgets.mettreAJour(
        budgetExistant.copyWith(amount: budget.amount),
      );
    } else {
      await repoBudgets.ajouter(budget);
    }
    await refresh();
  }

  Future<void> deleteBudget(String id) async {
    final repoBudgets = ref.read(repoBudgetProvider);
    await repoBudgets.supprimerLogiquement(id);
    await refresh();
  }
}

final budgetsViewModelProvider =
    AsyncNotifierProvider<BudgetsViewModel, EtatBudgets>(
  BudgetsViewModel.new,
);
