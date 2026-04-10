import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/repositories.dart';
import '../../core/security/security_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/file_io_service.dart';
import '../../data/database/app_database.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/repetitif.dart';
import '../../data/models/transaction.dart';

class SettingsState {
  final bool securityEnabled;
  final bool pinSet;
  final bool biometricAvailable;
  final String appVersion;

  const SettingsState({
    this.securityEnabled = false,
    this.pinSet = false,
    this.biometricAvailable = false,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    bool? securityEnabled,
    bool? pinSet,
    bool? biometricAvailable,
  }) {
    return SettingsState(
      securityEnabled: securityEnabled ?? this.securityEnabled,
      pinSet: pinSet ?? this.pinSet,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      appVersion: appVersion,
    );
  }
}

class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    return _loadSettings();
  }

  Future<SettingsState> _loadSettings() async {
    final results = await Future.wait([
      SecurityService.instance.isSecurityEnabled(),
      SecurityService.instance.isPinSet(),
      SecurityService.instance.isBiometricAvailable(),
    ]);
    return SettingsState(
      securityEnabled: results[0],
      pinSet: results[1],
      biometricAvailable: results[2],
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadSettings);
  }

  Future<void> setSecurityEnabled(bool enabled) async {
    await SecurityService.instance.setSecurityEnabled(enabled);
    await refresh();
  }

  Future<void> clearPin() async {
    await SecurityService.instance.clearPin();
    await refresh();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
  }

  Future<void> exporterExcel({required int mois, required int annee}) async {
    final List<TransactionModele> transactions =
        await ref.read(repoTransactionProvider).obtenirParMois(mois, annee);
    final List<CategorieModele> categories =
        await ref.read(repoCategorieProvider).obtenirToutes();
    final List<BudgetModele> budgets =
        await ref.read(repoBudgetProvider).obtenirParMois(mois, annee);
    final List<ObjectifModele> objectifs =
        await ref.read(repoObjectifProvider).obtenirTous();
    final List<RecurrenceModele> recurrences = await ref
        .read(repoRepetitifProvider)
        .obtenirToutes(activesSeulement: false);

    final donneesExport = ExcelExportData(
      month: mois,
      year: annee,
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      goals: objectifs,
      recurring: recurrences,
    );

    final octets = ExcelService.instance.exporterVersExcel(donneesExport);
    final nomFichier = ExcelService.instance.nomFichierExcel(mois, annee);
    await FileIoService.instance.enregistrerEtPartager(
      nomFichier: nomFichier,
      octets: octets,
      typeMime:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sujet: 'Export BudgetFlow $mois/$annee',
      sousDossier: 'BudgetFlow/Export',
    );
  }

  Future<int> appliquerImportExcel(ExcelImportPreview apercu) async {
    // Charger les catégories existantes (nom → modèle) pour éviter les doublons.
    final categoriesExistantes =
        await ref.read(repoCategorieProvider).obtenirToutes();
    final categorieParNom = <String, CategorieModele>{
      for (final categorie in categoriesExistantes)
        categorie.name.toLowerCase(): categorie,
    };
    var totalImporte = 0;

    // Utilitaire : trouver ou créer une catégorie par nom.
    Future<CategorieModele?> trouverOuCreerCategorie(
      String nom,
      String type,
    ) async {
      if (nom.isEmpty) return null;
      final cle = nom.toLowerCase();
      if (categorieParNom.containsKey(cle)) return categorieParNom[cle];
      final nouvelleCategorie = CategorieModele.create(
        name: nom,
        icon: 'label',
        colorValue: 0xFF607D8B,
        type: type,
      );
      await ref.read(repoCategorieProvider).ajouter(nouvelleCategorie);
      categorieParNom[cle] = nouvelleCategorie;
      return nouvelleCategorie;
    }

    // Transactions
    for (final transactionMap in apercu.transactions) {
      final nomCategorie = (transactionMap['categorie'] as String?) ?? '';
      final typeTransaction = transactionMap['type'] as String? ?? 'expense';
      final categorie = await trouverOuCreerCategorie(
        nomCategorie,
        typeTransaction,
      );
      if (categorie == null) continue;

      // Analyser la date au format jj/mm/aaaa
      DateTime? dateTransaction;
      final dateTexte = transactionMap['date'] as String?;
      if (dateTexte != null && dateTexte.contains('/')) {
        final morceaux = dateTexte.split('/');
        if (morceaux.length == 3) {
          dateTransaction = DateTime.tryParse(
            '${morceaux[2]}-${morceaux[1].padLeft(2, '0')}-${morceaux[0].padLeft(2, '0')}',
          );
        }
      }

      final note = (transactionMap['note'] as String?) ?? '';
      final transaction = TransactionModele.create(
        title: (transactionMap['titre'] as String?) ?? '',
        amount: (transactionMap['montant'] as num? ?? 0).toDouble(),
        type: typeTransaction == 'income'
            ? TypeTransaction.income
            : TypeTransaction.expense,
        categoryId: categorie.id,
        note: note.isEmpty ? null : note,
        date: dateTransaction,
      );
      await ref.read(repoTransactionProvider).ajouter(transaction);
      totalImporte++;
    }

    // Budgets
    final maintenant = DateTime.now();
    for (final budgetMap in apercu.budgets) {
      final nomCategorie = (budgetMap['categorie'] as String?) ?? '';
      final categorie = await trouverOuCreerCategorie(nomCategorie, 'both');
      if (categorie == null) continue;
      final budget = BudgetModele.create(
        categoryId: categorie.id,
        amount: (budgetMap['montant'] as num? ?? 0).toDouble(),
        month: budgetMap['mois'] as int? ?? apercu.month ?? maintenant.month,
        year: budgetMap['annee'] as int? ?? apercu.year ?? maintenant.year,
      );
      await ref.read(repoBudgetProvider).ajouter(budget);
      totalImporte++;
    }

    // Objectifs
    for (final objectifMap in apercu.goals) {
      final objectif = ObjectifModele.create(
        name: (objectifMap['nom'] as String?) ?? '',
        targetAmount: (objectifMap['montant_cible'] as num? ?? 0).toDouble(),
        currentAmount: (objectifMap['montant_actuel'] as num? ?? 0).toDouble(),
        icon: 'flag',
        colorValue: 0xFF4CAF50,
      );
      await ref.read(repoObjectifProvider).ajouter(objectif);
      totalImporte++;
    }

    return totalImporte;
  }

  Future<ExcelImportPreview?> choisirEtPrevisualiserExcel() async {
    final fichierChoisi = await FileIoService.instance.choisirFichier(
      extensionsAutorisees: ['xlsx'],
    );
    if (fichierChoisi == null) return null;
    return ExcelService.instance.importerDepuisExcel(fichierChoisi.octets);
  }

  Future<void> exporterSauvegarde(String motDePasse) async {
    final db = AppDatabase.instance;
    final donnees = await BackupService.instance.lireToutesLesDonnees(db);
    final octets = await BackupService.instance.creerSauvegardeChiffree(
      donnees,
      motDePasse,
    );
    final nomFichier = BackupService.instance.nomFichierSauvegarde();
    await FileIoService.instance.enregistrerEtPartager(
      nomFichier: nomFichier,
      octets: octets,
      typeMime: 'application/octet-stream',
      sujet: 'Sauvegarde BudgetFlow',
    );
  }

  Future<MergeStats> importerEtFusionnerSauvegarde(String motDePasse) async {
    final fichierChoisi = await FileIoService.instance.choisirFichier(
      extensionsAutorisees: ['bfbackup'],
    );
    if (fichierChoisi == null) throw Exception('Aucun fichier sélectionné.');
    final db = AppDatabase.instance;
    final donnees = await BackupService.instance.dechiffrerSauvegarde(
      fichierChoisi.octets,
      motDePasse,
    );
    return BackupService.instance.fusionnerDansBase(db, donnees);
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
