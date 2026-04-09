import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/goal.dart';
import '../../../core/providers/repositories.dart';

class GoalsViewModel extends AsyncNotifier<List<ObjectifModele>> {
  @override
  Future<List<ObjectifModele>> build() async {
    return ref.read(repoObjectifProvider).obtenirTous();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(repoObjectifProvider).obtenirTous(),
    );
  }

  Future<void> addGoal(ObjectifModele goal) async {
    await ref.read(repoObjectifProvider).ajouter(goal);
    await refresh();
  }

  Future<void> updateGoal(ObjectifModele goal) async {
    await ref.read(repoObjectifProvider).mettreAJour(goal);
    await refresh();
  }

  Future<void> ajouterMontant(String id, double amount) async {
    await ref.read(repoObjectifProvider).ajouterMontant(id, amount);
    await refresh();
  }

  Future<void> deleteGoal(String id) async {
    await ref.read(repoObjectifProvider).supprimerLogiquement(id);
    await refresh();
  }
}

final goalsViewModelProvider =
    AsyncNotifierProvider<GoalsViewModel, List<ObjectifModele>>(
  GoalsViewModel.new,
);
