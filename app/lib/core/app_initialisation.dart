import 'crypto/service_chiffrement.dart';
import 'database/service_base_de_donnees.dart';
import 'utils/localisation.dart';
import '../../features/shared/utils/depot_categories.dart';

class ServiceInitialisationApp {
  ServiceInitialisationApp._();
  static final ServiceInitialisationApp instance = ServiceInitialisationApp._();

  Future<void>? _futureCritique;
  Future<void>? _futureSecondaire;

  Future<void> demarrer() {
    return demarrerCritique().then((_) => demarrerSecondaire());
  }

  Future<void> demarrerCritique() {
    _futureCritique ??= _initialiserCritique();
    return _futureCritique!;
  }

  Future<void> demarrerSecondaire() {
    _futureSecondaire ??= _initialiserSecondaire();
    return _futureSecondaire!;
  }

  Future<void> _initialiserCritique() async {
    await initialiserLocalisation();
    await ServiceChiffrement.instance.initialiser();
  }

  Future<void> _initialiserSecondaire() async {
    await ServiceBaseDeDonnees.instance.base;
    await DepotCategories.instance.initialiserParDefaut();
  }
}
