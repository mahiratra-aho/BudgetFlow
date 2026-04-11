import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import 'transactions_viewmodel.dart';
import 'widgets/transactions_widgets.dart';

class TransactionsView extends ConsumerWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(transactionsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.addTransaction),
          ),
        ],
      ),
      body: etat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (donnees) => Column(
          children: [
            BarreFiltresTransactions(
              typeFiltre: donnees.filterType,
              categories: donnees.categories,
              idCategorieSelectionnee: donnees.filterCategoryId,
              mois: donnees.filterMonth,
              annee: donnees.filterYear,
              onTypeChanged: (t) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setTypeFilter(t),
              onCategoryChanged: (c) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setCategoryFilter(c),
              onMonthChanged: (m, y) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .changeMonth(m, y),
            ),
            _BarreRecherche(
              query: donnees.searchQuery,
              onChanged: (q) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setSearchQuery(q),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(transactionsViewModelProvider.notifier).refresh(),
                child: donnees.transactionsFiltrees.isEmpty
                    ? const EtatVideTransactionsListe()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: donnees.transactionsFiltrees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final transaction = donnees.transactionsFiltrees[i];
                          final categorie = donnees.categories.firstWhere(
                            (categorie) =>
                                categorie.id == transaction.categoryId,
                            orElse: () => CategorieModele.create(
                              name: 'Autre',
                              icon: 'more_horiz',
                              colorValue: AppColors.disabled.toARGB32(),
                              type: 'both',
                            ),
                          );

                          return CarteTransaction(
                            transaction: transaction,
                            categorie: categorie,
                            onDelete: () => ref
                                .read(transactionsViewModelProvider.notifier)
                                .deleteTransaction(transaction.id),
                            onEdit: () => context.push(
                              AppRoutes.addTransaction,
                              extra: {'editId': transaction.id},
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _BarreRecherche extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _BarreRecherche({required this.query, required this.onChanged});

  @override
  State<_BarreRecherche> createState() => _BarreRechercheState();
}

class _BarreRechercheState extends State<_BarreRecherche> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(_BarreRecherche oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une transaction…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }
}
