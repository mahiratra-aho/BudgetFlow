import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/local_auth_service.dart';
import '../../core/providers/repositories.dart';
import '../../core/security/security_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/file_io_service.dart';
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
    final user = await LocalAuthService.instance.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final key = user != null ? 'onboarding_done_${user.id}' : 'onboarding_done';
    await prefs.setBool(key, false);
  }

  Future<void> exportExcel({required int month, required int year}) async {
    final List<TransactionModele> transactions =
        await ref.read(repoTransactionProvider).obtenirParMois(month, year);
    final List<CategorieModele> categories =
        await ref.read(repoCategorieProvider).obtenirToutes();
    final List<BudgetModele> budgets =
        await ref.read(repoBudgetProvider).obtenirParMois(month, year);
    final List<ObjectifModele> goals =
        await ref.read(repoObjectifProvider).obtenirTous();
    final List<RecurrenceModele> recurring =
        await ref.read(repoRepetitifProvider).obtenirToutes(activesSeulement: false);

    final data = ExcelExportData(
      month: month,
      year: year,
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      goals: goals,
      recurring: recurring,
    );

    final bytes = ExcelService.instance.exportToExcel(data);
    final fileName = ExcelService.instance.excelFileName(month, year);
    await FileIoService.instance.saveAndShare(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'Export BudgetFlow $month/$year',
      subDirectory: 'BudgetFlow/Export',
    );
  }

  Future<int> applyExcelImport(ExcelImportPreview preview) async {
    // Charger les catégories existantes (nom → modèle) pour éviter les doublons.
    final existingCats = await ref.read(repoCategorieProvider).obtenirToutes();
    final catByName = <String, CategorieModele>{
      for (final c in existingCats) c.name.toLowerCase(): c,
    };
    var count = 0;

    // Utilitaire : trouver ou créer une catégorie par nom.
    Future<CategorieModele?> findOrCreateCategory(
        String name, String type) async {
      if (name.isEmpty) return null;
      final key = name.toLowerCase();
      if (catByName.containsKey(key)) return catByName[key];
      final newCat = CategorieModele.create(
        name: name,
        icon: 'label',
        colorValue: 0xFF607D8B,
        type: type,
      );
      await ref.read(repoCategorieProvider).ajouter(newCat);
      catByName[key] = newCat;
      return newCat;
    }

    // Transactions
    for (final t in preview.transactions) {
      final catName = (t['categorie'] as String?) ?? '';
      final typeStr = t['type'] as String? ?? 'expense';
      final cat = await findOrCreateCategory(catName, typeStr);
      if (cat == null) continue;

      // Analyser la date au format jj/mm/aaaa
      DateTime? date;
      final dateStr = t['date'] as String?;
      if (dateStr != null && dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime.tryParse(
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
          );
        }
      }

      final note = (t['note'] as String?) ?? '';
      final transaction = TransactionModele.create(
        title: (t['titre'] as String?) ?? '',
        amount: (t['montant'] as num? ?? 0).toDouble(),
        type: typeStr == 'income'
            ? TypeTransaction.income
            : TypeTransaction.expense,
        categoryId: cat.id,
        note: note.isEmpty ? null : note,
        date: date,
      );
      await ref.read(repoTransactionProvider).ajouter(transaction);
      count++;
    }

    // Budgets
    final now = DateTime.now();
    for (final b in preview.budgets) {
      final catName = (b['categorie'] as String?) ?? '';
      final cat = await findOrCreateCategory(catName, 'both');
      if (cat == null) continue;
      final budget = BudgetModele.create(
        categoryId: cat.id,
        amount: (b['montant'] as num? ?? 0).toDouble(),
        month: b['mois'] as int? ?? preview.month ?? now.month,
        year: b['annee'] as int? ?? preview.year ?? now.year,
      );
      await ref.read(repoBudgetProvider).ajouter(budget);
      count++;
    }

    // Objectifs
    for (final g in preview.goals) {
      final goal = ObjectifModele.create(
        name: (g['nom'] as String?) ?? '',
        targetAmount: (g['montant_cible'] as num? ?? 0).toDouble(),
        currentAmount: (g['montant_actuel'] as num? ?? 0).toDouble(),
        icon: 'flag',
        colorValue: 0xFF4CAF50,
      );
      await ref.read(repoObjectifProvider).ajouter(goal);
      count++;
    }

    return count;
  }

  Future<ExcelImportPreview?> pickAndPreviewExcel() async {
    final picked = await FileIoService.instance.pickFile(extensions: ['xlsx']);
    if (picked == null) return null;
    return ExcelService.instance.importFromExcel(picked.bytes);
  }

  Future<void> exportBackup(String password) async {
    final db = ref.read(appDatabaseProvider);
    final payload = await BackupService.instance.readAllData(db);
    final bytes = await BackupService.instance.createEncryptedBackup(payload, password);
    final fileName = BackupService.instance.backupFileName();
    await FileIoService.instance.saveAndShare(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/octet-stream',
      subject: 'Sauvegarde BudgetFlow',
    );
  }

  Future<MergeStats> importAndMergeBackup(String password) async {
    final picked = await FileIoService.instance.pickFile(extensions: ['bfbackup']);
    if (picked == null) throw Exception('Aucun fichier sélectionné.');
    final db = ref.read(appDatabaseProvider);
    final payload = await BackupService.instance.decryptBackup(picked.bytes, password);
    return BackupService.instance.mergeIntoDatabase(db, payload);
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
