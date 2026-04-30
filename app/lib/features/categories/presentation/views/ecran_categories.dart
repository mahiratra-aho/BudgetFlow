import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import 'ecran_ajout_categorie.dart';

class EcranCategories extends StatefulWidget {
  const EcranCategories({super.key});

  @override
  State<EcranCategories> createState() => _EtatEcranCategories();
}

class _EtatEcranCategories extends State<EcranCategories> {
  List<Categorie> _items = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await DepotCategories.instance.lireTout();
    if (!mounted) return;
    setState(() => _items = data);
  }

  Future<void> _ouvrirForm([Categorie? item]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EcranAjoutCategorie(categorieExistante: item)),
    );
    if (ok == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Catégories'),
      body: _items.isEmpty
          ? const Center(child: Text('Aucune catégorie'))
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
                        content: Text('Supprimer la catégorie "${item.nom}" ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await DepotCategories.instance.supprimer(item.id);
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
                    subtitle: Text(item.type.libelle),
                    trailing: item.estDefaut ? const Text('Défaut') : null,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _items.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ouvrirForm,
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded, color: AppCouleurs.textePrincipal),
      ),
    );
  }
}
