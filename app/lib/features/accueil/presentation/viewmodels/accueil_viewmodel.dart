import 'package:flutter/material.dart';
import '../../../shared/utils/modeles.dart';

class AccueilViewModel extends ChangeNotifier {
  bool _soldeVisible = true;
  final String _moisSelectionne = 'Avril 2025';

  bool get soldeVisible => _soldeVisible;
  String get moisSelectionne => _moisSelectionne;

  double get soldeTotal => 3245.80;
  double get totalRevenus => 2800.00;
  double get totalDepenses => 1046.49;

  List<Transaction> get dernieresTransactions =>
      DonneesDDemo.transactions.take(5).toList();

  void toggleVisibiliteSolde() {
    _soldeVisible = !_soldeVisible;
    notifyListeners();
  }

  String formaterMontant(double montant) {
    return '${montant.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  String formaterDate(DateTime date) {
    final maintenant = DateTime.now();
    final diff = maintenant.difference(date).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return '${date.day}/${date.month}';
  }
}
