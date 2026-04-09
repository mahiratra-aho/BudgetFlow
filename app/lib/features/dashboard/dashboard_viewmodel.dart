import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/budget.dart';
import '../../data/models/goal.dart';
import '../../data/models/category.dart';
import '../../core/providers/repositories.dart';

typedef DashboardState = EtatTableauDeBord;

class EtatTableauDeBord {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<TransactionModele> recentTransactions;
  final List<BudgetModele> budgets;
  final List<ObjectifModele> goals;
  final Map<String, CategorieModele> categories;
  final Map<String, double> spentByCategory;
  final bool isLoading;
  final String? error;

  const EtatTableauDeBord({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.balance = 0,
    this.recentTransactions = const [],
    this.budgets = const [],
    this.goals = const [],
    this.categories = const {},
    this.spentByCategory = const {},
    this.isLoading = false,
    this.error,
  });

  EtatTableauDeBord copyWith({
    double? totalIncome,
    double? totalExpense,
    double? balance,
    List<TransactionModele>? recentTransactions,
    List<BudgetModele>? budgets,
    List<ObjectifModele>? goals,
    Map<String, CategorieModele>? categories,
    Map<String, double>? spentByCategory,
    bool? isLoading,
    String? error,
  }) {
    return EtatTableauDeBord(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      budgets: budgets ?? this.budgets,
      goals: goals ?? this.goals,
      categories: categories ?? this.categories,
      spentByCategory: spentByCategory ?? this.spentByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardViewModel extends AsyncNotifier<EtatTableauDeBord> {
  @override
  Future<EtatTableauDeBord> build() async {
    return _chargerDonnees();
  }

  Future<EtatTableauDeBord> _chargerDonnees() async {
    final dateCourante = DateTime.now();
    final mois = dateCourante.month;
    final annee = dateCourante.year;

    final repoTransactions = ref.read(repoTransactionProvider);
    final repoBudgets = ref.read(repoBudgetProvider);
    final repoObjectifs = ref.read(repoObjectifProvider);
    final repoCategories = ref.read(repoCategorieProvider);

    final resultats = await Future.wait([
      repoTransactions.obtenirParMois(mois, annee),
      repoTransactions.sommeParTypeEtMois(TypeTransaction.income, mois, annee),
      repoTransactions.sommeParTypeEtMois(TypeTransaction.expense, mois, annee),
      repoTransactions.sommeParCategorie(TypeTransaction.expense, mois, annee),
      repoBudgets.obtenirParMois(mois, annee),
      repoObjectifs.obtenirTous(),
      repoCategories.obtenirToutes(),
    ]);

    final transactions = resultats[0] as List<TransactionModele>;
    final totalRevenus = resultats[1] as double;
    final totalDepenses = resultats[2] as double;
    final depensesParCategorie = resultats[3] as Map<String, double>;
    final budgets = resultats[4] as List<BudgetModele>;
    final objectifs = resultats[5] as List<ObjectifModele>;
    final categories = resultats[6] as List<CategorieModele>;
    final categoriesParId = {
      for (final categorie in categories) categorie.id: categorie,
    };

    return DashboardState(
      totalIncome: totalRevenus,
      totalExpense: totalDepenses,
      balance: totalRevenus - totalDepenses,
      recentTransactions: transactions.take(5).toList(),
      budgets: budgets,
      goals:
          objectifs.where((objectif) => !objectif.estAtteint).take(3).toList(),
      categories: categoriesParId,
      spentByCategory: depensesParCategorie,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _chargerDonnees());
  }
}

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, EtatTableauDeBord>(
  DashboardViewModel.new,
);
