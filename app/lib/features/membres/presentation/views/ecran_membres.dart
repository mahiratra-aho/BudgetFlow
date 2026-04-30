import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import 'ecran_ajout_membre.dart';

const _cleMembres = 'membres_budgetflow';

class EcranMembres extends StatefulWidget {
  const EcranMembres({super.key});

  @override
  State<EcranMembres> createState() => _EtatEcranMembres();
}

class _EtatEcranMembres extends State<EcranMembres> {
  List<EntiteSimple> _items = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await DepotEntitesSimples.instance.lireTous(_cleMembres);
    if (!mounted) return;
    setState(() => _items = data);
  }

  Future<void> _ouvrirForm([EntiteSimple? item]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EcranAjoutMembre(itemExistant: item)),
    );
    if (ok == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Membres'),
      body: _items.isEmpty
          ? const Center(child: Text('Aucun membre'))
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
                    await DepotEntitesSimples.instance.supprimer(_cleMembres, item.id);
                    _charger();
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
