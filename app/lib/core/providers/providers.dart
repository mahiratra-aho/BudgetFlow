import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/service_synchronisation_donnees.dart';
import '../../features/shared/utils/depot_categories.dart';
import '../../features/shared/utils/depot_transactions.dart';
import '../../features/shared/utils/modeles.dart';
import '../constants/constantes_app.dart';

class UtilisateurNotifier extends Notifier<UtilisateurLocal> {
  @override
  UtilisateurLocal build() => UtilisateurLocal.anonyme;

  Future<void> initialiserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ConstantesApp.cleUtilisateurLocal);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final uid = map['uid'] as String?;
      final nom = map['nomAffiche'] as String?;
      if (uid == null || uid.isEmpty || nom == null || nom.isEmpty) return;
      state = UtilisateurLocal(uid: uid, nomAffiche: nom);
    } catch (_) {
      await prefs.remove(ConstantesApp.cleUtilisateurLocal);
    }
  }

  Future<void> connecter(String uid, String nom) async {
    await ServiceSynchronisationDonnees.instance.connecterCompte(uid);
    await DepotCategories.instance.initialiserParDefaut();
    state = UtilisateurLocal(uid: uid, nomAffiche: nom);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ConstantesApp.cleUtilisateurLocal,
      jsonEncode({'uid': uid, 'nomAffiche': nom}),
    );
  }

  Future<void> deconnecter() async {
    if (state.uid != null) {
      await ServiceSynchronisationDonnees.instance.sauvegarderCompte(state.uid!);
    }
    await ServiceSynchronisationDonnees.instance.viderDonneesLocales();
    state = UtilisateurLocal.anonyme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ConstantesApp.cleUtilisateurLocal);
  }

  void mettreAJourNom(String nom) {
    state = UtilisateurLocal(uid: state.uid, nomAffiche: nom);
  }
}

final utilisateurProvider =
    NotifierProvider<UtilisateurNotifier, UtilisateurLocal>(
  UtilisateurNotifier.new,
);

final sessionInitialiseeProvider = FutureProvider<void>((ref) async {
  await ref.read(utilisateurProvider.notifier).initialiserSession();
});

class MoisNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  void changerMois(DateTime mois) {
    state = DateTime(mois.year, mois.month);
  }

  void moisPrecedent() {
    state = DateTime(state.year, state.month - 1);
  }

  void moisSuivant() {
    if (state.isBefore(DateTime(DateTime.now().year, DateTime.now().month))) {
      state = DateTime(state.year, state.month + 1);
    }
  }
}

final moisSelectionneProvider = NotifierProvider<MoisNotifier, DateTime>(
  MoisNotifier.new,
);

final transactionsDuMoisProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final mois = ref.watch(moisSelectionneProvider);
  ref.watch(transactionsInvalidateurProvider);
  return DepotTransactions.instance.lireParMois(mois.year, mois.month);
});

class ResumeAccueilDonnees {
  final List<Transaction> dernieresTransactions;
  final double totalRevenus;
  final double totalDepenses;

  const ResumeAccueilDonnees({
    required this.dernieresTransactions,
    required this.totalRevenus,
    required this.totalDepenses,
  });
}

final resumeAccueilProvider =
    FutureProvider.autoDispose<ResumeAccueilDonnees>((ref) async {
  final transactions = await ref.watch(transactionsDuMoisProvider.future);

  double revenus = 0;
  double depenses = 0;
  for (final t in transactions) {
    if (t.type == TypeTransaction.revenu) {
      revenus += t.montant;
    } else {
      depenses += t.montant;
    }
  }

  return ResumeAccueilDonnees(
    dernieresTransactions: transactions.take(5).toList(),
    totalRevenus: revenus,
    totalDepenses: depenses,
  );
});

final dernieresTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final mois = ref.watch(moisSelectionneProvider);
  ref.watch(transactionsInvalidateurProvider);
  return DepotTransactions.instance.lireDernieres(mois.year, mois.month);
});

final transactionsInvalidateurProvider = StateProvider<int>((ref) => 0);

void invalidaterTransactions(WidgetRef ref) {
  ref.read(transactionsInvalidateurProvider.notifier).state++;
}

final totalRevenusMoisProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final mois = ref.watch(moisSelectionneProvider);
  ref.watch(transactionsInvalidateurProvider);
  return DepotTransactions.instance
      .totalParType(TypeTransaction.revenu, mois.year, mois.month);
});

final totalDepensesMoisProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final mois = ref.watch(moisSelectionneProvider);
  ref.watch(transactionsInvalidateurProvider);
  return DepotTransactions.instance
      .totalParType(TypeTransaction.depense, mois.year, mois.month);
});

final categoriesDepensesProvider =
    FutureProvider.autoDispose<List<Categorie>>((ref) async {
  return DepotCategories.instance.lireParType(TypeTransaction.depense);
});

final categoriesRevenusProvider =
    FutureProvider.autoDispose<List<Categorie>>((ref) async {
  return DepotCategories.instance.lireParType(TypeTransaction.revenu);
});

final onboardingVuProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(ConstantesApp.cleOnboardingVu) ?? false;
});

Future<void> marquerOnboardingVu() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(ConstantesApp.cleOnboardingVu, true);
}

