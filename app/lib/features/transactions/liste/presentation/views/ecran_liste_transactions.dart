import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../accueil/presentation/views/ecran_detail_transaction.dart';
import '../../../../accueil/presentation/widgets/carte_transaction_accueil.dart';
import '../../../../shared/utils/depot_budgets.dart';
import '../../../../shared/utils/depot_transactions.dart';
import '../../../../shared/utils/modeles.dart';
import '../../../../shared/widgets/app_bar_budgetflow.dart';

final _filtreTypeProvider =
    StateProvider.autoDispose<TypeTransaction?>((ref) => null);
final _rechercheProvider = StateProvider.autoDispose<String>((ref) => '');

class EcranListeTransactions extends ConsumerWidget {
  final VoidCallback onAjouterTransaction;

  const EcranListeTransactions({
    super.key,
    required this.onAjouterTransaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsDuMoisProvider);
    final filtre = ref.watch(_filtreTypeProvider);
    final recherche = ref.watch(_rechercheProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Transactions'),
      body: Column(
        children: [
          // ── Barre de recherche ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppEspaces.lg, 0, AppEspaces.lg, AppEspaces.sm),
            child: TextField(
              onChanged: (v) =>
                  ref.read(_rechercheProvider.notifier).state = v,
              style: AppTypographie.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: AppTypographie.bodyMedium
                    .copyWith(color: AppCouleurs.texteTertiaire),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppCouleurs.texteSecondaire, size: 20),
                filled: true,
                fillColor: AppCouleurs.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRayons.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Filtres rapides ────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppEspaces.lg),
              children: [
                _ChipFiltre(
                  label: 'Tous',
                  estActif: filtre == null,
                  onTap: () =>
                      ref.read(_filtreTypeProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _ChipFiltre(
                  label: 'Dépenses',
                  estActif: filtre == TypeTransaction.depense,
                  couleur: AppCouleurs.erreur,
                  onTap: () => ref.read(_filtreTypeProvider.notifier).state =
                      TypeTransaction.depense,
                ),
                const SizedBox(width: 8),
                _ChipFiltre(
                  label: 'Revenus',
                  estActif: filtre == TypeTransaction.revenu,
                  couleur: AppCouleurs.succes,
                  onTap: () => ref.read(_filtreTypeProvider.notifier).state =
                      TypeTransaction.revenu,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppEspaces.md),

          // ── Liste ──────────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppCouleurs.primaire),
              ),
              error: (e, _) =>
                  Center(child: Text('Erreur : $e')),
              data: (toutes) {
                final filtrees = toutes.where((t) {
                  if (filtre != null && t.type != filtre) {
                    return false;
                  }
                  if (recherche.isNotEmpty &&
                      !t.titre
                          .toLowerCase()
                          .contains(recherche.toLowerCase()) &&
                      !t.categorie.nom
                          .toLowerCase()
                          .contains(recherche.toLowerCase())) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtrees.isEmpty) {
                  return _EtatVide(
                    recherche: recherche,
                    onAjouter: onAjouterTransaction,
                  );
                }

                // Grouper par date
                final groupes = <String, List<Transaction>>{};
                for (final t in filtrees) {
                  final cle = _cleDate(t.date);
                  groupes.putIfAbsent(cle, () => []).add(t);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppEspaces.lg),
                  itemCount: groupes.length,
                  itemBuilder: (ctx, i) {
                    final cle = groupes.keys.elementAt(i);
                    final liste = groupes[cle]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppEspaces.sm),
                          child: Text(cle,
                              style: AppTypographie.labelLarge.copyWith(
                                  color: AppCouleurs.texteSecondaire)),
                        ),
                        ...liste.map((t) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: CarteTransactionAccueil(
                                transaction: t,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProviderScope(
                                      parent: ProviderScope
                                          .containerOf(context),
                                      child: EcranDetailTransaction(
                                          transaction: t),
                                    ),
                                  ),
                                ),
                                onSupprimer: () => _supprimer(
                                    context, ref, t.id),
                              ),
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAjouterTransaction,
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded,
            color: AppCouleurs.textePrincipal),
      ),
    );
  }

  String _cleDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "Aujourd'hui";
    }
    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) return 'Hier';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _supprimer(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.md)),
        title:
            Text('Supprimer ?', style: AppTypographie.titleSmall),
        content: Text(
            'Cette transaction sera supprimée définitivement.',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppCouleurs.erreur,
                foregroundColor: AppCouleurs.texteInverse,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRayons.md))),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final tx = await DepotTransactions.instance.lireParId(id);
      await DepotTransactions.instance.supprimer(id);
      if (tx != null && tx.type == TypeTransaction.depense) {
        await DepotBudgets.instance.retirerDepense(
          categorieId: tx.categorie.id,
          montant: tx.montant,
        );
      }
      invalidaterTransactions(ref);
    }
  }
}

class _ChipFiltre extends StatelessWidget {
  final String label;
  final bool estActif;
  final VoidCallback onTap;
  final Color? couleur;

  const _ChipFiltre({
    required this.label,
    required this.estActif,
    required this.onTap,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? AppCouleurs.primaire;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: estActif ? c : AppCouleurs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: estActif
                ? c
                : AppCouleurs.textePrincipal.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTypographie.labelMedium.copyWith(
            color:
                estActif ? AppCouleurs.texteInverse : AppCouleurs.texteSecondaire,
          ),
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  final String recherche;
  final VoidCallback onAjouter;

  const _EtatVide({required this.recherche, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            recherche.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.receipt_long_outlined,
            size: 60,
            color: AppCouleurs.texteTertiaire,
          ),
          const SizedBox(height: 12),
          Text(
            recherche.isNotEmpty
                ? 'Aucun résultat pour "$recherche"'
                : 'Aucune transaction ce mois',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire),
            textAlign: TextAlign.center,
          ),
          if (recherche.isEmpty) ...[
            const SizedBox(height: AppEspaces.md),
            TextButton.icon(
              onPressed: onAjouter,
              icon: const Icon(Icons.add_rounded,
                  color: AppCouleurs.primaire),
              label: Text('Ajouter une transaction',
                  style: AppTypographie.labelLarge
                      .copyWith(color: AppCouleurs.primaire)),
            ),
          ],
        ],
      ),
    );
  }
}
