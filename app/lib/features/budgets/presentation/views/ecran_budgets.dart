import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/shared/utils/depot_budgets.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import 'ecran_ajout_budget.dart';

// ─── Écran Budgets ────────────────────────────────────────────────────────────

class EcranBudgets extends StatefulWidget {
  const EcranBudgets({super.key});

  @override
  State<EcranBudgets> createState() => _EtatEcranBudgets();
}

class _EtatEcranBudgets extends State<EcranBudgets> {
  List<BudgetLocal> _budgets = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await DepotBudgets.instance.lireTous();
    if (!mounted) return;
    setState(() => _budgets = data);
  }

  Future<void> _ouvrirAjout([BudgetLocal? budget]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EcranAjoutBudget(budgetExistant: budget)),
    );
    if (ok == true) _charger();
  }

  Future<void> _supprimer(BudgetLocal budget) async {
    await DepotBudgets.instance.supprimer(budget.id);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Budgets', afficherRetour: false),
      body: _budgets.isEmpty
          ? const Center(child: Text('Aucun budget'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppEspaces.lg),
              itemBuilder: (_, i) {
                final b = _budgets[i];
                final p = b.montantTotal == 0 ? 0.0 : (b.montantDepense / b.montantTotal).clamp(0, 1);
                return Dismissible(
                  key: ValueKey(b.id),
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
                    await _supprimer(b);
                    return false;
                  },
                  child: ListTile(
                    onTap: () => _ouvrirAjout(b),
                    tileColor: AppCouleurs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRayons.md),
                    ),
                    title: Text(b.categorieNom),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(value: p.toDouble()),
                    ),
                    trailing: Text('${b.montantTotal.toStringAsFixed(0)} Ar'),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _budgets.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ouvrirAjout,
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded, color: AppCouleurs.textePrincipal),
      ),
    );
  }
}
