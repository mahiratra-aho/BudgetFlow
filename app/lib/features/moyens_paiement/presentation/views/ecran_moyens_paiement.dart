import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import 'ecran_ajout_moyen_paiement.dart';

const _cleMoyensPaiement = 'moyens_paiement';

class EcranMoyensPaiement extends StatefulWidget {
  const EcranMoyensPaiement({super.key});

  @override
  State<EcranMoyensPaiement> createState() => _EtatEcranMoyensPaiement();
}

class _EtatEcranMoyensPaiement extends State<EcranMoyensPaiement> {
  List<EntiteSimple> _items = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await DepotEntitesSimples.instance.lireTous(_cleMoyensPaiement);
    if (!mounted) return;
    setState(() => _items = data);
  }

  Future<void> _ouvrirForm([EntiteSimple? item]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EcranAjoutMoyenPaiement(itemExistant: item),
      ),
    );
    if (ok == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Moyens de paiement'),
      body: _items.isEmpty
          ? const Center(child: Text('Aucun moyen de paiement'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppEspaces.lg),
              itemBuilder: (_, i) {
                final item = _items[i];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppCouleurs.erreur,
                      borderRadius: BorderRadius.circular(AppRayons.md),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppCouleurs.texteInverse),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer ?'),
                        content: Text('Supprimer "${item.nom}" ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await DepotEntitesSimples.instance
                          .supprimer(_cleMoyensPaiement, item.id);
                      _charger();
                    }
                    return false;
                  },
                  child: ListTile(
                    onTap: () => _ouvrirForm(item),
                    tileColor: AppCouleurs.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRayons.md)),
                    title: Text(item.nom),
                    subtitle: item.detail == null ? null : Text(item.detail!),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _items.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirForm(),
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded, color: AppCouleurs.textePrincipal),
      ),
    );
  }
}
