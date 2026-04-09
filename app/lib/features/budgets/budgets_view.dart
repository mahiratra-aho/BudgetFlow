import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/amount_display.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/montant_utils.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import 'budgets_viewmodel.dart';

class BudgetsView extends ConsumerWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(budgetsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: etat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (donnees) => RefreshIndicator(
          onRefresh: () =>
              ref.read(budgetsViewModelProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MonthNavigator(
                  month: donnees.month,
                  year: donnees.year,
                  onChanged: (m, y) => ref
                      .read(budgetsViewModelProvider.notifier)
                      .changeMonth(m, y),
                ),
              ),
              if (donnees.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _BudgetSummaryCard(
                      totalBudget: donnees.totalBudget,
                      totalSpent: donnees.totalSpent,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: donnees.items.isEmpty
                    ? SliverToBoxAdapter(
                        child: _EmptyBudgets(
                          onAdd: () => _showAddBudgetSheet(
                            context,
                            ref,
                            donnees.categories,
                            donnees.month,
                            donnees.year,
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final elementBudget = donnees.items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BudgetCard(
                                item: elementBudget,
                                onDelete: () => ref
                                    .read(budgetsViewModelProvider.notifier)
                                    .deleteBudget(elementBudget.budget.id),
                                onEdit: () => _showAddBudgetSheet(
                                  context,
                                  ref,
                                  donnees.categories,
                                  donnees.month,
                                  donnees.year,
                                  existing: elementBudget,
                                ),
                              ),
                            );
                          },
                          childCount: donnees.items.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => etat.whenData(
          (donnees) => _showAddBudgetSheet(
            context,
            ref,
            donnees.categories,
            donnees.month,
            donnees.year,
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showAddBudgetSheet(
    BuildContext context,
    WidgetRef ref,
    List<CategorieModele> categories,
    int month,
    int year, {
    BudgetAvecDepenses? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddBudgetSheet(
        categories: categories,
        month: month,
        year: year,
        existing: existing,
        onSave: (budget) => ref
            .read(budgetsViewModelProvider.notifier)
            .addOrUpdateBudget(budget),
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int, int) onChanged;

  const _MonthNavigator({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final dt = DateTime(year, month - 1);
              onChanged(dt.month, dt.year);
            },
          ),
          Text(
            '${AppDateUtils.monthName(month).toUpperCase()} $year',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: month == now.month && year == now.year
                ? null
                : () {
                    final dt = DateTime(year, month + 1);
                    onChanged(dt.month, dt.year);
                  },
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;

  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progression =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget total', style: theme.textTheme.titleSmall),
              AmountDisplay(
                amount: totalSpent,
                isExpense: true,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(progress: progression),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dépensé',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Budget: ${FormatteurMontant.formatCourt(totalBudget)} Ar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetAvecDepenses item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = item.category != null
        ? Color(item.category!.colorValue)
        : AppColors.primary;
    final depasseBudget = item.depasseBudget;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.category_rounded, color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category?.name ?? 'Catégorie',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${FormatteurMontant.formatCourt(item.spent)} / ${FormatteurMontant.formatCourt(item.budget.amount)} Ar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: depasseBudget
                            ? AppColors.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    depasseBudget
                        ? 'Dépassé!'
                        : '${FormatteurMontant.formatCourt(item.reste)} Ar restant',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: depasseBudget ? AppColors.error : AppColors.income,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: onEdit,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      InkWell(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            progress: item.progression,
            color: depasseBudget ? AppColors.error : catColor,
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  final List<CategorieModele> categories;
  final int month;
  final int year;
  final BudgetAvecDepenses? existing;
  final Future<void> Function(BudgetModele) onSave;

  const _AddBudgetSheet({
    required this.categories,
    required this.month,
    required this.year,
    this.existing,
    required this.onSave,
  });

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedCategoryId = widget.existing!.budget.categoryId;
      _amountController.text =
          widget.existing!.budget.amount.toStringAsFixed(0);
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final budget = BudgetModele.create(
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: widget.month,
        year: widget.year,
      );
      await widget.onSave(budget);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l’enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing != null ? 'Modifier le budget' : 'Nouveau budget',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Text('Catégorie', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(hintText: 'Choisir...'),
            items: widget.categories
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Montant budget',
              suffix: Text('Ar'),
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Enregistrer',
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudgets({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.pie_chart_outline_rounded,
              size: 56, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            'Aucun budget ce mois-ci',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.disabled),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer un budget'),
          ),
        ],
      ),
    );
  }
}
