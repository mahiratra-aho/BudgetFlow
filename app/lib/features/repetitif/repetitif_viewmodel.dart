import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repositories.dart';
import '../../data/models/repetitif.dart';

class RepetitifViewModel extends AsyncNotifier<List<RecurrenceModele>> {
  @override
  Future<List<RecurrenceModele>> build() async {
    return ref.read(repoRepetitifProvider).obtenirToutes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(repoRepetitifProvider).obtenirToutes(),
    );
  }

  Future<void> add(RecurrenceModele repetitif) async {
    await ref.read(repoRepetitifProvider).ajouter(repetitif);
    await refresh();
  }

  Future<void> updateRepetitif(RecurrenceModele repetitif) async {
    await ref.read(repoRepetitifProvider).mettreAJour(repetitif);
    await refresh();
  }

  Future<void> toggle(RecurrenceModele repetitif) async {
    final elementMisAJour = repetitif.copyWith(
      isActive: !repetitif.isActive,
    );
    await ref.read(repoRepetitifProvider).mettreAJour(elementMisAJour);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(repoRepetitifProvider).supprimerLogiquement(id);
    await refresh();
  }
}

final repetitifViewModelProvider =
    AsyncNotifierProvider<RepetitifViewModel, List<RecurrenceModele>>(
  RepetitifViewModel.new,
);
