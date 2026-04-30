import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../budgets/presentation/views/ecran_ajout_budget.dart';
import '../../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../../shared/utils/depot_budgets.dart';
import '../../../../shared/utils/depot_categories.dart';
import '../../../../shared/utils/depot_entites_simples.dart';
import '../../../../shared/utils/depot_transactions.dart';
import '../../../../shared/utils/modeles.dart';
import '../../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../../shared/widgets/champ_formulaire.dart';
import '../../../shared/widgets/champs_transaction.dart';

const _cleMembres = 'membres_budgetflow';
const _cleMoyensPaiement = 'moyens_paiement';

class _EtatAjout {
  final TypeTransaction type;
  final Categorie? categorie;
  final DateTime date;
  final List<String> cheminImages;
  final List<String> membreIds;
  final String? moyenPaiementId;

  _EtatAjout({
    this.type = TypeTransaction.depense,
    this.categorie,
    DateTime? date,
    this.cheminImages = const [],
    this.membreIds = const [],
    this.moyenPaiementId,
  }) : date = date ?? DateTime.now();

  _EtatAjout copyWith({
    TypeTransaction? type,
    Categorie? categorie,
    DateTime? date,
    List<String>? cheminImages,
    List<String>? membreIds,
    String? moyenPaiementId,
  }) =>
      _EtatAjout(
        type: type ?? this.type,
        categorie: categorie,
        date: date ?? this.date,
        cheminImages: cheminImages ?? this.cheminImages,
        membreIds: membreIds ?? this.membreIds,
        moyenPaiementId: moyenPaiementId ?? this.moyenPaiementId,
      );
}

class _AjoutNotifier extends StateNotifier<_EtatAjout> {
  _AjoutNotifier() : super(_EtatAjout());

  void changerType(TypeTransaction type) {
    state = state.copyWith(type: type, categorie: null);
  }

  void changerCategorie(Categorie c) {
    state = _EtatAjout(
      type: state.type,
      categorie: c,
      date: state.date,
      cheminImages: state.cheminImages,
      membreIds: state.membreIds,
      moyenPaiementId: state.moyenPaiementId,
    );
  }

  void changerDate(DateTime d) {
    state = _EtatAjout(
      type: state.type,
      categorie: state.categorie,
      date: d,
      cheminImages: state.cheminImages,
      membreIds: state.membreIds,
      moyenPaiementId: state.moyenPaiementId,
    );
  }

  void ajouterImage(String chemin) {
    state = _EtatAjout(
      type: state.type,
      categorie: state.categorie,
      date: state.date,
      cheminImages: [...state.cheminImages, chemin],
      membreIds: state.membreIds,
      moyenPaiementId: state.moyenPaiementId,
    );
  }

  void supprimerImage(int index) {
    final imgs = [...state.cheminImages]..removeAt(index);
    state = _EtatAjout(
      type: state.type,
      categorie: state.categorie,
      date: state.date,
      cheminImages: imgs,
      membreIds: state.membreIds,
      moyenPaiementId: state.moyenPaiementId,
    );
  }

  void basculerMembre(String id) {
    final ids = [...state.membreIds];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(membreIds: ids);
  }

  void changerMoyenPaiement(String? id) {
    state = state.copyWith(moyenPaiementId: id);
  }
}

final _ajoutProvider =
    StateNotifierProvider.autoDispose<_AjoutNotifier, _EtatAjout>(
        (_) => _AjoutNotifier());

class EcranAjoutTransaction extends ConsumerStatefulWidget {
  const EcranAjoutTransaction({super.key});

  @override
  ConsumerState<EcranAjoutTransaction> createState() =>
      _EtatEcranAjoutTransaction();
}

class _EtatEcranAjoutTransaction extends ConsumerState<EcranAjoutTransaction> {
  final _controleurMontant = TextEditingController();
  final _controleurTitre = TextEditingController();
  final _controleurNote = TextEditingController();
  final _imagePicker = ImagePicker();

  List<Categorie> _categoriesDisponibles = [];
  List<EntiteSimple> _membresDisponibles = [];
  List<EntiteSimple> _moyensPaiementDisponibles = [];
  bool _enChargement = false;

  @override
  void initState() {
    super.initState();
    _chargerCategories(TypeTransaction.depense);
    _chargerMembres();
    _chargerMoyensPaiement();
  }

  Future<void> _chargerCategories(TypeTransaction type) async {
    final cats = await DepotCategories.instance.lireParType(type);
    if (mounted) setState(() => _categoriesDisponibles = cats);
  }

  Future<void> _chargerMembres() async {
    final membres = await DepotEntitesSimples.instance.lireTous(_cleMembres);
    if (mounted) setState(() => _membresDisponibles = membres);
  }

  Future<void> _chargerMoyensPaiement() async {
    final moyensPaiement =
        await DepotEntitesSimples.instance.lireTous(_cleMoyensPaiement);
    if (mounted) setState(() => _moyensPaiementDisponibles = moyensPaiement);
  }

