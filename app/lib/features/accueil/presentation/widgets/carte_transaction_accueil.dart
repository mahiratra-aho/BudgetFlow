import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/modeles.dart';

class CarteTransactionAccueil extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onSupprimer;

  const CarteTransactionAccueil({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {},
      background: Container(
        decoration: BoxDecoration(
          color: AppCouleurs.erreur,
          borderRadius: BorderRadius.circular(AppRayons.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppEspaces.lg),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppCouleurs.texteInverse, size: 26),
      ),
      confirmDismiss: (_) async {
        onSupprimer();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppEspaces.md),
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            boxShadow: [
              BoxShadow(
                color: AppCouleurs.textePrincipal.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.titre,
                      style: AppTypographie.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      transaction.categorie.nom,
                      style: AppTypographie.bodySmall,
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.type == TypeTransaction.depense ? '-' : '+'}${Devise.formater(transaction.montant)}',
                    style: AppTypographie.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: transaction.type == TypeTransaction.depense
                          ? AppCouleurs.erreur
                          : AppCouleurs.succes,
                    ),
                  ),
                  Text(
                    _formaterDate(transaction.date),
                    style: AppTypographie.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) {
    final maintenant = DateTime.now();
    if (date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day) {
      return "Auj.";
    }
    if (date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day - 1) {
      return 'Hier';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
