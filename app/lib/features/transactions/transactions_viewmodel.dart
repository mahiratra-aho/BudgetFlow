import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../core/providers/repositories.dart';

typedef TransactionsState = EtatTransactions;

class EtatTransactions {
  final List<TransactionModele> transactions;
  final List<CategorieModele> categories;
  final String? filterCategoryId;
  final TypeTransaction? filterType;
  final int filterMonth;
  final int filterYear;
  final bool isLoading;
  final String? error;

  const EtatTransactions({
    this.transactions = const [],
    this.categories = const [],
    this.filterCategoryId,
    this.filterType,
    required this.filterMonth,
    required this.filterYear,
    this.isLoading = false,
    this.error,
  });

  List<TransactionModele> get transactionsFiltrees {
    return transactions.where((transaction) {
      if (filterType != null && transaction.type != filterType) return false;
      if (filterCategoryId != null &&
          transaction.categoryId != filterCategoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  EtatTransactions copyWith({
    List<TransactionModele>? transactions,
    List<CategorieModele>? categories,
    String? filterCategoryId,
    TypeTransaction? filterType,
    int? filterMonth,
    int? filterYear,
    bool? isLoading,
    String? error,
    bool clearCategoryFilter = false,
    bool clearTypeFilter = false,
  }) {
    return EtatTransactions(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      filterCategoryId: clearCategoryFilter
          ? null
          : (filterCategoryId ?? this.filterCategoryId),
      filterType: clearTypeFilter ? null : (filterType ?? this.filterType),
      filterMonth: filterMonth ?? this.filterMonth,
      filterYear: filterYear ?? this.filterYear,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TransactionsViewModel extends AsyncNotifier<EtatTransactions> {
  @override
  Future<EtatTransactions> build() async {
    final dateCourante = DateTime.now();
    return _chargerDonnees(dateCourante.month, dateCourante.year);
  }

  Future<EtatTransactions> _chargerDonnees(int mois, int annee) async {
    final repoTransactions = ref.read(repoTransactionProvider);
    final repoCategories = ref.read(repoCategorieProvider);

    final resultats = await Future.wait([
      repoTransactions.obtenirParMois(mois, annee),
      repoCategories.obtenirToutes(),
    ]);

    final etatCourant = state.valueOrNull;
    return EtatTransactions(
      transactions: resultats[0] as List<TransactionModele>,
      categories: resultats[1] as List<CategorieModele>,
      filterCategoryId: etatCourant?.filterCategoryId,
      filterType: etatCourant?.filterType,
      filterMonth: mois,
      filterYear: annee,
    );
  }

  Future<void> refresh() async {
    final etatCourant = state.valueOrNull;
    final dateCourante = DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _chargerDonnees(
        etatCourant?.filterMonth ?? dateCourante.month,
        etatCourant?.filterYear ?? dateCourante.year,
      ),
    );
  }

  void setTypeFilter(TypeTransaction? type) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      filterType: type,
      clearTypeFilter: type == null,
    ));
  }

  void setCategoryFilter(String? categoryId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      filterCategoryId: categoryId,
      clearCategoryFilter: categoryId == null,
    ));
  }

  Future<void> changeMonth(int month, int year) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _chargerDonnees(month, year));
  }

  Future<void> deleteTransaction(String id) async {
    final repoTransactions = ref.read(repoTransactionProvider);
    await repoTransactions.supprimerLogiquement(id);
    await refresh();
  }
}

final transactionsViewModelProvider =
    AsyncNotifierProvider<TransactionsViewModel, EtatTransactions>(
  TransactionsViewModel.new,
);
