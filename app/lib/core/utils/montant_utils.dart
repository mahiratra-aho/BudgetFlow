class FormatteurMontant {
  const FormatteurMontant._();

  /// Réduit les grands montants pour l'affichage tout en conservant leur signe.
  static String formatCourt(double montant) {
    if (montant.abs() >= 1000000) {
      final valeurCompacte = (montant.abs() / 1000000).toStringAsFixed(1);
      return montant < 0 ? '−${valeurCompacte}M' : '${valeurCompacte}M';
    }

    if (montant.abs() >= 1000) {
      final chiffres = montant.abs().toStringAsFixed(0);
      final tampon = StringBuffer();
      var compteur = 0;

      for (var index = chiffres.length - 1; index >= 0; index--) {
        if (compteur > 0 && compteur % 3 == 0) {
          tampon.write(' ');
        }
        tampon.write(chiffres[index]);
        compteur++;
      }

      final montantFormate = tampon.toString().split('').reversed.join();
      return montant < 0 ? '−$montantFormate' : montantFormate;
    }

    return montant.toStringAsFixed(0);
  }
}
