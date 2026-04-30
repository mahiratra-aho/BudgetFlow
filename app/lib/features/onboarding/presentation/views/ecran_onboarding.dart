import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/bouton_primaire.dart';
import '../widgets/carte_onboarding.dart';
import '../widgets/indicateur_page.dart';

class EcranOnboarding extends ConsumerWidget {
  final Future<void> Function() onTerminer;

  const EcranOnboarding({super.key, required this.onTerminer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(onboardingViewModelProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: AppEspaces.md, right: AppEspaces.xl),
                child: AnimatedOpacity(
                  opacity: vm.estDernierePage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: vm.estDernierePage ? null : vm.passer,
                    child: Text(
                      'Passer',
                      style: AppTypographie.labelLarge
                          .copyWith(color: AppCouleurs.primaire),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: vm.controleurPage,
                onPageChanged: vm.mettreAJourIndex,
                itemCount: vm.pages.length,
                itemBuilder: (ctx, i) =>
                    CarteOnboarding(pageOnboarding: vm.pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspaces.xl,
                vertical: AppEspaces.lg,
              ),
              child: Column(
                children: [
                  IndicateurPage(
                    nombrePages: vm.pages.length,
                    indexCourant: vm.indexCourant,
                  ),
                  const SizedBox(height: AppEspaces.xl),
                  BoutonPrimaire(
                    libelle: vm.estDernierePage ? 'Commencer' : 'Suivant',
                    onPress: vm.estDernierePage
                        ? () => onTerminer()
                        : vm.pageSuivante,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
