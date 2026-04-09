import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import 'dashboard_viewmodel.dart';
import 'widgets/tableau_de_bord_widgets.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatTableauDeBord = ref.watch(dashboardViewModelProvider);
    final themeActuel = Theme.of(context);
    final dateCourante = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: etatTableauDeBord.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (etat) => RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardViewModelProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BudgetFlow',
                      style: themeActuel.textTheme.titleLarge,
                    ),
                    Text(
                      AppDateUtils.formatMonthYear(dateCourante),
                      style: themeActuel.textTheme.bodySmall?.copyWith(
                        color: themeActuel.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded),
                    tooltip: 'Statistiques',
                    onPressed: () => context.push(AppRoutes.stats),
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded),
                    tooltip: 'Répétitifs',
                    onPressed: () => context.push(AppRoutes.repetitif),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CarteBilanMensuel(
                      montantRevenus: etat.totalIncome,
                      montantDepenses: etat.totalExpense,
                      solde: etat.balance,
                    ),
                    const SizedBox(height: 20),
                    if (etat.budgets.isNotEmpty) ...[
                      EnteteSectionTableauDeBord(
                        titre: 'Budgets du mois',
                        onVoirTout: () => context.go(AppRoutes.budgets),
                      ),
                      const SizedBox(height: 12),
                      ...etat.budgets.take(3).map(
                            (budget) => LigneBudgetTableauDeBord(
                              budget: budget,
                              montantDepense:
                                  etat.spentByCategory[budget.categoryId] ?? 0,
                              categorie: etat.categories[budget.categoryId],
                            ),
                          ),
                      const SizedBox(height: 20),
                    ],
                    if (etat.goals.isNotEmpty) ...[
                      EnteteSectionTableauDeBord(
                        titre: 'Objectifs en cours',
                        onVoirTout: () => context.go(AppRoutes.goals),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: etat.goals.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, index) => CarteObjectifCompacte(
                            objectif: etat.goals[index],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    EnteteSectionTableauDeBord(
                      titre: 'Transactions récentes',
                      onVoirTout: () => context.go(AppRoutes.transactions),
                    ),
                    const SizedBox(height: 12),
                    if (etat.recentTransactions.isEmpty)
                      EtatVideTransactionsTableauDeBord(
                        onAjouter: () => context.push(AppRoutes.addTransaction),
                      )
                    else
                      ...etat.recentTransactions.map(
                        (transaction) => TuileTransactionTableauDeBord(
                          transaction: transaction,
                          categorie: etat.categories[transaction.categoryId],
                        ),
                      ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addTransaction),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
