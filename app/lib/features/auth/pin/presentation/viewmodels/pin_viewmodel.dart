import 'package:flutter/material.dart';

enum ModePIN { creation, confirmation, verification }

class PinViewModel extends ChangeNotifier {
  final ModePIN mode;
  final String? pinAVerifier;

  PinViewModel({required this.mode, this.pinAVerifier})
      : _modeSaisie = mode == ModePIN.verification
            ? ModePIN.verification
            : ModePIN.creation;

  String _pin = '';
  String _pinInitial = '';
  String? _pinFinal;
  bool _aErreur = false;
  bool _estSucces = false;
  ModePIN _modeSaisie;

  String get pin => _pin;
  bool get erreur => _aErreur;
  bool get succes => _estSucces;
  ModePIN get modeActuel => _modeSaisie;
  String? get pinFinal => _pinFinal;

  String get titre {
    switch (_modeSaisie) {
      case ModePIN.creation:
        return 'Créer votre PIN';
      case ModePIN.confirmation:
        return 'Confirmer votre PIN';
      case ModePIN.verification:
        return 'Entrez votre PIN';
    }
  }

  String get sousTitre {
    switch (_modeSaisie) {
      case ModePIN.creation:
        return 'Choisissez un code à 4 chiffres';
      case ModePIN.confirmation:
        return 'Saisissez à nouveau votre PIN';
      case ModePIN.verification:
        return 'Saisissez votre code à 4 chiffres';
    }
  }

  void saisirChiffre(String chiffre) {
    if (_pin.length < 4) {
      _pin += chiffre;
      _aErreur = false;
      notifyListeners();

      if (_pin.length == 4) {
        _validerPin();
      }
    }
  }

  void effacerDernier() {
    if (_pin.isNotEmpty) {
      _pin = _pin.substring(0, _pin.length - 1);
      _aErreur = false;
      notifyListeners();
    }
  }

  void _validerPin() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mode == ModePIN.creation && _modeSaisie == ModePIN.creation) {
        _pinInitial = _pin;
        _pin = '';
        _modeSaisie = ModePIN.confirmation;
        notifyListeners();
      } else if (mode == ModePIN.creation &&
          _modeSaisie == ModePIN.confirmation) {
        if (_pin == _pinInitial) {
          _pinFinal = _pin;
          _estSucces = true;
          notifyListeners();
        } else {
          _aErreur = true;
          _pin = '';
          notifyListeners();
        }
      } else if (mode == ModePIN.verification) {
        if (_pin == (pinAVerifier ?? '0000')) {
          _pinFinal = _pin;
          _estSucces = true;
          notifyListeners();
        } else {
          _aErreur = true;
          _pin = '';
          notifyListeners();
        }
      }
    });
  }
}
