import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Bienvenue dans mes couleurs, typographies et styles communs
class SystemeDesignBudgetFlow {
  SystemeDesignBudgetFlow._();

  static const Color fondApplication = Color(0xFFF4ECEB);
  static const Color blancCarte = Color(0xFFF9F6FB);
  static const Color rosePrincipal = Color(0xFFF468B0);
  static const Color violetPrincipal = Color(0xFFC29AE6);
  static const Color bleuSecondaire = Color(0xFFA9D6EC);
  static const Color bleuChamp = Color(0xFFD9EAF3);
  static const Color textePrincipal = Color(0xFF6E446A);
  static const Color texteSecondaire = Color(0xFF8D8091);
  static const Color bordureDouce = Color(0xFFE8D9E6);
  static const Color succes = Color(0xFF6CC576);
  static const Color erreur = Color(0xFFF47C76);

  static const LinearGradient degradePrincipal = LinearGradient(
    colors: <Color>[Color(0xFF8C3F74), Color(0xFFD95FA4), Color(0xFFF47EB8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData creerTheme() {
    final ColorScheme palette =
        ColorScheme.fromSeed(
          seedColor: violetPrincipal,
          brightness: Brightness.light,
        ).copyWith(
          primary: rosePrincipal,
          secondary: bleuSecondaire,
          surface: blancCarte,
          error: erreur,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: palette,
      scaffoldBackgroundColor: fondApplication,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.comicNeue(
          fontSize: 31,
          fontWeight: FontWeight.w700,
          color: textePrincipal,
        ),
        headlineMedium: GoogleFonts.comicNeue(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: textePrincipal,
        ),
        bodyLarge: GoogleFonts.comicNeue(fontSize: 16, color: textePrincipal),
        bodyMedium: GoogleFonts.nunito(fontSize: 15, color: texteSecondaire),
        labelLarge: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textePrincipal,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bleuChamp,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.nunito(color: texteSecondaire, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: rosePrincipal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: erreur, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: erreur, width: 1.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textePrincipal,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
