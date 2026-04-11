import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/repo_budget.dart';
import '../../data/repositories/repo_categorie.dart';
import '../../data/repositories/repo_member.dart';
import '../../data/repositories/repo_objectif.dart';
import '../../data/repositories/repo_payment_method.dart';
import '../../data/repositories/repo_repetitif.dart';
import '../../data/repositories/repo_transaction.dart';
import '../auth/auth_viewmodel.dart';
import '../services/balance_carry_service.dart';

// Fournit la base de données SQLite isolée pour l'utilisateur connecté.
//
// Ce provider se re-crée automatiquement à chaque changement d'utilisateur
// (connexion / déconnexion) grâce au `ref.watch(authViewModelProvider)`.
// L'ancienne instance est fermée proprement via `ref.onDispose`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final user = ref.watch(authViewModelProvider).valueOrNull;
  if (user == null) {
    // Aucun utilisateur connecté — ne devrait pas arriver sur les écrans protégés.
    throw StateError(
        'Aucun utilisateur connecté : base de données inaccessible.');
  }
  final db = AppDatabase(user.id);
  ref.onDispose(() async => db.close());
  return db;
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

final repoMoyenPaiementProvider = Provider<RepoMoyenPaiement>((ref) {
  return RepoMoyenPaiement(ref.watch(appDatabaseProvider));
});

final repoMembreProvider = Provider<RepoMembre>((ref) {
  return RepoMembre(ref.watch(appDatabaseProvider));
});

final balanceCarryServiceProvider = Provider<BalanceCarryService>((ref) {
  final user = ref.watch(authViewModelProvider).valueOrNull;
  return BalanceCarryService(user?.id);
});
