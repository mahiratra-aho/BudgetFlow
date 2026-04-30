import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'features/auth/connexion/presentation/views/ecran_connexion.dart';
import 'features/auth/inscription/presentation/views/ecran_inscription.dart';
import 'features/onboarding/presentation/views/ecran_onboarding.dart';
import 'features/shared/widgets/shell_navigation.dart';
import 'features/splash/presentation/views/ecran_splash.dart';

class AppNavigation extends ConsumerStatefulWidget {
  const AppNavigation({super.key});

  @override
  ConsumerState<AppNavigation> createState() => _EtatAppNavigation();
}

class _EtatAppNavigation extends ConsumerState<AppNavigation> {
  @override
  Widget build(BuildContext context) {
    final sessionInitAsync = ref.watch(sessionInitialiseeProvider);
    final onboardingVuAsync = ref.watch(onboardingVuProvider);
    final utilisateur = ref.watch(utilisateurProvider);

    if (sessionInitAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppCouleurs.fondSombre,
        body: Center(
          child: CircularProgressIndicator(color: AppCouleurs.primaire),
        ),
      );
    }

    return onboardingVuAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppCouleurs.fondSombre,
        body: Center(
          child: CircularProgressIndicator(color: AppCouleurs.primaire),
        ),
      ),
      error: (_, __) => const ShellNavigation(),
      data: (onboardingVu) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        child: _EcranInitial(
          onboardingVu: onboardingVu,
          utilisateurConnecte: utilisateur.estConnecte,
        ),
      ),
    ); 
  }
}

class _EcranInitial extends ConsumerStatefulWidget {
  final bool onboardingVu;
  final bool utilisateurConnecte;
  const _EcranInitial({
    required this.onboardingVu,
    required this.utilisateurConnecte,
  });

  @override
  ConsumerState<_EcranInitial> createState() => _EtatEcranInitial();
}

class _EtatEcranInitial extends ConsumerState<_EcranInitial> {
  bool _splashTermine = false;
  bool _onboardingTermine = false;
  bool _afficherConnexion = true;

  @override
  void didUpdateWidget(covariant _EcranInitial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.onboardingVu && oldWidget.onboardingVu != widget.onboardingVu) {
      _onboardingTermine = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Splash
    if (!_splashTermine) {
      return EcranSplash(
        key: const ValueKey('splash'),
        onTerminer: () => setState(() => _splashTermine = true),
      );
    }

    // 2. Onboarding (premier lancement seulement)
    if (!widget.onboardingVu && !_onboardingTermine) {
      return EcranOnboarding(
        key: const ValueKey('onboarding'),
        onTerminer: () async {
          await marquerOnboardingVu();
          setState(() => _onboardingTermine = true);
        },
      );
    }

    if (!widget.utilisateurConnecte) {
      if (_afficherConnexion) {
        return EcranConnexion(
          key: const ValueKey('connexion'),
          onConnecte: _finaliserConnexion,
          onInscription: () => setState(() => _afficherConnexion = false),
        );
      }
      return EcranInscription(
        key: const ValueKey('inscription'),
        onInscrit: (_) => setState(() => _afficherConnexion = true),
        onConnexion: () => setState(() => _afficherConnexion = true),
      );
    }

    return const ShellNavigation(key: ValueKey('shell'));
  }

  Future<void> _finaliserConnexion(String nom) async {
    final uid = 'uid_${nom.toLowerCase().replaceAll(' ', '_')}';
    await ref.read(utilisateurProvider.notifier).connecter(uid, nom);
    ref.invalidate(onboardingVuProvider);
    invalidaterTransactions(ref);
  }
}
