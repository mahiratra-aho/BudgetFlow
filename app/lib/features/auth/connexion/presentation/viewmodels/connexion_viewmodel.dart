import 'package:flutter/material.dart';

class ConnexionViewModel extends ChangeNotifier {
  final controleurEmail = TextEditingController();
  final controleurMotDePasse = TextEditingController();

  bool _motDePasseVisible = false;
  bool _estEnChargement = false;
  String? _messageErreur;

  bool get motDePasseVisible => _motDePasseVisible;
  bool get enChargement => _estEnChargement;
  String? get erreur => _messageErreur;

  bool get formulaireValide =>
      controleurEmail.text.trim().isNotEmpty &&
      controleurMotDePasse.text.trim().isNotEmpty;

  void toggleVisibiliteMDP() {
    _motDePasseVisible = !_motDePasseVisible;
    notifyListeners();
  }

  Future<bool> connecter() async {
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
    controleurEmail.dispose();
    controleurMotDePasse.dispose();
    super.dispose();
  }
}