  @override
  void dispose() {
    _controleurMontant.dispose();
    _controleurTitre.dispose();
    _controleurNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(_ajoutProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Nouvelle transaction'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppEspaces.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelecteurTypeTransaction(
                typeActuel: etat.type,
                onChanged: (t) {
                  ref.read(_ajoutProvider.notifier).changerType(t);
                  _chargerCategories(t);
                },
              ),

              const SizedBox(height: AppEspaces.xl),

              SaisieMontantTransaction(
                controleur: _controleurMontant,
                type: etat.type,
              ),

              const SizedBox(height: AppEspaces.lg),

              ChampFormulaire(
                label: 'Description',
                placeholder: 'Ex: Courses marché',
                controleur: _controleurTitre,
              ),

              const SizedBox(height: AppEspaces.lg),

              SelecteurCategorieTransaction(
                categories: _categoriesDisponibles,
                selectionActuelle: etat.categorie,
                onSelectionne: (c) =>
                    ref.read(_ajoutProvider.notifier).changerCategorie(c),
              ),

              const SizedBox(height: AppEspaces.lg),

              ChampDateTransaction(
                date: etat.date,
                onChanged: (d) =>
                    ref.read(_ajoutProvider.notifier).changerDate(d),
              ),

              const SizedBox(height: AppEspaces.lg),

              SelecteurMembresTransaction(
                membres: _membresDisponibles,
                membreIdsSelectionnes: etat.membreIds,
                onToggle: (id) =>
                    ref.read(_ajoutProvider.notifier).basculerMembre(id),
              ),

              const SizedBox(height: AppEspaces.lg),

              SelecteurMoyenPaiementTransaction(
                moyensPaiement: _moyensPaiementDisponibles,
                moyenPaiementIdSelectionne: etat.moyenPaiementId,
                onChanged: (id) =>
                    ref.read(_ajoutProvider.notifier).changerMoyenPaiement(id),
              ),

              const SizedBox(height: AppEspaces.lg),

              ChampFormulaire(
                label: 'Note (optionnel)',
                placeholder: 'Ajoutez une note...',
                controleur: _controleurNote,
                maxLignes: 2,
              ),

              const SizedBox(height: AppEspaces.lg),

              SectionImagesTransaction(
                chemins: etat.cheminImages,
                onAjouter: _ajouterImage,
                onSupprimer: (i) =>
                    ref.read(_ajoutProvider.notifier).supprimerImage(i),
              ),

              const SizedBox(height: AppEspaces.xl),

              BoutonPrimaire(
                libelle: 'Enregistrer',
                estChargement: _enChargement,
                onPress: _enregistrer,
              ),

              const SizedBox(height: AppEspaces.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ajouterImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppCouleurs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      ref.read(_ajoutProvider.notifier).ajouterImage(image.path);
    }
  }

  Future<void> _enregistrer() async {
    final etat = ref.read(_ajoutProvider);
    final montantTexte = _controleurMontant.text.replaceAll(',', '.');
    final montant = double.tryParse(montantTexte);

    if (montant == null || montant <= 0) {
      _snack('Veuillez saisir un montant valide');
      return;
    }
    if (_controleurTitre.text.trim().isEmpty) {
      _snack('Veuillez saisir une description');
      return;
    }
    if (etat.categorie == null) {
      _snack('Veuillez choisir une catégorie');
      return;
    }

    if (etat.type == TypeTransaction.depense) {
      final budget = await DepotBudgets.instance.lireParCategorie(etat.categorie!.id);
      if (budget != null) {
        final depenseApres = budget.montantDepense + montant;
        if (depenseApres > budget.montantTotal) {
          if (!mounted) return;
          final veutModifier = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Budget épuisé'),
              content: Text(
                'Le budget "${budget.categorieNom}" est insuffisant. Voulez-vous le modifier ?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
              ],
            ),
          );
          if (veutModifier == true && mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EcranAjoutBudget(budgetExistant: budget),
            ));
          }
          return;
        }
      }
    }

    setState(() => _enChargement = true);

    try {
      await DepotTransactions.instance.inserer(
        titre: _controleurTitre.text.trim(),
        montant: montant,
        type: etat.type,
        categorie: etat.categorie!,
        date: ref.read(_ajoutProvider).date,
        note: _controleurNote.text.trim().isEmpty
            ? null
            : _controleurNote.text.trim(),
        cheminImages: etat.cheminImages,
        membreIds: etat.membreIds,
        moyenPaiementId: etat.moyenPaiementId,
      );

      if (etat.type == TypeTransaction.depense) {
        await DepotBudgets.instance.ajouterDepense(
          categorieId: etat.categorie!.id,
          montant: montant,
        );
      }

      invalidaterTransactions(ref);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack('Erreur lors de l\'enregistrement');
    } finally {
      if (mounted) setState(() => _enChargement = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppCouleurs.erreur,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.sm)),
    ));
  }
}


