import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/modeles.dart';

class EnTeteAccueil extends StatelessWidget {
  final String nomUtilisateur;
  final DateTime mois;
  final double soldeTotal;
  final bool soldeVisible;
  final VoidCallback onToggleSolde;
  final VoidCallback onChangerMois;

  const EnTeteAccueil({
    super.key,
    required this.nomUtilisateur,
    required this.mois,
    required this.soldeTotal,
    required this.soldeVisible,
    required this.onToggleSolde,
    required this.onChangerMois,
  });

  @override
  Widget build(BuildContext context) {
    final labelMois = DateFormat('MMMM yyyy', 'fr_FR').format(mois);
    final labelMoisCapitalise =
        labelMois[0].toUpperCase() + labelMois.substring(1);

    return Container(
      decoration: const BoxDecoration(
        color: AppCouleurs.primaire,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppEspaces.lg,
            AppEspaces.md,
            AppEspaces.lg,
            AppEspaces.xl,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppCouleurs.primaireClaire,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppCouleurs.texteInverse.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/nounours.svg',
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour',
                        style: AppTypographie.bodySmall
                            .copyWith(color: AppCouleurs.accentBrun),
                      ),
                      Text(
                        nomUtilisateur,
                        style: AppTypographie.titleSmall
                            .copyWith(color: AppCouleurs.textePrincipal),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppEspaces.xl),
              GestureDetector(
                onTap: onChangerMois,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppCouleurs.texteInverse.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labelMoisCapitalise,
                        style: AppTypographie.labelLarge
                            .copyWith(color: AppCouleurs.textePrincipal),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppCouleurs.textePrincipal,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppEspaces.md),
              Text(
                'Solde total',
                style: AppTypographie.bodyMedium.copyWith(
                  color: AppCouleurs.textePrincipal.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      soldeVisible ? Devise.formater(soldeTotal) : '••••••',
                      key: ValueKey(soldeVisible),
                      style: AppTypographie.displayMedium.copyWith(
                        color: AppCouleurs.textePrincipal,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleSolde,
                    child: SvgPicture.asset(
                      soldeVisible
                          ? 'assets/icons/see.svg'
                          : 'assets/icons/hide.svg',
                      width: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppEspaces.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class CarteResumeAccueil extends StatelessWidget {
  final String label;
  final String montant;
  final Color couleur;

  const CarteResumeAccueil({
    super.key,
    required this.label,
    required this.montant,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.textePrincipal.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: couleur, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypographie.bodySmall
                    .copyWith(color: AppCouleurs.texteSecondaire),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            montant,
            style: AppTypographie.titleSmall.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class EtatVideTransactionsAccueil extends StatelessWidget {
  final VoidCallback onAjouter;

  const EtatVideTransactionsAccueil({
    super.key,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppEspaces.xxl),
      child: Column(
        children: [
          SvgPicture.asset('assets/icons/wallet.svg', width: 80),
          const SizedBox(height: AppEspaces.md),
          Text(
            'Aucune transaction ce mois',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppEspaces.lg),
          TextButton.icon(
            onPressed: onAjouter,
            icon: const Icon(Icons.add_rounded, color: AppCouleurs.primaire),
            label: Text(
              'Ajouter une transaction',
              style: AppTypographie.labelLarge
                  .copyWith(color: AppCouleurs.primaire),
            ),
          ),
        ],
      ),
    );
  }
}
