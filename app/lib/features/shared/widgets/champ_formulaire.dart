import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChampFormulaire extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controleur;
  final bool estMDP;
  final bool afficherVisibilite;
  final bool estVisible;
  final VoidCallback? onToggleVisibilite;
  final Widget? prefixIcone;
  final String? messageErreur;
  final TextInputType typeClavier;
  final String? valeurInitiale;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLignes;

  const ChampFormulaire({
    super.key,
    required this.label,
    this.placeholder,
    this.controleur,
    this.estMDP = false,
    this.afficherVisibilite = false,
    this.estVisible = false,
    this.onToggleVisibilite,
    this.prefixIcone,
    this.messageErreur,
    this.typeClavier = TextInputType.text,
    this.valeurInitiale,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLignes = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypographie.labelLarge.copyWith(
            color: AppCouleurs.texteSecondaire,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controleur,
          initialValue: controleur == null ? valeurInitiale : null,
          obscureText: estMDP && !estVisible,
          keyboardType: typeClavier,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLignes,
          style: AppTypographie.bodyMedium.copyWith(
            color: AppCouleurs.textePrincipal,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTypographie.bodyMedium.copyWith(
              color: AppCouleurs.texteTertiaire,
            ),
            filled: true,
            fillColor: AppCouleurs.surface,
            prefixIcon: prefixIcone != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: prefixIcone,
                  )
                : null,
            suffixIcon: afficherVisibilite
                ? IconButton(
                    onPressed: onToggleVisibilite,
                    icon: Icon(
                      estVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppCouleurs.texteSecondaire,
                      size: 20,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: BorderSide(
                color: AppCouleurs.textePrincipal.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: BorderSide(
                color: AppCouleurs.textePrincipal.withOpacity(0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: const BorderSide(
                color: AppCouleurs.primaire,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: const BorderSide(color: AppCouleurs.erreur),
            ),
            errorText: messageErreur,
          ),
        ),
      ],
    );
  }
}
