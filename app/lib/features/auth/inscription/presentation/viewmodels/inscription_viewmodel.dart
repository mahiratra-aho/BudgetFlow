import 'package:flutter/material.dart';

class InscriptionViewModel extends ChangeNotifier {
  final controleurPseudo = TextEditingController();
  final controleurEmail = TextEditingController();
  final controleurMotDePasse = TextEditingController();
  final controleurConfirmation = TextEditingController();

  bool _motDePasseVisible = false;
  bool _confirmationVisible = false;
  bool _estEnChargement = false;
  String? _messageErreur;

  bool get motDePasseVisible => _motDePasseVisible;
  bool get confirmationVisible => _confirmationVisible;
  bool get enChargement => _estEnChargement;
  String? get erreur => _messageErreur;

  void toggleVisibiliteMDP() {
    _motDePasseVisible = !_motDePasseVisible;
    notifyListeners();
  }

  void toggleVisibiliteConfirmation() {
    _confirmationVisible = !_confirmationVisible;
    notifyListeners();
  }

  bool valider() {
    if (controleurPseudo.text.trim().isEmpty) {
      _messageErreur = 'Le pseudo est requis';
      notifyListeners();
      return false;
    }
    if (!controleurEmail.text.contains('@')) {
      _messageErreur = 'E-mail invalide';
      notifyListeners();
      return false;
    }
    if (controleurMotDePasse.text.length < 6) {
      _messageErreur = 'Mot de passe trop court (6 caractères min.)';
      notifyListeners();
      return false;
    }
    if (controleurMotDePasse.text != controleurConfirmation.text) {
      _messageErreur = 'Les mots de passe ne correspondent pas';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> inscrire() async {
    if (!valider()) return false;

    _messageErreur = null;
    _estEnChargement = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _estEnChargement = false;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    controleurPseudo.dispose();
    controleurEmail.dispose();
    controleurMotDePasse.dispose();
    controleurConfirmation.dispose();
    super.dispose();
  }
}
