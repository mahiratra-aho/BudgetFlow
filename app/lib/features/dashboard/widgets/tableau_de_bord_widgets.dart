import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/montant_utils.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/budget.dart';
import '../../../data/models/category.dart';
import '../../../data/models/goal.dart';
import '../../../data/models/transaction.dart';

class CarteBilanMensuel extends StatelessWidget {
  final double montantRevenus;
  final double montantDepenses;
  final double solde;
  final double soldeInitial;
  final double soldeCloture;
  final double? surchargeManuelle;
  final VoidCallback? onModifierSoldeInitial;

  const CarteBilanMensuel({
    super.key,
    required this.montantRevenus,
    required this.montantDepenses,
    required this.solde,
    this.soldeInitial = 0,
    this.soldeCloture = 0,
    this.surchargeManuelle,
    this.onModifierSoldeInitial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientCard(
      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde du mois',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              if (onModifierSoldeInitial != null)
                InkWell(
                  onTap: onModifierSoldeInitial,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Solde initial',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${FormatteurMontant.formatCourt(soldeCloture)} Ar',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          if (soldeInitial != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Report : ${FormatteurMontant.formatCourt(soldeInitial)} Ar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: surchargeManuelle != null
                        ? const Color(0xFFFFE082)
                        : Colors.white60,
                  ),
                ),
                if (surchargeManuelle != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded,
                      size: 11, color: Color(0xFFFFE082)),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
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

// Dialogue de saisie du solde initial.
Future<double?> showSoldeInitialDialog(
    BuildContext context, double valeurActuelle) async {
  final controller =
      TextEditingController(text: valeurActuelle.toStringAsFixed(0));
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Modifier le solde initial'),
      content: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        ],
        decoration: const InputDecoration(
          labelText: 'Solde initial (Ar)',
          suffixText: 'Ar',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final v = double.tryParse(controller.text);
            Navigator.pop(ctx, v);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
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
    final depassement = montantDepense > budget.amount;
    final progression = budget.amount > 0
        ? (montantDepense / budget.amount).clamp(0.0, 1.0)
        : 0.0;
    final couleurProgression = depassement ? AppColors.error : couleurCategorie;

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
                        color: depassement
                            ? AppColors.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (depassement)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Dépassement',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  '${(progression * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
              color: couleurProgression,
              minHeight: 6,
            ),
          ),
          if (depassement) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${FormatteurMontant.formatCourt(montantDepense - budget.amount)} Ar dépassés',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
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
