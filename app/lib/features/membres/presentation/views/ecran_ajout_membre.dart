import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';

const _cleMembres = 'membres_budgetflow';

class EcranAjoutMembre extends StatefulWidget {
  final EntiteSimple? itemExistant;
  const EcranAjoutMembre({super.key, this.itemExistant});

  @override
  State<EcranAjoutMembre> createState() => _EtatEcranAjoutMembre();
}

class _EtatEcranAjoutMembre extends State<EcranAjoutMembre> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _roleCtrl;
  String? _errNom;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.itemExistant?.nom ?? '');
    _roleCtrl = TextEditingController(text: widget.itemExistant?.detail ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _errNom = 'Champ requis');
      return;
    }
    if (widget.itemExistant == null) {
      await DepotEntitesSimples.instance
          .ajouter(_cleMembres, nom, detail: _roleCtrl.text.trim());
    } else {
      await DepotEntitesSimples.instance.mettreAJour(
        _cleMembres,
        widget.itemExistant!.copyWith(nom: nom, detail: _roleCtrl.text.trim()),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: widget.itemExistant == null ? 'Ajouter membre' : 'Modifier membre',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          children: [
            ChampFormulaire(
              label: 'Nom',
              placeholder: 'Ex: Jean',
              controleur: _nomCtrl,
              messageErreur: _errNom,
            ),
            const SizedBox(height: AppEspaces.md),
            ChampFormulaire(
              label: 'Rôle',
              placeholder: 'Ex: Conjoint',
              controleur: _roleCtrl,
            ),
            const SizedBox(height: AppEspaces.lg),
            BoutonPrimaire(libelle: 'Enregistrer', onPress: _save),
          ],
        ),
      ),
    );
  }
}
