import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/auth/service_auth_local.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../navigation.dart';
import '../../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../../shared/widgets/app_bar_budgetflow.dart';

class EcranConnexion extends StatefulWidget {
  final void Function(String nomUtilisateur) onConnecte;
  final VoidCallback onInscription;

  const EcranConnexion({
    super.key,
    required this.onConnecte,
    required this.onInscription,
  });

  @override
  State<EcranConnexion> createState() => _EtatEcranConnexion();
}

class _EtatEcranConnexion extends State<EcranConnexion> {
  final _controleurPseudo = TextEditingController();
  final _controleurMDP = TextEditingController();
  bool _mdpVisible = false;
  bool _enChargement = false;
  String? _erreur;

  @override
  void dispose() {
    _controleurPseudo.dispose();
    _controleurMDP.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (_controleurPseudo.text.trim().isEmpty ||
        _controleurMDP.text.trim().isEmpty) {
      setState(() => _erreur = 'Veuillez remplir tous les champs');
      return;
    }
    setState(() {
      _enChargement = true;
      _erreur = null;
    });
    final ok = await ServiceAuthLocal.instance.connecter(
      pseudo: _controleurPseudo.text.trim(),
      motDePasse: _controleurMDP.text,
    );
    if (!mounted) return;
    setState(() => _enChargement = false);
    if (!ok) {
      setState(() => _erreur = 'Pseudo ou mot de passe incorrect');
      return;
    }
    widget.onConnecte(_controleurPseudo.text.trim());

    // Sécurité: si le parent n'a pas fermé/redirigé l'écran, on force l'accès accueil.
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppNavigation()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Connexion'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppEspaces.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppEspaces.xl),
              Center(
                child: SvgPicture.asset('assets/icons/wallet.svg', width: 72),
              ),
              const SizedBox(height: AppEspaces.lg),
              Center(
                child: Text('Bienvenue !',
                    style: AppTypographie.headlineSmall
                        .copyWith(fontFamily: 'ComicNeue')),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Connectez-vous pour synchroniser vos données',
                    style: AppTypographie.bodySmall
                        .copyWith(color: AppCouleurs.texteSecondaire),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: AppEspaces.xxl),
              _Champ(
                label: 'Pseudo',
                placeholder: 'MonPseudo',
                controleur: _controleurPseudo,
                typeClavier: TextInputType.text,
                prefixIcone:
                    const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(height: AppEspaces.md),
              _Champ(
                label: 'Mot de passe',
                placeholder: '••••••••',
                controleur: _controleurMDP,
                estMDP: true,
                mdpVisible: _mdpVisible,
                onToggleMDP: () => setState(() => _mdpVisible = !_mdpVisible),
                messageErreur: _erreur,
              ),
              const SizedBox(height: AppEspaces.xl),
              BoutonPrimaire(
                libelle: 'Se connecter',
                estChargement: _enChargement,
                onPress: _connecter,
              ),
              const SizedBox(height: AppEspaces.xl),
              Center(
                child: GestureDetector(
                  onTap: widget.onInscription,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pas encore de compte ? ',
                          style: AppTypographie.bodyMedium
                              .copyWith(color: AppCouleurs.texteSecondaire),
                        ),
                        TextSpan(
                          text: 'Créer un compte',
                          style: AppTypographie.bodyMedium.copyWith(
                            color: AppCouleurs.primaire,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppEspaces.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Champ extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controleur;
  final TextInputType typeClavier;
  final bool estMDP;
  final bool mdpVisible;
  final VoidCallback? onToggleMDP;
  final Widget? prefixIcone;
  final String? messageErreur;

  const _Champ({
    required this.label,
    required this.placeholder,
    required this.controleur,
    this.typeClavier = TextInputType.text,
    this.estMDP = false,
    this.mdpVisible = false,
    this.onToggleMDP,
    this.prefixIcone,
    this.messageErreur,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypographie.labelLarge
                .copyWith(color: AppCouleurs.texteSecondaire)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controleur,
          obscureText: estMDP && !mdpVisible,
          keyboardType: typeClavier,
          style: AppTypographie.bodyMedium,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTypographie.bodyMedium
                .copyWith(color: AppCouleurs.texteTertiaire),
            filled: true,
            fillColor: AppCouleurs.surface,
            prefixIcon: prefixIcone != null
                ? Padding(padding: const EdgeInsets.all(12), child: prefixIcone)
                : null,
            suffixIcon: estMDP
                ? IconButton(
                    onPressed: onToggleMDP,
                    icon: Icon(
                      mdpVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppCouleurs.texteSecondaire,
                      size: 20,
                    ))
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: BorderSide(
                  color: AppCouleurs.textePrincipal.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide:
                  const BorderSide(color: AppCouleurs.primaire, width: 2),
            ),
            errorText: messageErreur,
          ),
        ),
      ],
    );
  }
}
