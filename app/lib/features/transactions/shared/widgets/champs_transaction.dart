import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/utils/modeles.dart';

class SelecteurTypeTransaction extends StatelessWidget {
  final TypeTransaction typeActuel;
  final ValueChanged<TypeTransaction> onChanged;

  const SelecteurTypeTransaction({
    super.key,
    required this.typeActuel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.textePrincipal.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: TypeTransaction.values.map((t) {
          final estActif = t == typeActuel;
          final couleur = t == TypeTransaction.depense
              ? AppCouleurs.erreur
              : AppCouleurs.succes;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: estActif ? couleur : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.libelle,
                  style: AppTypographie.labelLarge.copyWith(
                    color: estActif
                        ? AppCouleurs.texteInverse
                        : AppCouleurs.texteSecondaire,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SaisieMontantTransaction extends StatelessWidget {
  final TextEditingController controleur;
  final TypeTransaction type;

  const SaisieMontantTransaction({
    super.key,
    required this.controleur,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppEspaces.lg,
        vertical: AppEspaces.xl,
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            type == TypeTransaction.depense ? '-' : '+',
            style: AppTypographie.headlineMedium.copyWith(
              color: type == TypeTransaction.depense
                  ? AppCouleurs.erreur
                  : AppCouleurs.succes,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controleur,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTypographie.displayMedium.copyWith(fontFamily: 'ComicNeue'),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            Devise.symbole,
            style: AppTypographie.headlineMedium
                .copyWith(color: AppCouleurs.texteSecondaire),
          ),
        ],
      ),
    );
  }
}

class ChampDateTransaction extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const ChampDateTransaction({
    super.key,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: AppCouleurs.primaire),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppCouleurs.surface,
              borderRadius: BorderRadius.circular(AppRayons.md),
              border: Border.all(
                color: AppCouleurs.textePrincipal.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppCouleurs.texteSecondaire,
                ),
                const SizedBox(width: 10),
                Text(label, style: AppTypographie.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SelecteurCategorieTransaction extends StatelessWidget {
  final List<Categorie> categories;
  final Categorie? selectionActuelle;
  final ValueChanged<Categorie> onSelectionne;

  const SelecteurCategorieTransaction({
    super.key,
    required this.categories,
    required this.selectionActuelle,
    required this.onSelectionne,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            border: Border.all(color: AppCouleurs.textePrincipal.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Categorie>(
              value: categories.contains(selectionActuelle) ? selectionActuelle : null,
              isExpanded: true,
              hint: Text(
                'Choisir une catégorie',
                style: AppTypographie.bodyMedium
                    .copyWith(color: AppCouleurs.texteTertiaire),
              ),
              borderRadius: BorderRadius.circular(AppRayons.md),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: categories
                  .map((cat) => DropdownMenuItem<Categorie>(
                        value: cat,
                        child: Text(cat.nom, style: AppTypographie.bodyMedium),
                      ))
                  .toList(),
              onChanged: (cat) {
                if (cat != null) onSelectionne(cat);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class SelecteurMembresTransaction extends StatelessWidget {
  final List<EntiteSimple> membres;
  final List<String> membreIdsSelectionnes;
  final ValueChanged<String> onToggle;

  const SelecteurMembresTransaction({
    super.key,
    required this.membres,
    required this.membreIdsSelectionnes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membres (optionnel)',
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            border: Border.all(color: AppCouleurs.textePrincipal.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EntiteSimple>(
              value: null,
              isExpanded: true,
              hint: Text(
                'Choisir un membre',
                style: AppTypographie.bodyMedium
                    .copyWith(color: AppCouleurs.texteTertiaire),
              ),
              borderRadius: BorderRadius.circular(AppRayons.md),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: membres
                  .where((m) => !membreIdsSelectionnes.contains(m.id))
                  .map((m) => DropdownMenuItem<EntiteSimple>(
                        value: m,
                        child: Text(m.nom, style: AppTypographie.bodyMedium),
                      ))
                  .toList(),
              onChanged: (m) {
                if (m != null) onToggle(m.id);
              },
            ),
          ),
        ),
        if (membreIdsSelectionnes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: membres
                .where((m) => membreIdsSelectionnes.contains(m.id))
                .map((m) => InputChip(
                      label: Text(m.nom),
                      showCheckmark: false,
                      selected: true,
                      onDeleted: () => onToggle(m.id),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class SelecteurMoyenPaiementTransaction extends StatelessWidget {
  final List<EntiteSimple> moyensPaiement;
  final String? moyenPaiementIdSelectionne;
  final ValueChanged<String?> onChanged;

  const SelecteurMoyenPaiementTransaction({
    super.key,
    required this.moyensPaiement,
    required this.moyenPaiementIdSelectionne,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectionValide = moyensPaiement
        .any((m) => m.id == moyenPaiementIdSelectionne);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moyen de paiement',
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            border: Border.all(color: AppCouleurs.textePrincipal.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectionValide ? moyenPaiementIdSelectionne : null,
              isExpanded: true,
              hint: Text(
                'Choisir un moyen de paiement',
                style: AppTypographie.bodyMedium
                    .copyWith(color: AppCouleurs.texteTertiaire),
              ),
              borderRadius: BorderRadius.circular(AppRayons.md),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Aucun'),
                ),
                ...moyensPaiement.map((m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.nom, style: AppTypographie.bodyMedium),
                    )),
              ],
              onChanged: (id) => onChanged(
                (id == null || id.isEmpty) ? null : id,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SectionImagesTransaction extends StatelessWidget {
  final List<String> chemins;
  final VoidCallback onAjouter;
  final ValueChanged<int> onSupprimer;

  const SectionImagesTransaction({
    super.key,
    required this.chemins,
    required this.onAjouter,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pièces jointes (optionnel)',
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: onAjouter,
                child: Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppCouleurs.surface,
                    borderRadius: BorderRadius.circular(AppRayons.md),
                    border: Border.all(
                      color: AppCouleurs.primaire.withOpacity(0.4),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppCouleurs.primaire, size: 26),
                      const SizedBox(height: 4),
                      Text(
                        'Ajouter',
                        style: AppTypographie.labelSmall
                            .copyWith(color: AppCouleurs.primaire),
                      ),
                    ],
                  ),
                ),
              ),
              ...chemins.asMap().entries.map((e) => Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRayons.md),
                          child: Image.file(File(e.value), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => onSupprimer(e.key),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppCouleurs.erreur,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: AppCouleurs.texteInverse),
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
