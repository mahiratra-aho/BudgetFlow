import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../core/providers/repositories.dart';

typedef StatsState = DonneesStatistiques;

class DonneesStatistiques {
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final List<Map<String, dynamic>> trends; // 6 derniers mois
  final List<CategorieModele> categories;
  final double totalIncome;
  final double totalExpense;
  final int month;
  final int year;

  const DonneesStatistiques({
    this.expenseByCategory = const {},
    this.incomeByCategory = const {},
    this.trends = const [],
    this.categories = const [],
    this.totalIncome = 0,
    this.totalExpense = 0,
    required this.month,
    required this.year,
  });
}

class StatsViewModel extends AsyncNotifier<DonneesStatistiques> {
  @override
  Future<DonneesStatistiques> build() async {
    final now = DateTime.now();
    return _loadData(now.month, now.year);
  }

  Future<DonneesStatistiques> _loadData(int month, int year) async {
    final repoTransactions = ref.read(repoTransactionProvider);
    final repoCategories = ref.read(repoCategorieProvider);

    final results = await Future.wait([
      repoTransactions.sommeParCategorie(TypeTransaction.expense, month, year),
      repoTransactions.sommeParCategorie(TypeTransaction.income, month, year),
      repoTransactions.obtenirTendances(6),
      repoCategories.obtenirToutes(),
      repoTransactions.sommeParTypeEtMois(TypeTransaction.income, month, year),
      repoTransactions.sommeParTypeEtMois(TypeTransaction.expense, month, year),
    ]);

    return DonneesStatistiques(
      expenseByCategory: results[0] as Map<String, double>,
      incomeByCategory: results[1] as Map<String, double>,
      trends: results[2] as List<Map<String, dynamic>>,
      categories: results[3] as List<CategorieModele>,
      totalIncome: results[4] as double,
      totalExpense: results[5] as double,
      month: month,
      year: year,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final now = DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadData(current?.month ?? now.month, current?.year ?? now.year),
    );
  }

  Future<void> changeMonth(int month, int year) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadData(month, year));
  }
}

final statsViewModelProvider =
    AsyncNotifierProvider<StatsViewModel, DonneesStatistiques>(
  StatsViewModel.new,
);
