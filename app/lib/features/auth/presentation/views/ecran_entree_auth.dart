import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../navigation.dart';
import '../../connexion/presentation/views/ecran_connexion.dart';
import '../../inscription/presentation/views/ecran_inscription.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';

class EcranEntreeAuth extends ConsumerWidget {
  const EcranEntreeAuth({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Connexion', afficherRetour: false),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'Connectez-vous pour retrouver vos données.',
              style: AppTypographie.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppEspaces.lg),
            ElevatedButton(
              onPressed: () => _ouvrirConnexion(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCouleurs.primaire,
                foregroundColor: AppCouleurs.textePrincipal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: AppEspaces.sm),
            OutlinedButton(
              onPressed: () => _ouvrirInscription(context, ref),
              child: const Text('Créer un compte'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _ouvrirConnexion(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => EcranConnexion(
          onConnecte: (nom) => _finaliserConnexion(pageContext, ref, nom),
          onInscription: () => _ouvrirInscriptionDepuisConnexion(pageContext, ref),
        ),
      ),
    );
  }

  void _ouvrirInscription(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => EcranInscription(
          onInscrit: (_) => _ouvrirConnexionDepuisInscription(pageContext, ref),
          onConnexion: () => _ouvrirConnexionDepuisInscription(pageContext, ref),
        ),
      ),
    );
  }

  Future<void> _finaliserConnexion(
    BuildContext pageContext,
    WidgetRef ref,
    String nom,
  ) async {
    final uid = 'uid_${nom.toLowerCase().replaceAll(' ', '_')}';
    await ref.read(utilisateurProvider.notifier).connecter(uid, nom);
    ref.invalidate(onboardingVuProvider);
    invalidaterTransactions(ref);
    if (pageContext.mounted) {
      Navigator.of(pageContext, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppNavigation()),
        (route) => false,
      );
    }
  }

  void _ouvrirInscriptionDepuisConnexion(BuildContext pageContext, WidgetRef ref) {
    Navigator.of(pageContext).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => EcranInscription(
          onInscrit: (_) => _ouvrirConnexionDepuisInscription(ctx, ref),
          onConnexion: () => _ouvrirConnexionDepuisInscription(ctx, ref),
        ),
      ),
    );
  }

  void _ouvrirConnexionDepuisInscription(BuildContext pageContext, WidgetRef ref) {
    Navigator.of(pageContext).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => EcranConnexion(
          onConnecte: (nom) => _finaliserConnexion(ctx, ref, nom),
          onInscription: () => _ouvrirInscriptionDepuisConnexion(ctx, ref),
        ),
      ),
    );
  }
}
