import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_budgets.dart';
import '../../../shared/utils/depot_transactions.dart';
import '../../../shared/utils/modeles.dart';
import '../../presentation/views/ecran_detail_transaction.dart';
import '../../presentation/widgets/accueil_widgets.dart';
import '../../presentation/widgets/carte_transaction_accueil.dart';
import '../../presentation/widgets/selecteur_mois.dart';

class EcranAccueil extends ConsumerWidget {
  final VoidCallback onAjouterTransaction;
  final VoidCallback onVoirTransactions;

  const EcranAccueil({
    super.key,
    required this.onAjouterTransaction,
    required this.onVoirTransactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurProvider);
    final mois = ref.watch(moisSelectionneProvider);
    final resumeAsync = ref.watch(resumeAccueilProvider);

    final soldeVisible = ref.watch(_soldeVisibleProvider);
    final totalRevenus = resumeAsync.valueOrNull?.totalRevenus ?? 0.0;
    final totalDepenses = resumeAsync.valueOrNull?.totalDepenses ?? 0.0;
    final soldeTotal = totalRevenus - totalDepenses;

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EnTeteAccueil(
              nomUtilisateur: utilisateur.nomAffiche,
              mois: mois,
              soldeTotal: soldeTotal,
              soldeVisible: soldeVisible,
              onToggleSolde: () => ref
                  .read(_soldeVisibleProvider.notifier)
                  .state = !soldeVisible,
              onChangerMois: () => _ouvrirSelecteurMois(context, ref),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppEspaces.lg)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaces.lg),
              child: Row(
                children: [
                  Expanded(
                    child: CarteResumeAccueil(
                      label: 'Revenus',
                      montant: Devise.formater(totalRevenus),
                      couleur: AppCouleurs.succes,
                    ),
                  ),
                  const SizedBox(width: AppEspaces.md),
                  Expanded(
                    child: CarteResumeAccueil(
                      label: 'Dépenses',
                      montant: Devise.formater(totalDepenses),
                      couleur: AppCouleurs.erreur,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppEspaces.xl)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaces.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions récentes',
                      style: AppTypographie.titleSmall),
                  TextButton(
                    onPressed: onVoirTransactions,
                    child: Text('Voir tout',
                        style: AppTypographie.labelMedium
                            .copyWith(color: AppCouleurs.primaire)),
                  ),
                ],
              ),
            ),
          ),

          resumeAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(
                  color: AppCouleurs.primaire,
                )),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
            data: (resume) {
              final transactions = resume.dernieresTransactions;
              if (transactions.isEmpty) {
                return SliverToBoxAdapter(
                  child: EtatVideTransactionsAccueil(
                    onAjouter: onAjouterTransaction,
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppEspaces.lg, vertical: 4),
                    child: CarteTransactionAccueil(
                      transaction: transactions[i],
                      onTap: () => _ouvrirDetail(context, ref, transactions[i]),
                      onSupprimer: () => _supprimerTransaction(
                          context, ref, transactions[i].id),
                    ),
                  ),
                  childCount: transactions.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAjouterTransaction,
        backgroundColor: AppCouleurs.primaire,
        elevation: 3,
        child: const Icon(Icons.add_rounded,
            color: AppCouleurs.textePrincipal, size: 28),
      ),
    );
  }

  void _ouvrirSelecteurMois(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => SelecteurMoisDialog(
        moisActuel: ref.read(moisSelectionneProvider),
        onSelectionne: (m) =>
            ref.read(moisSelectionneProvider.notifier).changerMois(m),
      ),
    );
  }

  void _ouvrirDetail(
      BuildContext context, WidgetRef ref, Transaction transaction) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: EcranDetailTransaction(transaction: transaction),
      ),
    ));
  }

  Future<void> _supprimerTransaction(
      BuildContext context, WidgetRef ref, String transactionId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.md)),
        title: Text('Supprimer ?', style: AppTypographie.titleSmall),
        content: Text('Cette transaction sera supprimée définitivement.',
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
                    borderRadius: BorderRadius.circular(AppRayons.md))),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      final transaction = await DepotTransactions.instance.lireParId(transactionId);
      await DepotTransactions.instance.supprimer(transactionId);
      if (transaction != null && transaction.type == TypeTransaction.depense) {
        await DepotBudgets.instance.retirerDepense(
          categorieId: transaction.categorie.id,
          montant: transaction.montant,
        );
      }
      invalidaterTransactions(ref);
    }
  }
}

final _soldeVisibleProvider = StateProvider.autoDispose<bool>((ref) => true);

