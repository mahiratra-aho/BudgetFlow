import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_auth_service.dart';
import 'local_user.dart';

// État de la session : null = non connecté, LocalUser = connecté.
class AuthViewModel extends AsyncNotifier<LocalUser?> {
  @override
  Future<LocalUser?> build() => LocalAuthService.instance.getCurrentUser();

  // Crée un compte et met à jour l'état.
  Future<void> signUp({
    required String email,
    required String password,
    required String pseudo,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LocalAuthService.instance.signUp(
        email: email,
        password: password,
        pseudo: pseudo,
      ),
    );
  }

  // Connecte un utilisateur existant et met à jour l'état.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LocalAuthService.instance.signIn(
        email: email,
        password: password,
      ),
    );
  }

  // Déconnecte l'utilisateur courant.
  Future<void> signOut() async {
    state = const AsyncLoading();
    await LocalAuthService.instance.signOut();
    state = const AsyncData(null);
  }
}

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, LocalUser?>(AuthViewModel.new);
