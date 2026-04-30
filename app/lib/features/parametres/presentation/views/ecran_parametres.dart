import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/constantes_app.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../navigation.dart';
import '../../../auth/pin/presentation/views/ecran_pin.dart';
import '../../../auth/connexion/presentation/views/ecran_connexion.dart';
import '../../../auth/inscription/presentation/views/ecran_inscription.dart';
import '../../../budgets/presentation/views/ecran_budgets.dart';
import '../../../categories/presentation/views/ecran_categories.dart';
import '../../../membres/presentation/views/ecran_membres.dart';
import '../../../moyens_paiement/presentation/views/ecran_moyens_paiement.dart';
import '../../../rappels/presentation/views/ecran_rappels.dart';
import '../../../statistiques/presentation/views/ecran_statistiques.dart';
import '../../../shared/utils/depot_categories.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../widgets/parametres_widgets.dart';

class EcranParametres extends ConsumerStatefulWidget {
  const EcranParametres({super.key});

  @override
  ConsumerState<EcranParametres> createState() => _EtatEcranParametres();
}

class _EtatEcranParametres extends ConsumerState<EcranParametres> {
  String? _pin;

  @override
  void initState() {
    super.initState();
    _chargerPin();
  }

  Future<void> _chargerPin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _pin = prefs.getString(ConstantesApp.clePinLocal));
  }

  bool get _pinActif => _pin != null && _pin!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final utilisateur = ref.watch(utilisateurProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(
        titre: 'Paramètres',
        afficherRetour: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppEspaces.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Carte profil ─────────────────────────────────────────
            CarteProfilParametres(utilisateur: utilisateur),

            const SizedBox(height: AppEspaces.lg),

            // ── Bouton connexion/déconnexion selon l'état ─────────────
            if (!utilisateur.estConnecte) ...[
              BoutonActionParametres(
                icone: Icons.login_rounded,
                label: 'Se connecter',
                description: 'Synchronisez vos données sur plusieurs appareils',
                onTap: () => _ouvrirConnexion(context, ref),
              ),
              const SizedBox(height: AppEspaces.sm),
              BoutonActionParametres(
                icone: Icons.person_add_outlined,
                label: 'Créer un compte',
                description: 'Inscrivez-vous gratuitement',
                onTap: () => _ouvrirInscription(context, ref),
              ),
            ],

            const SizedBox(height: AppEspaces.xl),

            const TitreSectionParametres('Sécurité'),
            const SizedBox(height: AppEspaces.sm),
            GroupeParametres(enfants: [
              ItemParametre(
                icone: Icons.lock_outline_rounded,
                label: _pinActif ? 'Modifier PIN' : 'Configurer PIN',
                onTap: () => _ouvrirConfigurerOuModifierPin(context),
              ),
              ItemParametre(
                icone: Icons.delete_outline_rounded,
                label: 'Supprimer PIN',
                onTap: !_pinActif ? null : () => _supprimerPin(context),
              ),
            ]),

            const SizedBox(height: AppEspaces.xl),
            const TitreSectionParametres('Gérer'),
            const SizedBox(height: AppEspaces.sm),
            GroupeParametres(enfants: [
              ItemParametre(
                icone: Icons.account_balance_wallet_outlined,
                label: 'Moyens de paiement',
                onTap: () => _ouvrir(context, const EcranMoyensPaiement()),
              ),
              ItemParametre(
                icone: Icons.group_outlined,
                label: 'Membres',
                onTap: () => _ouvrir(context, const EcranMembres()),
              ),
              ItemParametre(
                icone: Icons.category_outlined,
                label: 'Catégorie',
                onTap: () => _ouvrir(context, const EcranCategories()),
              ),
              ItemParametre(
                icone: Icons.pie_chart_outline_rounded,
                label: 'Budgets',
                onTap: () => _ouvrir(context, const EcranBudgets()),
              ),
            ]),

            const SizedBox(height: AppEspaces.xl),
            const TitreSectionParametres('Données'),
            const SizedBox(height: AppEspaces.sm),
            GroupeParametres(enfants: [
              ItemParametre(
                icone: Icons.bar_chart_rounded,
                label: 'Statistiques',
                onTap: () => _ouvrir(context, const EcranStatistiques()),
              ),
              ItemParametre(
                icone: Icons.notifications_active_outlined,
                label: 'Rappels',
                onTap: () => _ouvrir(context, const EcranRappels()),
              ),
              ItemParametre(
                svgAsset: 'assets/icons/exportexcel.svg',
                label: 'Exporter',
                onTap: () => _ouvrir(context, const EcranStatistiques(ouvrirExportAuDemarrage: true)),
              ),
            ]),

            if (utilisateur.estConnecte) ...[
              const SizedBox(height: AppEspaces.xl),
              OutlinedButton.icon(
                onPressed: () => _deconnecter(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppCouleurs.accentBrun,
                  side: const BorderSide(color: AppCouleurs.accentBrun),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRayons.bouton)),
                  textStyle: AppTypographie.labelLarge,
                ),
              ),
            ],

            const SizedBox(height: AppEspaces.xxl),
          ],
        ),
      ),
    );
  }

  void _pousserEcranCreationPin(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EcranPin(
          mode: ModePIN.creation,
          onSucces: (pin) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(ConstantesApp.clePinLocal, pin);
            if (mounted) {
              Navigator.pop(context);
              _chargerPin();
            }
          },
        ),
      ),
    );
  }

  Future<void> _ouvrirConfigurerOuModifierPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final pinExistant = prefs.getString(ConstantesApp.clePinLocal);
    if (!mounted) return;

    if (pinExistant == null || pinExistant.isEmpty) {
      _pousserEcranCreationPin(context);
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => EcranPin(
          mode: ModePIN.verification,
          pinAVerifier: pinExistant,
          onSucces: (_) {
            Navigator.of(ctx).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _pousserEcranCreationPin(context);
            });
          },
        ),
      ),
    );
  }

  void _ouvrir(BuildContext context, Widget ecran) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
  }

  Future<void> _supprimerPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final pinExistant = prefs.getString(ConstantesApp.clePinLocal);
    if (pinExistant == null || pinExistant.isEmpty) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => EcranPin(
          mode: ModePIN.verification,
          pinAVerifier: pinExistant,
          onSucces: (_) async {
            Navigator.of(ctx).pop();
            final p = await SharedPreferences.getInstance();
            await p.remove(ConstantesApp.clePinLocal);
            if (mounted) {
              _chargerPin();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN supprimé')),
              );
            }
          },
        ),
      ),
    );
  }

  void _ouvrirConnexion(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: EcranConnexion(
            onConnecte: (nom) {
              final uid = 'uid_${nom.toLowerCase().replaceAll(' ', '_')}';
              ref
                  .read(utilisateurProvider.notifier)
                  .connecter(uid, nom)
                  .then((_) {
                ref.invalidate(onboardingVuProvider);
                invalidaterTransactions(ref);
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AppNavigation()),
                    (route) => false,
                  );
                }
              });
            },
            onInscription: () {
              Navigator.pop(context);
              _ouvrirInscription(context, ref);
            },
          ),
        ),
      ),
    );
  }

  void _ouvrirInscription(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: EcranInscription(
            onInscrit: (_) {
              Navigator.pop(context);
              _ouvrirConnexion(context, ref);
            },
            onConnexion: () {
              Navigator.pop(context);
              _ouvrirConnexion(context, ref);
            },
          ),
        ),
      ),
    );
  }

  void _deconnecter(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRayons.md)),
        title: Text('Se déconnecter ?', style: AppTypographie.titleSmall),
        content: Text('Vos données locales seront conservées.',
            style: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteSecondaire)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Annuler',
                style: AppTypographie.labelLarge
                    .copyWith(color: AppCouleurs.texteSecondaire)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(utilisateurProvider.notifier).deconnecter();
              await DepotCategories.instance.initialiserParDefaut();
              ref.invalidate(onboardingVuProvider);
              invalidaterTransactions(ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCouleurs.primaire,
              foregroundColor: AppCouleurs.textePrincipal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRayons.md)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
