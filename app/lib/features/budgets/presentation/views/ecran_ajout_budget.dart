import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/utils/depot_budgets.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';

class EcranAjoutBudget extends StatefulWidget {
  final BudgetLocal? budgetExistant;
  const EcranAjoutBudget({super.key, this.budgetExistant});

  @override
  State<EcranAjoutBudget> createState() => _EtatEcranAjoutBudget();
}

class _EtatEcranAjoutBudget extends State<EcranAjoutBudget> {
  late final TextEditingController _montantCtrl;
  List<Categorie> _categories = [];
  Categorie? _categorie;
  String? _erreurMontant;
  String? _erreurCategorie;

  @override
  void initState() {
    super.initState();
    _montantCtrl = TextEditingController(
      text: widget.budgetExistant?.montantTotal.toStringAsFixed(0) ?? '',
    );
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final cats = await DepotCategories.instance.lireParType(TypeTransaction.depense);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (widget.budgetExistant != null) {
        for (final c in cats) {
          if (c.id == widget.budgetExistant!.categorieId) {
            _categorie = c;
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    setState(() {
      _erreurCategorie = _categorie == null ? 'Veuillez choisir une catégorie' : null;
      _erreurMontant =
          (montant == null || montant <= 0) ? 'Veuillez saisir un montant valide' : null;
    });
    if (_erreurCategorie != null || _erreurMontant != null) return;

    final tousLesBudgets = await DepotBudgets.instance.lireTous();
    final budgetExistantMemeCategorie = tousLesBudgets.any(
      (b) =>
          b.categorieId == _categorie!.id &&
          b.id != widget.budgetExistant?.id,
    );
    if (budgetExistantMemeCategorie) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette catégorie a déjà un budget. Modifiez le budget existant.'),
        ),
      );
      return;
    }

    if (widget.budgetExistant == null) {
      await DepotBudgets.instance.ajouter(
        categorieId: _categorie!.id,
        categorieNom: _categorie!.nom,
        montantTotal: montant!,
      );
    } else {
      await DepotBudgets.instance.mettreAJour(
        widget.budgetExistant!.copyWith(
          categorieId: _categorie!.id,
          categorieNom: _categorie!.nom,
          montantTotal: montant,
        ),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: widget.budgetExistant == null ? 'Ajouter budget' : 'Modifier budget',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Catégorie', style: AppTypographie.labelLarge.copyWith(color: AppCouleurs.texteSecondaire)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppCouleurs.surface,
                borderRadius: BorderRadius.circular(AppRayons.md),
                border: Border.all(color: AppCouleurs.textePrincipal.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<Categorie>(
                    value: _categories.contains(_categorie) ? _categorie : null,
                    isExpanded: true,
                    hint: const Text('Choisir une catégorie'),
                    borderRadius: BorderRadius.circular(AppRayons.md),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.nom)))
                        .toList(),
                    onChanged: (v) => setState(() => _categorie = v),
                  ),
                ),
              ),
            ),
            if (_erreurCategorie != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _erreurCategorie!,
                  style: AppTypographie.bodySmall.copyWith(color: AppCouleurs.erreur),
                ),
              ),
            const SizedBox(height: AppEspaces.md),
            ChampFormulaire(
              label: 'Montant total (Ar)',
              placeholder: '0',
              controleur: _montantCtrl,
              typeClavier: const TextInputType.numberWithOptions(decimal: true),
              messageErreur: _erreurMontant,
            ),
            const SizedBox(height: AppEspaces.lg),
            BoutonPrimaire(
              libelle: 'Enregistrer',
              onPress: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
