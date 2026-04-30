import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';

class EcranAjoutCategorie extends StatefulWidget {
  final Categorie? categorieExistante;
  const EcranAjoutCategorie({super.key, this.categorieExistante});

  @override
  State<EcranAjoutCategorie> createState() => _EtatEcranAjoutCategorie();
}

class _EtatEcranAjoutCategorie extends State<EcranAjoutCategorie> {
  late final TextEditingController _nomCtrl;
  TypeTransaction _type = TypeTransaction.depense;
  String? _errNom;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.categorieExistante?.nom ?? '');
    _type = widget.categorieExistante?.type ?? TypeTransaction.depense;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _errNom = 'Champ requis');
      return;
    }
    if (widget.categorieExistante == null) {
      final cat = Categorie(
        id: 'usr_${const Uuid().v4()}',
        nom: nom,
        iconeCode: 0xe7c9,
        couleurHex: 'F9C12B',
        type: _type,
        estDefaut: false,
      );
      await DepotCategories.instance.inserer(cat);
    } else {
      await DepotCategories.instance.mettreAJour(
        widget.categorieExistante!.copyWith(nom: nom, type: _type),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: widget.categorieExistante == null
            ? 'Ajouter catégorie'
            : 'Modifier catégorie',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          children: [
            ChampFormulaire(
              label: 'Nom',
              placeholder: 'Ex: Transport',
              controleur: _nomCtrl,
              messageErreur: _errNom,
            ),
            const SizedBox(height: AppEspaces.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Type',
                  style: AppTypographie.labelLarge
                      .copyWith(color: AppCouleurs.texteSecondaire)),
            ),
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
                  child: DropdownButton<TypeTransaction>(
                    value: _type,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRayons.md),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    items: TypeTransaction.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.libelle)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppEspaces.lg),
            BoutonPrimaire(libelle: 'Enregistrer', onPress: _save),
          ],
        ),
      ),
    );
  }
}
