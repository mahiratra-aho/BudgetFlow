import 'package:flutter/material.dart';

class SplashViewModel extends ChangeNotifier {
  bool _estPret = false;

  bool get estPret => _estPret;

  Future<void> initialiser() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    _estPret = true;
    notifyListeners();
  }
}
