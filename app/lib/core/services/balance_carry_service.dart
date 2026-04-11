import 'package:shared_preferences/shared_preferences.dart';

// Service de gestion du report de solde mensuel.
//
// - Le solde initial d'un mois peut être surchargé manuellement (stocké en local).
// - Si aucune surcharge n'est définie, le solde initial = solde de clôture du mois précédent.
// - Solde de clôture(mois) = soldeInitial(mois) + revenus(mois) - dépenses(mois).
//
// Les clés SharedPreferences sont préfixées par [userId] pour garantir l'isolation
// entre plusieurs utilisateurs sur le même appareil.
class BalanceCarryService {
  static const String _prefix = 'balance_override_';

  // Identifiant de l'utilisateur courant (null = utilisateur anonyme).
  final String? userId;

  BalanceCarryService(this.userId);

  // Clé SharedPreferences pour un mois donné, isolée par utilisateur.
  String _key(int month, int year) {
    final userPrefix = userId != null ? '${userId}_' : '';
    return '$userPrefix$_prefix${year}_$month';
  }

  // Retourne la surcharge manuelle du solde initial pour un mois donné,
  // ou `null` si aucune surcharge n'a été définie.
  Future<double?> getOverride(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_key(month, year));
    return value;
  }

  // Enregistre une surcharge manuelle du solde initial pour un mois donné.
  Future<void> setOverride(int month, int year, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key(month, year), value);
  }

  // Supprime la surcharge manuelle pour un mois donné
  // (revient au calcul automatique via report).
  Future<void> removeOverride(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(month, year));
  }

  // Calcule le solde initial d'un mois :
  //   - surcharge manuelle si présente
  //   - sinon solde de clôture du mois précédent (via callback)
  //
  // [getPreviousClosing] est une fonction asynchrone qui renvoie le solde de
  // clôture du mois précédent (revenus - dépenses + solde initial précédent).
  Future<double> computeStartingBalance({
    required int month,
    required int year,
    required Future<double> Function(int month, int year) getPreviousClosing,
  }) async {
    final override = await getOverride(month, year);
    if (override != null) return override;

    final prevDate =
        month == 1 ? DateTime(year - 1, 12) : DateTime(year, month - 1);
    return getPreviousClosing(prevDate.month, prevDate.year);
  }
}
