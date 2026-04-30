import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budgets/presentation/views/ecran_ajout_budget.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_budgets.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/utils/depot_transactions.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';
import '../../../transactions/shared/widgets/champs_transaction.dart';

const _cleMembres = 'membres_budgetflow';
const _cleMoyensPaiement = 'moyens_paiement';

class EcranDetailTransaction extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EcranDetailTransaction({super.key, required this.transaction});

  @override
  ConsumerState<EcranDetailTransaction> createState() =>
      _EtatEcranDetailTransaction();
}

class _EtatEcranDetailTransaction
    extends ConsumerState<EcranDetailTransaction> {
  late Transaction _transaction;
  bool _enModification = false;

  // Contrôleurs de modification
  late TextEditingController _controleurTitre;
  late TextEditingController _controleurMontant;
  late TextEditingController _controleurNote;
  late TypeTransaction _typeSelectionne;
  late DateTime _dateSelectionnee;
  late List<String> _cheminImages;
  late List<String> _membreIdsSelectionnes;
  String? _moyenPaiementIdSelectionne;
  Categorie? _categorieSelectionnee;
  List<Categorie> _categoriesDisponibles = [];
  List<EntiteSimple> _membresDisponibles = [];
  List<EntiteSimple> _moyensPaiementDisponibles = [];
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _controleurTitre = TextEditingController(text: _transaction.titre);
    _controleurMontant =
        TextEditingController(text: _transaction.montant.toStringAsFixed(0));
    _controleurNote = TextEditingController(text: _transaction.note ?? '');
    _typeSelectionne = _transaction.type;
    _dateSelectionnee = _transaction.date;
    _cheminImages = [..._transaction.cheminImages];
    _membreIdsSelectionnes = [..._transaction.membreIds];
    _moyenPaiementIdSelectionne = _transaction.moyenPaiementId;
    _categorieSelectionnee = _transaction.categorie;
    _chargerCategories();
    _chargerMembres();
    _chargerMoyensPaiement();
  }

  Future<void> _chargerCategories() async {
    final cats = await DepotCategories.instance.lireParType(_typeSelectionne);
    if (!mounted) return;
    setState(() {
      _categoriesDisponibles = cats;
      if (_categorieSelectionnee == null ||
          !_categoriesDisponibles.contains(_categorieSelectionnee)) {
        _categorieSelectionnee = _categoriesDisponibles.isNotEmpty
            ? _categoriesDisponibles.first
            : null;
      }
    });
  }

  Future<void> _chargerMembres() async {
    final membres = await DepotEntitesSimples.instance.lireTous(_cleMembres);
    if (!mounted) return;
    setState(() => _membresDisponibles = membres);
  }

  Future<void> _chargerMoyensPaiement() async {
    final moyensPaiement =
        await DepotEntitesSimples.instance.lireTous(_cleMoyensPaiement);
    if (!mounted) return;
    setState(() => _moyensPaiementDisponibles = moyensPaiement);
  }

  @override
  void dispose() {
    _controleurTitre.dispose();
    _controleurMontant.dispose();
    _controleurNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: _enModification ? 'Modifier' : 'Détail',
        actions: [
          if (!_enModification)
            IconButton(
              onPressed: () => setState(() => _enModification = true),
              icon: const Icon(Icons.edit_outlined,
                  color: AppCouleurs.accentBrun, size: 20),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: _enModification
            ? _ContenuModification(
                transaction: _transaction,
                controleurTitre: _controleurTitre,
                controleurMontant: _controleurMontant,
                controleurNote: _controleurNote,
                typeSelectionne: _typeSelectionne,
                dateSelectionnee: _dateSelectionnee,
                cheminsImages: _cheminImages,
                membresDisponibles: _membresDisponibles,
                moyensPaiementDisponibles: _moyensPaiementDisponibles,
                membreIdsSelectionnes: _membreIdsSelectionnes,
                moyenPaiementIdSelectionne: _moyenPaiementIdSelectionne,
                categorieSelectionnee: _categorieSelectionnee,
                categoriesDisponibles: _categoriesDisponibles,
                onTypeChange: (t) async {
                  _typeSelectionne = t;
                  await _chargerCategories();
                },
                onAjouterImage: _ajouterImage,
                onSupprimerImage: (i) =>
                    setState(() => _cheminImages.removeAt(i)),
                onToggleMembre: (id) => setState(() {
                  if (_membreIdsSelectionnes.contains(id)) {
                    _membreIdsSelectionnes.remove(id);
                  } else {
                    _membreIdsSelectionnes.add(id);
                  }
                }),
                onMoyenPaiementChoisi: (id) =>
                    setState(() => _moyenPaiementIdSelectionne = id),
                onCategorieChoisie: (c) =>
                    setState(() => _categorieSelectionnee = c),
                onDateChange: (d) => setState(() => _dateSelectionnee = d),
                onEnregistrer: _enregistrer,
                onAnnuler: () => setState(() => _enModification = false),
              )
            : _ContenuDetail(
                transaction: _transaction,
                membresRattaches: _membresDisponibles
                    .where((m) => _transaction.membreIds.contains(m.id))
                    .map((m) => m.nom)
                    .toList(),
                moyenPaiementNom: _moyensPaiementDisponibles
                    .where((m) => m.id == _transaction.moyenPaiementId)
                    .map((m) => m.nom)
                    .cast<String?>()
                    .firstWhere((_) => true, orElse: () => null),
              ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    final montant =
        double.tryParse(_controleurMontant.text.replaceAll(',', '.'));
    if (montant == null || _categorieSelectionnee == null) return;

    final updated = Transaction(
      id: _transaction.id,
      titre: _controleurTitre.text.trim(),
      montant: montant,
      type: _typeSelectionne,
      categorie: _categorieSelectionnee!,
      date: _dateSelectionnee,
      note: _controleurNote.text.trim().isEmpty
          ? null
          : _controleurNote.text.trim(),
      cheminImages: _cheminImages,
      membreIds: _membreIdsSelectionnes,
      moyenPaiementId: _moyenPaiementIdSelectionne,
    );

    if (updated.type == TypeTransaction.depense) {
      final budgetNouveau =
          await DepotBudgets.instance.lireParCategorie(updated.categorie.id);
      if (budgetNouveau != null) {
        final depenseProjetee = budgetNouveau.montantDepense +
            updated.montant -
            (_transaction.type == TypeTransaction.depense &&
                    _transaction.categorie.id == updated.categorie.id
                ? _transaction.montant
                : 0);
        if (depenseProjetee > budgetNouveau.montantTotal) {
          if (!mounted) return;
          final veutModifier = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Budget épuisé'),
              content: Text(
                  'Le budget "${budgetNouveau.categorieNom}" est insuffisant. Voulez-vous le modifier ?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Non')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Oui')),
              ],
            ),
          );
          if (veutModifier == true && mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EcranAjoutBudget(budgetExistant: budgetNouveau),
            ));
          }
          return;
        }
      }
    }

    await DepotTransactions.instance.mettre_a_jour(updated);
    if (_transaction.type == TypeTransaction.depense) {
      await DepotBudgets.instance.retirerDepense(
        categorieId: _transaction.categorie.id,
        montant: _transaction.montant,
      );
    }
    if (updated.type == TypeTransaction.depense) {
      await DepotBudgets.instance.ajouterDepense(
        categorieId: updated.categorie.id,
        montant: updated.montant,
      );
    }
    invalidaterTransactions(ref);

    setState(() {
      _transaction = updated;
      _enModification = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction mise à jour'),
          backgroundColor: AppCouleurs.succes,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRayons.sm)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _ajouterImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppCouleurs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppCouleurs.primaire),
              title:
                  Text('Prendre une photo', style: AppTypographie.bodyMedium),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppCouleurs.primaire),
              title: Text('Galerie', style: AppTypographie.bodyMedium),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final image =
        await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _cheminImages = [..._cheminImages, image.path]);
    }
  }

}

