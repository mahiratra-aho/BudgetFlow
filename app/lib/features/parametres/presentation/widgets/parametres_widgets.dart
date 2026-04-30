import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/modeles.dart';

class CarteProfilParametres extends StatelessWidget {
  final UtilisateurLocal utilisateur;

  const CarteProfilParametres({super.key, required this.utilisateur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppEspaces.lg),
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.textePrincipal.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: utilisateur.estConnecte
                  ? AppCouleurs.primaireClaire
                  : AppCouleurs.fondSecondaire,
              shape: BoxShape.circle,
              border: Border.all(
                color: utilisateur.estConnecte
                    ? AppCouleurs.primaire
                    : AppCouleurs.textePrincipal.withOpacity(0.15),
                width: 2,
              ),
            ),
            child: SvgPicture.asset(
              'assets/icons/nounours.svg',
              fit: BoxFit.scaleDown,
            ),
          ),
          const SizedBox(width: AppEspaces.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(utilisateur.nomAffiche, style: AppTypographie.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Je gére mes finances',
                  style: AppTypographie.bodySmall
                      .copyWith(color: AppCouleurs.texteSecondaire),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BoutonActionParametres extends StatelessWidget {
  final IconData icone;
  final String label;
  final String description;
  final VoidCallback onTap;

  const BoutonActionParametres({
    super.key,
    required this.icone,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppCouleurs.surface,
      borderRadius: BorderRadius.circular(AppRayons.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRayons.md),
        child: Container(
          padding: const EdgeInsets.all(AppEspaces.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRayons.md),
            boxShadow: [
              BoxShadow(
                color: AppCouleurs.textePrincipal.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
            border: Border.all(
              color: AppCouleurs.primaire.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppCouleurs.primaire.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: AppCouleurs.primaire, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypographie.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(description, style: AppTypographie.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppCouleurs.texteTertiaire,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TitreSectionParametres extends StatelessWidget {
  final String titre;

  const TitreSectionParametres(this.titre, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      titre.toUpperCase(),
      style: AppTypographie.labelSmall.copyWith(
        color: AppCouleurs.texteSecondaire,
        letterSpacing: 1.2,
      ),
    );
  }
}

class GroupeParametres extends StatelessWidget {
  final List<Widget> enfants;

  const GroupeParametres({super.key, required this.enfants});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.textePrincipal.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: List.generate(enfants.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
              height: 1,
              color: AppCouleurs.textePrincipal.withOpacity(0.06),
              indent: 56,
            );
          }
          return enfants[i ~/ 2];
        }),
      ),
    );
  }
}

class ItemParametre extends StatelessWidget {
  final IconData icone;
  final String? svgAsset;
  final String label;
  final VoidCallback? onTap;

  const ItemParametre({
    super.key,
    this.icone = Icons.circle,
    this.svgAsset,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRayons.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              if (svgAsset != null)
                SvgPicture.asset(
                  svgAsset!,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppCouleurs.accentBrun,
                    BlendMode.srcIn,
                  ),
                )
              else
                Icon(icone, size: 22, color: AppCouleurs.accentBrun),
              const SizedBox(width: AppEspaces.md),
              Expanded(child: Text(label, style: AppTypographie.bodyMedium)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppCouleurs.texteTertiaire,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
