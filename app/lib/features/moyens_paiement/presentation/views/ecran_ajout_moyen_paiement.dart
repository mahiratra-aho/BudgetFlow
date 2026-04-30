import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';

const _cleMoyensPaiement = 'moyens_paiement';

class EcranAjoutMoyenPaiement extends StatefulWidget {
  final EntiteSimple? itemExistant;
  const EcranAjoutMoyenPaiement({super.key, this.itemExistant});

  @override
  State<EcranAjoutMoyenPaiement> createState() => _EtatEcranAjoutMoyenPaiement();
}

class _EtatEcranAjoutMoyenPaiement extends State<EcranAjoutMoyenPaiement> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _detailCtrl;
  String? _errNom;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.itemExistant?.nom ?? '');
    _detailCtrl = TextEditingController(text: widget.itemExistant?.detail ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _detailCtrl.dispose();
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
          .ajouter(_cleMoyensPaiement, nom, detail: _detailCtrl.text.trim());
    } else {
      await DepotEntitesSimples.instance.mettreAJour(
        _cleMoyensPaiement,
        widget.itemExistant!.copyWith(nom: nom, detail: _detailCtrl.text.trim()),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: widget.itemExistant == null
            ? 'Ajouter moyen de paiement'
            : 'Modifier moyen de paiement',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          children: [
            ChampFormulaire(
              label: 'Nom',
              placeholder: 'Ex: Carte BNI',
              controleur: _nomCtrl,
              messageErreur: _errNom,
            ),
            const SizedBox(height: AppEspaces.md),
            ChampFormulaire(
              label: 'Détail',
              placeholder: 'Ex: **** 1234',
              controleur: _detailCtrl,
            ),
            const SizedBox(height: AppEspaces.lg),
            BoutonPrimaire(libelle: 'Enregistrer', onPress: _save),
          ],
        ),
      ),
    );
  }
}
