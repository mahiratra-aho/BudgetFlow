import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/montant_utils.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/budget.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/goal.dart';
import '../../../../data/models/transaction.dart';

class CarteBilanMensuel extends StatelessWidget {
  final double montantRevenus;
  final double montantDepenses;
  final double solde;

  const CarteBilanMensuel({
    super.key,
    required this.montantRevenus,
    required this.montantDepenses,
    required this.solde,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientCard(
      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde du mois',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${FormatteurMontant.formatCourt(solde)} Ar',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ElementResume(
                  icone: Icons.arrow_upward_rounded,
                  libelle: 'Revenus',
                  montant: montantRevenus,
                  couleur: const Color(0xFF81F4C3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ElementResume(
                  icone: Icons.arrow_downward_rounded,
                  libelle: 'Dépenses',
                  montant: montantDepenses,
                  couleur: const Color(0xFFFFB3C6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementResume extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final double montant;
  final Color couleur;

  const _ElementResume({
    required this.icone,
    required this.libelle,
    required this.montant,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: couleur, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                '${FormatteurMontant.formatCourt(montant)} Ar',
                style: theme.textTheme.labelLarge?.copyWith(color: couleur),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EnteteSectionTableauDeBord extends StatelessWidget {
  final String titre;
  final VoidCallback? onVoirTout;

  const EnteteSectionTableauDeBord({
    super.key,
    required this.titre,
    this.onVoirTout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre, style: theme.textTheme.titleMedium),
        if (onVoirTout != null)
          TextButton(
            onPressed: onVoirTout,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Voir tout'),
          ),
      ],
    );
  }
}

class LigneBudgetTableauDeBord extends StatelessWidget {
  final BudgetModele budget;
  final double montantDepense;
  final CategorieModele? categorie;

  const LigneBudgetTableauDeBord({
    super.key,
    required this.budget,
    required this.montantDepense,
    this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurCategorie =
        categorie != null ? Color(categorie!.colorValue) : AppColors.primary;
    final progression = budget.amount > 0
        ? (montantDepense / budget.amount).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: couleurCategorie.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: couleurCategorie,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categorie?.name ?? 'Catégorie',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${FormatteurMontant.formatCourt(montantDepense)} / ${FormatteurMontant.formatCourt(budget.amount)} Ar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progression * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: progression >= 1.0
                      ? AppColors.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progression,
              backgroundColor: AppColors.surface,
              color: progression >= 1.0 ? AppColors.error : couleurCategorie,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class CarteObjectifCompacte extends StatelessWidget {
  final ObjectifModele objectif;

  const CarteObjectifCompacte({
    super.key,
    required this.objectif,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = Color(objectif.colorValue);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.savings_rounded, color: couleur, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    objectif.name,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: objectif.progression,
                backgroundColor: AppColors.surface,
                color: couleur,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(objectif.progression * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(color: couleur),
            ),
          ],
        ),
      ),
    );
  }
}

class TuileTransactionTableauDeBord extends StatelessWidget {
  final TransactionModele transaction;
  final CategorieModele? categorie;

  const TuileTransactionTableauDeBord({
    super.key,
    required this.transaction,
    this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estDepense = transaction.type == TypeTransaction.expense;
    final couleurCategorie = categorie != null
        ? Color(categorie!.colorValue)
        : (estDepense ? AppColors.expense : AppColors.income);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: couleurCategorie.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category_rounded,
                color: couleurCategorie,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${categorie?.name ?? ''} • ${AppDateUtils.formatRelative(transaction.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AmountDisplay(
              amount: transaction.amount,
              isExpense: estDepense,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class EtatVideTransactionsTableauDeBord extends StatelessWidget {
  final VoidCallback onAjouter;

  const EtatVideTransactionsTableauDeBord({
    super.key,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune transaction ce mois-ci',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.disabled,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAjouter,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter ma première transaction'),
          ),
        ],
      ),
    );
  }
}
