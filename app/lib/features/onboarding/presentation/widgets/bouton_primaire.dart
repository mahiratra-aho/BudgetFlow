import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BoutonPrimaire extends StatelessWidget {
  final String libelle;
  final VoidCallback onPress;
  final bool estChargement;

  const BoutonPrimaire({
    super.key,
    required this.libelle,
    required this.onPress,
    this.estChargement = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: estChargement ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCouleurs.primaire,
          foregroundColor: AppCouleurs.textePrincipal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.bouton),
          ),
        ),
        child: estChargement
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppCouleurs.textePrincipal,
                ),
              )
            : Text(
                libelle,
                style: AppTypographie.labelLarge.copyWith(
                  fontSize: 16,
                  color: AppCouleurs.textePrincipal,
                ),
              ),
      ),
    );
  }
}
