import 'package:flutter/material.dart';
import '../../../../../core/auth/service_auth_local.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../../shared/widgets/app_bar_budgetflow.dart';

class EcranInscription extends StatefulWidget {
  final void Function(String nomUtilisateur) onInscrit;
  final VoidCallback onConnexion;

  const EcranInscription({
    super.key,
    required this.onInscrit,
    required this.onConnexion,
  });

  @override
  State<EcranInscription> createState() => _EtatEcranInscription();
}

class _EtatEcranInscription extends State<EcranInscription> {
  final _controleurPseudo = TextEditingController();
  final _controleurMDP = TextEditingController();
  final _controleurConfirmation = TextEditingController();
  bool _mdpVisible = false;
  bool _confirmationVisible = false;
  bool _enChargement = false;
  String? _erreur;

  @override
  void dispose() {
    _controleurPseudo.dispose();
    _controleurMDP.dispose();
    _controleurConfirmation.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (_controleurPseudo.text.trim().isEmpty) {
      setState(() => _erreur = 'Le pseudo est requis');
      return;
    }
    if (_controleurMDP.text.length < 6) {
      setState(() => _erreur = 'Mot de passe trop court (6 min.)');
      return;
    }
    if (_controleurMDP.text != _controleurConfirmation.text) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _enChargement = true;
      _erreur = null;
    });
    final ok = await ServiceAuthLocal.instance.inscrire(
      pseudo: _controleurPseudo.text.trim(),
      motDePasse: _controleurMDP.text,
    );
    if (!mounted) return;
    setState(() => _enChargement = false);
    if (!ok) {
      setState(() => _erreur = 'Ce pseudo existe deja');
      return;
    }
    widget.onInscrit(_controleurPseudo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Créer un compte'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppEspaces.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppEspaces.lg),
              _Champ(
                  label: 'Pseudo',
                  placeholder: 'MonPseudo',
                  controleur: _controleurPseudo),
              const SizedBox(height: AppEspaces.md),
              _Champ(
                label: 'Mot de passe',
                placeholder: '••••••••',
                controleur: _controleurMDP,
                estMDP: true,
                mdpVisible: _mdpVisible,
                onToggleMDP: () => setState(() => _mdpVisible = !_mdpVisible),
              ),
              const SizedBox(height: AppEspaces.md),
              _Champ(
                label: 'Confirmer le mot de passe',
                placeholder: '••••••••',
                controleur: _controleurConfirmation,
                estMDP: true,
                mdpVisible: _confirmationVisible,
                onToggleMDP: () => setState(
                    () => _confirmationVisible = !_confirmationVisible),
                messageErreur: _erreur,
              ),
              const SizedBox(height: AppEspaces.xl),
              BoutonPrimaire(
                libelle: 'Créer mon compte',
                estChargement: _enChargement,
                onPress: _inscrire,
              ),
              const SizedBox(height: AppEspaces.lg),
              Center(
                child: GestureDetector(
                  onTap: widget.onConnexion,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Déjà un compte ? ',
                          style: AppTypographie.bodyMedium
                              .copyWith(color: AppCouleurs.texteSecondaire),
                        ),
                        TextSpan(
                          text: 'Se connecter',
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
  final String? messageErreur;

  const _Champ({
    required this.label,
    required this.placeholder,
    required this.controleur,
    this.typeClavier = TextInputType.text,
    this.estMDP = false,
    this.mdpVisible = false,
    this.onToggleMDP,
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
        TextField(
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRayons.md),
              borderSide: const BorderSide(color: AppCouleurs.erreur),
            ),
          ),
        ),
      ],
    );
  }
}
