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
  final double startingBalance;
  final double closingBalance;
  final double? overrideStartingBalance;
  final List<TransactionModele> recentTransactions;
  final List<BudgetModele> budgets;
  final List<ObjectifModele> goals;
  final Map<String, CategorieModele> categories;
  final Map<String, double> spentByCategory;
  final int month;
  final int year;
  final bool isLoading;
  final String? error;

  const EtatTableauDeBord({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.balance = 0,
    this.startingBalance = 0,
    this.closingBalance = 0,
    this.overrideStartingBalance,
    this.recentTransactions = const [],
    this.budgets = const [],
    this.goals = const [],
    this.categories = const {},
    this.spentByCategory = const {},
    required this.month,
    required this.year,
    this.isLoading = false,
    this.error,
  });

  // Solde prévisionnel = solde de clôture du mois courant.
  double get soldePrevisionnaire => closingBalance;

  EtatTableauDeBord copyWith({
    double? totalIncome,
    double? totalExpense,
    double? balance,
    double? startingBalance,
    double? closingBalance,
    double? overrideStartingBalance,
    List<TransactionModele>? recentTransactions,
    List<BudgetModele>? budgets,
    List<ObjectifModele>? goals,
    Map<String, CategorieModele>? categories,
    Map<String, double>? spentByCategory,
    int? month,
    int? year,
    bool? isLoading,
    String? error,
    bool clearOverride = false,
  }) {
    return EtatTableauDeBord(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      startingBalance: startingBalance ?? this.startingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      overrideStartingBalance: clearOverride
          ? null
          : (overrideStartingBalance ?? this.overrideStartingBalance),
      recentTransactions: recentTransactions ?? this.recentTransactions,
      budgets: budgets ?? this.budgets,
      goals: goals ?? this.goals,
      categories: categories ?? this.categories,
      spentByCategory: spentByCategory ?? this.spentByCategory,
      month: month ?? this.month,
      year: year ?? this.year,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardViewModel extends AsyncNotifier<EtatTableauDeBord> {
  @override
  Future<EtatTableauDeBord> build() async {
    final now = DateTime.now();
    return _chargerDonnees(now.month, now.year);
  }

  // Calcule le solde de clôture d'un mois donné (sans récursion infinie :
  // on ne descend que d'un niveau si aucune surcharge n'est définie).
  Future<double> _calculerSoldeInitial(int mois, int annee) async {
    final balanceService = ref.read(balanceCarryServiceProvider);
    final repoTransactions = ref.read(repoTransactionProvider);

    final override = await balanceService.getOverride(mois, annee);
    if (override != null) return override;

    // Récupérer solde de clôture du mois précédent
    final prevDate =
        mois == 1 ? DateTime(annee - 1, 12) : DateTime(annee, mois - 1);
    final prevOverride =
        await balanceService.getOverride(prevDate.month, prevDate.year);

    double prevStarting;
    if (prevOverride != null) {
      prevStarting = prevOverride;
    } else {
      // Pas de surcharge pour le mois précédent non plus : on part de 0
      // (on ne remonte pas indéfiniment)
      prevStarting = 0;
    }

    final results = await Future.wait([
      repoTransactions.sommeParTypeEtMois(
          TypeTransaction.income, prevDate.month, prevDate.year),
      repoTransactions.sommeParTypeEtMois(
          TypeTransaction.expense, prevDate.month, prevDate.year),
    ]);
    final prevIncome = results[0];
    final prevExpense = results[1];
    return prevStarting + prevIncome - prevExpense;
  }

  Future<EtatTableauDeBord> _chargerDonnees(int mois, int annee) async {
    final repoTransactions = ref.read(repoTransactionProvider);
    final repoBudgets = ref.read(repoBudgetProvider);
    final repoObjectifs = ref.read(repoObjectifProvider);
    final repoCategories = ref.read(repoCategorieProvider);
    final balanceService = ref.read(balanceCarryServiceProvider);

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

    final override = await balanceService.getOverride(mois, annee);
    final startingBalance = await _calculerSoldeInitial(mois, annee);
    final closingBalance = startingBalance + totalRevenus - totalDepenses;

    return DashboardState(
      totalIncome: totalRevenus,
      totalExpense: totalDepenses,
      balance: totalRevenus - totalDepenses,
      startingBalance: startingBalance,
      closingBalance: closingBalance,
      overrideStartingBalance: override,
      recentTransactions: transactions.take(5).toList(),
      budgets: budgets,
      goals:
          objectifs.where((objectif) => !objectif.estAtteint).take(3).toList(),
      categories: categoriesParId,
      spentByCategory: depensesParCategorie,
      month: mois,
      year: annee,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final now = DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _chargerDonnees(
        current?.month ?? now.month, current?.year ?? now.year));
  }

  // Enregistre une surcharge manuelle du solde initial pour le mois affiché.
  Future<void> setStartingBalanceOverride(double value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final balanceService = ref.read(balanceCarryServiceProvider);
    await balanceService.setOverride(current.month, current.year, value);
    await refresh();
  }

  // Supprime la surcharge manuelle du solde initial pour le mois affiché.
  Future<void> removeStartingBalanceOverride() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final balanceService = ref.read(balanceCarryServiceProvider);
    await balanceService.removeOverride(current.month, current.year);
    await refresh();
  }
}

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, EtatTableauDeBord>(
  DashboardViewModel.new,
);
