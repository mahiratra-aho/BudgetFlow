import 'package:bugdetflowapp/features/inscription/modeles/modele_inscription.dart';
import 'package:flutter/foundation.dart';

// état d'inscription
class ViewModeleInscription extends ChangeNotifier {
  ModeleInscription _donnees = const ModeleInscription();
  bool _afficherErreurs = false;
  ModeleInscription get donnees => _donnees;
  bool get afficherErreurs => _afficherErreurs;
  void mettreAJourPseudo(String valeur) {
    _donnees = _donnees.copieAvec(pseudo: valeur);
    notifyListeners();
  }

  void mettreAJourEmail(String valeur) {
    _donnees = _donnees.copieAvec(email: valeur);
    notifyListeners();
  }

  void mettreAJourMotDePasse(String valeur) {
    _donnees = _donnees.copieAvec(motDePasse: valeur);
    notifyListeners();
  }

  void mettreAJourConfirmationMotDePasse(String valeur) {
    _donnees = _donnees.copieAvec(confirmationMotDePasse: valeur);
    notifyListeners();
  }

  void changerAcceptationConditions(bool nouvelleValeur) {
    _donnees = _donnees.copieAvec(accepteConditions: nouvelleValeur);
    notifyListeners();
  }

  String? get erreurPseudo {
    if (_donnees.pseudo.trim().isEmpty) {
      return 'Le pseudo est obligatoire.';
    }
    if (_donnees.pseudo.trim().length < 3) {
      return 'Ajoute au moins 3 caractères.';
    }
    return null;
  }

  String? get erreurEmail {
    final String emailNettoye = _donnees.email.trim();
    if (emailNettoye.isEmpty) {
      return 'L\'email est obligatoire.';
    }

    final RegExp formatEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!formatEmail.hasMatch(emailNettoye)) {
      return 'Le format de l\'email semble incorrect.';
    }
    return null;
  }

  String? get erreurMotDePasse {
    if (_donnees.motDePasse.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    if (_donnees.motDePasse.length < 6) {
      return 'Choisis au moins 6 caractères.';
    }
    if (!RegExp(r'\d').hasMatch(_donnees.motDePasse)) {
      return 'Ajoute au moins un chiffre.';
    }
    return null;
  }

  String? get erreurConfirmation {
    if (_donnees.confirmationMotDePasse.isEmpty) {
      return 'Merci de confirmer le mot de passe.';
    }
    if (_donnees.confirmationMotDePasse != _donnees.motDePasse) {
      return 'Les deux mots de passe ne correspondent pas.';
    }
    return null;
  }

  bool get formulaireValide {
    return erreurPseudo == null &&
        erreurEmail == null &&
        erreurMotDePasse == null &&
        erreurConfirmation == null &&
        _donnees.accepteConditions;
  }

  /// Active l'affichage des erreurs puis indique si le formulaire est prêt.
  bool tenterInscription() {
    _afficherErreurs = true;
    notifyListeners();
    return formulaireValide;
  }
}
