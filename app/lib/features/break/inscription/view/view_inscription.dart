import 'package:budgetflow/core/theme/app_theme.dart';
import 'package:budgetflow/features/break/inscription/viewmodels/view_modele_inscription.dart';
import 'package:flutter/material.dart';

// 1- écran d'inscription
class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});
  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  // Les contrôleurs servent à récupérer proprement le contenu des champs.
  final TextEditingController _controllerPseudo = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerMotDePasse = TextEditingController();
  final TextEditingController _controllerConfirmation = TextEditingController();

  final ViewModeleInscription _viewModele = ViewModeleInscription();
  bool _masquerMotDePasse = true;
  bool _masquerConfirmation = true;

  @override
  void initState() {
    super.initState();
    _controllerPseudo.addListener(() {
      _viewModele.mettreAJourPseudo(_controllerPseudo.text);
    });
    _controllerEmail.addListener(() {
      _viewModele.mettreAJourEmail(_controllerEmail.text);
    });
    _controllerMotDePasse.addListener(() {
      _viewModele.mettreAJourMotDePasse(_controllerMotDePasse.text);
    });
    _controllerConfirmation.addListener(() {
      _viewModele.mettreAJourConfirmationMotDePasse(
        _controllerConfirmation.text,
      );
    });
  }

  @override
  void dispose() {
    _controllerPseudo.dispose();
    _controllerEmail.dispose();
    _controllerMotDePasse.dispose();
    _controllerConfirmation.dispose();
    _viewModele.dispose();
    super.dispose();
  }

  // Pour l'instant validation locale
  void _soumettreInscription() {
    FocusScope.of(context).unfocus();
    final bool inscriptionValide = _viewModele.tenterInscription();
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    messager.hideCurrentSnackBar();

    if (!inscriptionValide) {
      messager.showSnackBar(
        const SnackBar(
          content: Text('Le formulaire contient encore quelques erreurs.'),
        ),
      );
      return;
    }
    messager.showSnackBar(
      const SnackBar(
        content: Text(
          'Interface prête : la création réelle du compte pourra être reliée au backend ensuite.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModele,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFFF6EEEC),
                  Color(0xFFF3E8F1),
                  Color(0xFFEFF5FA),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: _construireBlocFormulaire(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construireBlocFormulaire(BuildContext context) {
    final TextTheme styles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SystemeDesignBudgetFlow.blancCarte,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SystemeDesignBudgetFlow.bordureDouce),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'lib/assets/logo/logo.png',
                width: 86,
                height: 86,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('S’inscrire', style: styles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Crée ton espace personnel pour suivre tes dépenses sereinement.',
            style: styles.bodyMedium,
          ),
          const SizedBox(height: 24),
          _ChampSaisieInscription(
            etiquette: 'Ton pseudo',
            indice: 'Entre ton pseudo',
            controleur: _controllerPseudo,
            icone: Icons.person_outline_rounded,
            texteErreur:
                _viewModele.afficherErreurs ? _viewModele.erreurPseudo : null,
          ),
          const SizedBox(height: 16),
          _ChampSaisieInscription(
            etiquette: 'Email',
            indice: 'exemple@budgetflow.fr',
            controleur: _controllerEmail,
            typeClavier: TextInputType.emailAddress,
            icone: Icons.mail_outline_rounded,
            texteErreur:
                _viewModele.afficherErreurs ? _viewModele.erreurEmail : null,
          ),
          const SizedBox(height: 16),
          _ChampSaisieInscription(
            etiquette: 'Mot de passe',
            indice: 'Au moins 6 caractères et 1 chiffre',
            controleur: _controllerMotDePasse,
            icone: Icons.lock_outline_rounded,
            masquerTexte: _masquerMotDePasse,
            texteErreur: _viewModele.afficherErreurs
                ? _viewModele.erreurMotDePasse
                : null,
            iconeFin: IconButton(
              onPressed: () {
                setState(() {
                  _masquerMotDePasse = !_masquerMotDePasse;
                });
              },
              icon: Icon(
                _masquerMotDePasse
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChampSaisieInscription(
            etiquette: 'Confirmer le mot de passe',
            indice: 'Répète le mot de passe',
            controleur: _controllerConfirmation,
            icone: Icons.lock_person_outlined,
            masquerTexte: _masquerConfirmation,
            texteErreur: _viewModele.afficherErreurs
                ? _viewModele.erreurConfirmation
                : null,
            iconeFin: IconButton(
              onPressed: () {
                setState(() {
                  _masquerConfirmation = !_masquerConfirmation;
                });
              },
              icon: Icon(
                _masquerConfirmation
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _viewModele.donnees.accepteConditions,
            contentPadding: EdgeInsets.zero,
            activeColor: SystemeDesignBudgetFlow.rosePrincipal,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? valeur) {
              _viewModele.changerAcceptationConditions(valeur ?? false);
            },
            title: Text(
              'J’accepte les conditions d’utilisation et la politique de confidentialité.',
              style: styles.bodyMedium?.copyWith(
                color: SystemeDesignBudgetFlow.textePrincipal,
              ),
            ),
          ),
          if (_viewModele.afficherErreurs &&
              !_viewModele.donnees.accepteConditions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Tu dois accepter les conditions pour continuer.',
                style: styles.bodyMedium?.copyWith(
                  color: SystemeDesignBudgetFlow.erreur,
                ),
              ),
            ),
          const SizedBox(height: 10),
          _BoutonPrincipal(
            texte: 'S’inscrire',
            actif: _viewModele.formulaireValide,
            onPressed: _soumettreInscription,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'L’écran de connexion sera ajouté dans l’étape suivante.',
                    ),
                  ),
                );
              },
              child: const Text('J’ai déjà un compte'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de saisie
class _ChampSaisieInscription extends StatelessWidget {
  const _ChampSaisieInscription({
    required this.etiquette,
    required this.indice,
    required this.controleur,
    required this.icone,
    this.typeClavier,
    this.masquerTexte = false,
    this.texteErreur,
    this.iconeFin,
  });

  final String etiquette;
  final String indice;
  final TextEditingController controleur;
  final IconData icone;
  final TextInputType? typeClavier;
  final bool masquerTexte;
  final String? texteErreur;
  final Widget? iconeFin;

  @override
  Widget build(BuildContext context) {
    final TextTheme styles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(etiquette, style: styles.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controleur,
          keyboardType: typeClavier,
          obscureText: masquerTexte,
          style: styles.bodyMedium?.copyWith(
            color: SystemeDesignBudgetFlow.textePrincipal,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: indice,
            errorText: texteErreur,
            prefixIcon: Icon(
              icone,
              color: SystemeDesignBudgetFlow.texteSecondaire,
            ),
            suffixIcon: iconeFin,
          ),
        ),
      ],
    );
  }
}

/// Bouton principal avec le dégradé rose-violet du design system.
class _BoutonPrincipal extends StatelessWidget {
  const _BoutonPrincipal({
    required this.texte,
    required this.actif,
    required this.onPressed,
  });

  final String texte;
  final bool actif;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: actif ? 1 : 0.88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SystemeDesignBudgetFlow.degradePrincipal,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x26D95FA4),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              texte,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
