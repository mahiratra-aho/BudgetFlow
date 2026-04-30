import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AppBarBudgetFlow extends StatelessWidget implements PreferredSizeWidget {
  final String titre;
  final bool afficherRetour;
  final List<Widget>? actions;
  final Color? couleurFond;
  final Color? couleurTitre;

  const AppBarBudgetFlow({
    super.key,
    required this.titre,
    this.afficherRetour = true,
    this.actions,
    this.couleurFond,
    this.couleurTitre,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: couleurFond ?? AppCouleurs.fondPrincipal,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: afficherRetour
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppCouleurs.accentBrun,
                size: 20,
              ),
            )
          : null,
      title: Text(
        titre,
        style: AppTypographie.titleMedium.copyWith(
          color: couleurTitre ?? AppCouleurs.textePrincipal,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
