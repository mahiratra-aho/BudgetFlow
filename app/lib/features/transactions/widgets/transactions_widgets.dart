import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/cute_chip.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';

class BarreFiltresTransactions extends StatelessWidget {
  final TypeTransaction? typeFiltre;
  final List<CategorieModele> categories;
  final String? idCategorieSelectionnee;
  final int mois;
  final int annee;
  final ValueChanged<TypeTransaction?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(int month, int year) onMonthChanged;

  const BarreFiltresTransactions({
    super.key,
    required this.typeFiltre,
    required this.categories,
    required this.idCategorieSelectionnee,
    required this.mois,
    required this.annee,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maintenant = DateTime.now();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  final datePrecedente = DateTime(annee, mois - 1);
                  onMonthChanged(datePrecedente.month, datePrecedente.year);
                },
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(annee, mois),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    onMonthChanged(picked.month, picked.year);
                  }
                },
                child: Text(
                  '${AppDateUtils.monthName(mois).toUpperCase()} $annee',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: mois == maintenant.month && annee == maintenant.year
                    ? null
                    : () {
                        final dateSuivante = DateTime(annee, mois + 1);
                        onMonthChanged(dateSuivante.month, dateSuivante.year);
                      },
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CuteChip(
                  label: 'Tout',
                  selected: typeFiltre == null,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 8),
                CuteChip(
                  label: 'Revenus',
                  selected: typeFiltre == TypeTransaction.income,
                  color: AppColors.income,
                  icon: Icons.arrow_upward_rounded,
                  onTap: () => onTypeChanged(TypeTransaction.income),
                ),
                const SizedBox(width: 8),
                CuteChip(
                  label: 'Dépenses',
                  selected: typeFiltre == TypeTransaction.expense,
                  color: AppColors.expense,
                  icon: Icons.arrow_downward_rounded,
                  onTap: () => onTypeChanged(TypeTransaction.expense),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CarteTransaction extends StatelessWidget {
  final TransactionModele transaction;
  final CategorieModele categorie;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const CarteTransaction({
    super.key,
    required this.transaction,
    required this.categorie,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estDepense = transaction.type == TypeTransaction.expense;
    final couleurCategorie = Color(categorie.colorValue);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: couleurCategorie.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.category_rounded,
              color: couleurCategorie,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: couleurCategorie.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categorie.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: couleurCategorie,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatDayMonth(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountDisplay(
                amount: transaction.amount,
                isExpense: estDepense,
                style: theme.textTheme.titleSmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _confirmerSuppression(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "${transaction.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexteDialogue, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexteDialogue, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      onDelete();
    }
  }
}

class EtatVideTransactionsListe extends StatelessWidget {
  const EtatVideTransactionsListe({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction pour ce filtre',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.disabled,
                ),
          ),
        ],
      ),
    );
  }
}
