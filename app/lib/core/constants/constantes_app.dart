class ConstantesApp {
  ConstantesApp._();

  static const String nomBdd = 'budgetflow.db';
  static const int versionBdd = 3;

  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableImages = 'images_transaction';

  static const String cleCryptoStorage = 'budgetflow_aes_key';
  static const String cleOnboardingVu = 'onboarding_vu';
  static const String cleUtilisateurLocal = 'utilisateur_local';
  static const String cleSnapshotComptePrefix = 'snapshot_compte_';
  static const String cleDemanderConnexionApresOnboarding =
      'demander_connexion_apres_onboarding';
  static const String clePinLocal = 'pin_local';
  static const String clePinFailCount = 'pin_fail_count';
  static const String clePinLockUntilMs = 'pin_lock_until_ms';

  static const String symboleDevise = 'Ar';
  static const String nomDevise = 'Ariary';

  static const String idCatDepensePrefix = 'dep_';
  static const String idCatRevenuPrefix = 'rev_';
}
