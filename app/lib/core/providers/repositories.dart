import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/repo_budget.dart';
import '../../data/repositories/repo_categorie.dart';
import '../../data/repositories/repo_objectif.dart';
import '../../data/repositories/repo_repetitif.dart';
import '../../data/repositories/repo_transaction.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final repoCategorieProvider = Provider<RepoCategorie>((ref) {
  return RepoCategorie(ref.watch(appDatabaseProvider));
});

final repoTransactionProvider = Provider<RepoTransaction>((ref) {
  return RepoTransaction(ref.watch(appDatabaseProvider));
});

final repoBudgetProvider = Provider<RepoBudget>((ref) {
  return RepoBudget(ref.watch(appDatabaseProvider));
});

final repoObjectifProvider = Provider<RepoObjectif>((ref) {
  return RepoObjectif(ref.watch(appDatabaseProvider));
});

final repoRepetitifProvider = Provider<RepoRepetitif>((ref) {
  return RepoRepetitif(ref.watch(appDatabaseProvider));
});
final repoRecurrenceProvider = repoRepetitifProvider;
