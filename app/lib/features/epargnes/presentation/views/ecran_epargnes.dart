import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/utils/depot_transactions.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';
import '../../utils/depot_epargnes.dart';

class EcranEpargnes extends ConsumerStatefulWidget {
  final VoidCallback? onAjouterEpargne;
  const EcranEpargnes({super.key, this.onAjouterEpargne});

  @override
  ConsumerState<EcranEpargnes> createState() => _EtatEcranEpargnes();
}

class _EtatEcranEpargnes extends ConsumerState<EcranEpargnes> {
  List<EpargneObjectif> _objectifsEpargne = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final objectifs = await DepotEpargnes.instance.lireTous();
    if (!mounted) return;
    setState(() => _objectifsEpargne = objectifs);
  }

  Future<void> _ajouterEpargne() async {
    final item = await _ouvrirFormEpargne();
    if (item != null) {
      await DepotEpargnes.instance.ajouter(nom: item.nom, objectif: item.objectif);
      await _charger();
    }
  }

  Future<EpargneObjectif?> _ouvrirFormEpargne([EpargneObjectif? objectifExistant]) async {
    final nomCtrl = TextEditingController(text: objectifExistant?.nom ?? '');
    final objectifCtrl = TextEditingController(
      text: objectifExistant?.objectif.toStringAsFixed(0) ?? '',
    );
    String? errNom;
    String? errObjectif;
    return showModalBottomSheet<EpargneObjectif>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppCouleurs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppEspaces.lg,
            AppEspaces.lg,
            AppEspaces.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppEspaces.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                objectifExistant == null ? 'Nouvelle épargne' : 'Modifier l\'épargne',
                style: AppTypographie.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppEspaces.lg),
              ChampFormulaire(
                label: 'Nom de l\'épargne',
                placeholder: 'Ex: Voyage, Urgence...',
                controleur: nomCtrl,
                messageErreur: errNom,
              ),
              const SizedBox(height: AppEspaces.md),
              _ChampMontantEpargne(
                label: 'Objectif',
                controller: objectifCtrl,
                errorText: errObjectif,
              ),
              const SizedBox(height: AppEspaces.lg),
              BoutonPrimaire(
                libelle: objectifExistant == null ? 'Ajouter' : 'Enregistrer',
                onPress: () {
                  final objectif =
                      double.tryParse(objectifCtrl.text.replaceAll(',', '.'));
                  setSt(() {
                    errNom = nomCtrl.text.trim().isEmpty ? 'Champ requis' : null;
                    errObjectif = (objectif == null || objectif <= 0)
                        ? 'Montant invalide'
                        : null;
                  });
                  if (errNom != null || errObjectif != null) return;
                  Navigator.pop(
                    ctx,
                    EpargneObjectif(
                      id: objectifExistant?.id ?? '',
                      nom: nomCtrl.text.trim(),
                      objectif: objectif!,
                      montantActuel: objectifExistant?.montantActuel ?? 0,
                      creeLe: objectifExistant?.creeLe ?? DateTime.now(),
                      transactionIds: objectifExistant?.transactionIds ?? const [],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _modifier(EpargneObjectif objectif) async {
    final objectifModifie = await _ouvrirFormEpargne(objectif);
    if (objectifModifie == null) return;
    var aSauver = objectifModifie;
    if (aSauver.montantActuel > aSauver.objectif) {
      aSauver = aSauver.copyWith(montantActuel: aSauver.objectif);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
            ),
            title: Text('Objectif revu à la baisse',
                style: AppTypographie.titleSmall),
            content: Text(
              'Le solde (${Devise.formater(objectifModifie.montantActuel)}) dépassait le nouvel objectif '
              '(${Devise.formater(aSauver.objectif)}). Le solde a été plafonné à l\'objectif.',
              style: AppTypographie.bodyMedium
                  .copyWith(color: AppCouleurs.texteSecondaire),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK',
                    style: AppTypographie.labelLarge
                        .copyWith(color: AppCouleurs.primaire)),
              ),
            ],
          ),
        );
      }
    }
    await DepotEpargnes.instance.mettreAJour(aSauver);
    await _charger();
  }

  Future<void> _ajouterMontant(EpargneObjectif objectif) async {
    if (objectif.montantActuel >= objectif.objectif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objectif atteint. Modifiez l\'objectif pour continuer.')),
      );
      return;
    }
    final ctrl = TextEditingController();
    String? errMontant;
    final montant = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppCouleurs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppEspaces.lg,
            AppEspaces.lg,
            AppEspaces.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppEspaces.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajouter à ${objectif.nom}',
                style: AppTypographie.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppEspaces.lg),
              _ChampMontantEpargne(
                label: 'Montant',
                controller: ctrl,
                errorText: errMontant,
              ),
              const SizedBox(height: AppEspaces.lg),
              BoutonPrimaire(
                libelle: 'Ajouter',
                onPress: () {
                  final valeur = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  setSt(() {
                    errMontant = (valeur == null || valeur <= 0)
                        ? 'Montant invalide'
                        : null;
                  });
                  if (errMontant != null) return;
                  Navigator.pop(ctx, valeur);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (montant == null) return;

    final reste = objectif.objectif - objectif.montantActuel;
    if (montant > reste && reste > 0) {
      final continuer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.md),
          ),
          title:
              Text('Dépassement de l\'objectif', style: AppTypographie.titleSmall),
          content: Text(
            'Il ne reste que ${Devise.formater(reste)} pour atteindre « ${objectif.nom} ». '
            'Seul ce montant sera ajouté au solde de l\'objectif ; la dépense enregistrée '
            'restera de ${Devise.formater(montant)}.',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler',
                  style: AppTypographie.labelLarge
                      .copyWith(color: AppCouleurs.texteSecondaire)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCouleurs.primaire,
                foregroundColor: AppCouleurs.textePrincipal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRayons.md),
                ),
              ),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (continuer != true || !mounted) return;
    }

    final categories = await DepotCategories.instance.lireParType(TypeTransaction.depense);
    if (categories.isEmpty) {
      await DepotCategories.instance.initialiserParDefaut();
    }
    final depenseCat = (await DepotCategories.instance.lireParType(TypeTransaction.depense)).first;
    final tx = await DepotTransactions.instance.inserer(
      titre: 'Epargne: ${objectif.nom}',
      montant: montant,
      type: TypeTransaction.depense,
      categorie: depenseCat,
      date: DateTime.now(),
      note: 'Ajout à un objectif d\'épargne',
    );
    final avant = objectif.montantActuel;
    // On borne le solde pour ne jamais depasser l'objectif.
    final nouveauSolde =
        (avant + montant).clamp(0, objectif.objectif).toDouble();
    await DepotEpargnes.instance.mettreAJour(
      objectif.copyWith(
        montantActuel: nouveauSolde,
        transactionIds: [...objectif.transactionIds, tx.id],
      ),
    );
    invalidaterTransactions(ref);
    await _charger();

    if (!mounted) return;

    final obj = objectif.objectif;
    if (obj > 0) {
      final progAvant = avant / obj;
      final progApres = nouveauSolde / obj;
      if (progApres >= 0.9 && progAvant < 0.9 && nouveauSolde < obj) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vous approchez de l\'objectif « ${objectif.nom} » (90 %).',
            ),
          ),
        );
      }
    }

    if (nouveauSolde >= objectif.objectif && avant < objectif.objectif) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.md),
          ),
          title: Text('Objectif atteint', style: AppTypographie.titleSmall),
          content: Text(
            'Félicitations ! L\'objectif « ${objectif.nom} » est atteint '
            '(${Devise.formater(nouveauSolde)}).',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK',
                  style: AppTypographie.labelLarge
                      .copyWith(color: AppCouleurs.primaire)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _supprimer(EpargneObjectif objectif) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer l\'objectif "${objectif.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      for (final txId in objectif.transactionIds) {
        await DepotTransactions.instance.supprimer(txId);
      }
      await DepotEpargnes.instance.supprimer(objectif.id);
      invalidaterTransactions(ref);
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: 'Épargnes',
        afficherRetour: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _objectifsEpargne.isEmpty
                  ? const Center(
                      child: Text('Aucune épargne pour le moment',
                          style: AppTypographie.bodyMedium),
                    )
                  : ListView.separated(
                      itemCount: _objectifsEpargne.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final objectif = _objectifsEpargne[i];
                        final progression = objectif.objectif == 0
                            ? 0.0
                            : (objectif.montantActuel / objectif.objectif)
                                .clamp(0, 1)
                                .toDouble();
                        return Dismissible(
                          key: ValueKey(objectif.id),
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
                            await _supprimer(objectif);
                            return false;
                          },
                          child: GestureDetector(
                            onTap: () => _modifier(objectif),
                            child: Container(
                              padding: const EdgeInsets.all(AppEspaces.md),
                              decoration: BoxDecoration(
                                color: AppCouleurs.surface,
                                borderRadius: BorderRadius.circular(AppRayons.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.savings_rounded, color: AppCouleurs.primaire),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(objectif.nom)),
                                      Text('${objectif.montantActuel.toStringAsFixed(0)} / ${objectif.objectif.toStringAsFixed(0)} Ar'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progression,
                                      minHeight: 7,
                                      backgroundColor: AppCouleurs.fondSecondaire,
                                      valueColor: const AlwaysStoppedAnimation(AppCouleurs.primaire),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: objectif.montantActuel >= objectif.objectif
                                          ? null
                                          : () => _ajouterMontant(objectif),
                                      icon: const Icon(Icons.add_circle_outline_rounded),
                                      label: Text(
                                        objectif.montantActuel >= objectif.objectif
                                            ? 'Objectif atteint'
                                            : 'Ajouter un montant',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEpargne,
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded, color: AppCouleurs.textePrincipal),
      ),
    );
  }
}

class _ChampMontantEpargne extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;

  const _ChampMontantEpargne({
    required this.label,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypographie.labelLarge
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.lg,
            vertical: AppEspaces.md,
          ),
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            border: Border.all(
              color: errorText != null
                  ? AppCouleurs.erreur
                  : AppCouleurs.textePrincipal.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypographie.titleSmall.copyWith(
                    fontFamily: 'ComicNeue',
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                Devise.symbole,
                style: AppTypographie.labelLarge
                    .copyWith(color: AppCouleurs.texteSecondaire),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTypographie.bodySmall.copyWith(color: AppCouleurs.erreur),
          ),
        ],
      ],
    );
  }
}