// ─── Vue détail (lecture) ─────────────────────────────────────────────────────

class _ContenuDetail extends StatelessWidget {
  final Transaction transaction;
  final List<String> membresRattaches;
  final String? moyenPaiementNom;
  const _ContenuDetail({
    required this.transaction,
    this.membresRattaches = const [],
    this.moyenPaiementNom,
  });

  @override
  Widget build(BuildContext context) {
    final estDepense = transaction.type == TypeTransaction.depense;

    return Column(
      children: [
        // ── Montant en grand ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppEspaces.xl),
          decoration: BoxDecoration(
            color: AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.lg),
            boxShadow: [
              BoxShadow(
                  color: AppCouleurs.textePrincipal.withOpacity(0.06),
                  blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: transaction.categorie.couleur.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(transaction.categorie.icone,
                    color: transaction.categorie.couleur, size: 28),
              ),
              const SizedBox(height: AppEspaces.md),
              Text(
                transaction.titre,
                style: AppTypographie.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${estDepense ? '-' : '+'}${Devise.formater(transaction.montant)}',
                style: AppTypographie.headlineMedium.copyWith(
                  fontFamily: 'ComicNeue',
                  color: estDepense ? AppCouleurs.erreur : AppCouleurs.succes,
                ),
              ),
              const SizedBox(height: AppEspaces.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (estDepense ? AppCouleurs.erreur : AppCouleurs.succes)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.type.libelle,
                  style: AppTypographie.labelSmall.copyWith(
                    color: estDepense ? AppCouleurs.erreur : AppCouleurs.succes,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppEspaces.lg),

        // ── Infos complémentaires ─────────────────────────────────────
        _GroupeInfos(lignes: [
          _LigneInfo(label: 'Catégorie', valeur: transaction.categorie.nom),
          _LigneInfo(
            label: 'Date',
            valeur:
                '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}',
          ),
          if (membresRattaches.isNotEmpty)
            _LigneInfo(label: 'Membres', valeur: membresRattaches.join(', ')),
          if (moyenPaiementNom != null && moyenPaiementNom!.isNotEmpty)
            _LigneInfo(label: 'Moyen de paiement', valeur: moyenPaiementNom!),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            _LigneInfo(label: 'Note', valeur: transaction.note!),
        ]),

        // ── Images ────────────────────────────────────────────────────
        if (transaction.cheminImages.isNotEmpty) ...[
          const SizedBox(height: AppEspaces.lg),
          _GalerieImages(chemins: transaction.cheminImages),
        ],
      ],
    );
  }
}

class _GroupeInfos extends StatelessWidget {
  final List<_LigneInfo> lignes;
  const _GroupeInfos({required this.lignes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
              color: AppCouleurs.textePrincipal.withOpacity(0.05),
              blurRadius: 8)
        ],
      ),
      child: Column(
        children: List.generate(lignes.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
                height: 1,
                color: AppCouleurs.textePrincipal.withOpacity(0.06),
                indent: 16);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppEspaces.md, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lignes[i ~/ 2].label,
                    style: AppTypographie.bodySmall
                        .copyWith(color: AppCouleurs.texteSecondaire)),
                Flexible(
                  child: Text(lignes[i ~/ 2].valeur,
                      style: AppTypographie.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LigneInfo {
  final String label;
  final String valeur;
  const _LigneInfo({required this.label, required this.valeur});
}

class _GalerieImages extends StatelessWidget {
  final List<String> chemins;
  const _GalerieImages({required this.chemins});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pièces jointes', style: AppTypographie.titleSmall),
        const SizedBox(height: AppEspaces.sm),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chemins.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRayons.sm),
              child: Image.file(File(chemins[i]),
                  width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Vue modification ─────────────────────────────────────────────────────────

class _ContenuModification extends StatelessWidget {
  final Transaction transaction;
  final TextEditingController controleurTitre;
  final TextEditingController controleurMontant;
  final TextEditingController controleurNote;
  final TypeTransaction typeSelectionne;
  final DateTime dateSelectionnee;
  final List<String> cheminsImages;
  final List<EntiteSimple> membresDisponibles;
  final List<EntiteSimple> moyensPaiementDisponibles;
  final List<String> membreIdsSelectionnes;
  final String? moyenPaiementIdSelectionne;
  final Categorie? categorieSelectionnee;
  final List<Categorie> categoriesDisponibles;
  final ValueChanged<TypeTransaction> onTypeChange;
  final VoidCallback onAjouterImage;
  final ValueChanged<int> onSupprimerImage;
  final ValueChanged<String> onToggleMembre;
  final ValueChanged<String?> onMoyenPaiementChoisi;
  final ValueChanged<Categorie> onCategorieChoisie;
  final ValueChanged<DateTime> onDateChange;
  final VoidCallback onEnregistrer;
  final VoidCallback onAnnuler;

  const _ContenuModification({
    required this.transaction,
    required this.controleurTitre,
    required this.controleurMontant,
    required this.controleurNote,
    required this.typeSelectionne,
    required this.dateSelectionnee,
    required this.cheminsImages,
    required this.membresDisponibles,
    required this.moyensPaiementDisponibles,
    required this.membreIdsSelectionnes,
    required this.moyenPaiementIdSelectionne,
    required this.categorieSelectionnee,
    required this.categoriesDisponibles,
    required this.onTypeChange,
    required this.onAjouterImage,
    required this.onSupprimerImage,
    required this.onToggleMembre,
    required this.onMoyenPaiementChoisi,
    required this.onCategorieChoisie,
    required this.onDateChange,
    required this.onEnregistrer,
    required this.onAnnuler,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelecteurTypeTransaction(typeActuel: typeSelectionne, onChanged: onTypeChange),
        const SizedBox(height: AppEspaces.lg),
        SaisieMontantTransaction(
          controleur: controleurMontant,
          type: typeSelectionne,
        ),
        const SizedBox(height: AppEspaces.lg),
        ChampFormulaire(
          label: 'Description',
          placeholder: 'Ex: Courses marché',
          controleur: controleurTitre,
        ),
        const SizedBox(height: AppEspaces.md),

        SelecteurCategorieTransaction(
          categories: categoriesDisponibles,
          selectionActuelle: categorieSelectionnee,
          onSelectionne: onCategorieChoisie,
        ),

        const SizedBox(height: AppEspaces.md),
        ChampDateTransaction(date: dateSelectionnee, onChanged: onDateChange),
        const SizedBox(height: AppEspaces.md),
        SelecteurMembresTransaction(
          membres: membresDisponibles,
          membreIdsSelectionnes: membreIdsSelectionnes,
          onToggle: onToggleMembre,
        ),
        const SizedBox(height: AppEspaces.md),
        SelecteurMoyenPaiementTransaction(
          moyensPaiement: moyensPaiementDisponibles,
          moyenPaiementIdSelectionne: moyenPaiementIdSelectionne,
          onChanged: onMoyenPaiementChoisi,
        ),
        const SizedBox(height: AppEspaces.md),
        ChampFormulaire(
          label: 'Note (optionnel)',
          placeholder: 'Ajoutez une note...',
          controleur: controleurNote,
          maxLignes: 2,
        ),
        const SizedBox(height: AppEspaces.md),
        SectionImagesTransaction(
          chemins: cheminsImages,
          onAjouter: onAjouterImage,
          onSupprimer: onSupprimerImage,
        ),
        const SizedBox(height: AppEspaces.xl),

        BoutonPrimaire(libelle: 'Enregistrer', onPress: onEnregistrer),
        const SizedBox(height: AppEspaces.sm),
        TextButton(
          onPressed: onAnnuler,
          child: Text('Annuler',
              style: AppTypographie.labelLarge
                  .copyWith(color: AppCouleurs.texteSecondaire)),
        ),
      ],
    );
  }
}

