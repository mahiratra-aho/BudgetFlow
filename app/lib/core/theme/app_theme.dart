import 'package:flutter/material.dart';

class AppCouleurs {
  AppCouleurs._();

  static const Color primaire = Color(0xFFFEBC2A);
  static const Color primaireClaire = Color(0xFFFEE8A0);
  static const Color primaireFoncee = Color(0xFFE6A800);

  static const Color succes = Color(0xFF8AA232);
  static const Color erreur = Color(0xFFE05252);
  static const Color avertissement = Color(0xFFFFB347);
  static const Color info = Color(0xFF6B8CBA);

  static const Color fondPrincipal = Color(0xFFEEEBE3);
  static const Color fondSecondaire = Color(0xFFF8F5EE);
  static const Color fondSombre = Color(0xFF2A1F17);
  static const Color surface = Color(0xFFFCF7EB);

  static const Color textePrincipal = Color(0xFF2D2318);
  static const Color texteSecondaire = Color(0xFF7A6B5A);
  static const Color texteTertiaire = Color(0xFFB0A090);
  static const Color texteInverse = Color(0xFFFFF7E3);

  static const Color accentBrun = Color(0xFF754539);
  static const Color accentVertOlive = Color(0xFF8AA232);

  static const Color conteneurPrimaire = Color(0xFFFEF3CC);
  static const Color conteneurSucces = Color(0xFFEEF3CC);
  static const Color conteneurErreur = Color(0xFFFDE8E8);
}

class AppTypographie {
  AppTypographie._();

  static const String familleDisplay = 'ComicNeue';
  static const String familleCorps = 'Nunito';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.15,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.2,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.25,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.3,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: familleDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.3,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 1.4,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.4,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: AppCouleurs.texteSecondaire,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppCouleurs.textePrincipal,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: familleCorps,
    fontWeight: FontWeight.w600,
    fontSize: 10,
    height: 1.3,
    letterSpacing: 1.0,
  );
}

class AppRayons {
  AppRayons._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double bouton = 50.0;
}

class AppEspaces {
  AppEspaces._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

ThemeData creerTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppCouleurs.primaire,
      secondary: AppCouleurs.accentVertOlive,
      surface: AppCouleurs.fondPrincipal,
      onPrimary: AppCouleurs.textePrincipal,
      onSurface: AppCouleurs.textePrincipal,
    ),
    scaffoldBackgroundColor: AppCouleurs.fondPrincipal,
    textTheme: const TextTheme(
      displayLarge: AppTypographie.displayLarge,
      displayMedium: AppTypographie.displayMedium,
      headlineLarge: AppTypographie.headlineLarge,
      headlineMedium: AppTypographie.headlineMedium,
      headlineSmall: AppTypographie.headlineSmall,
      titleLarge: AppTypographie.titleLarge,
      titleMedium: AppTypographie.titleMedium,
      titleSmall: AppTypographie.titleSmall,
      bodyLarge: AppTypographie.bodyLarge,
      bodyMedium: AppTypographie.bodyMedium,
      bodySmall: AppTypographie.bodySmall,
      labelLarge: AppTypographie.labelLarge,
      labelMedium: AppTypographie.labelMedium,
      labelSmall: AppTypographie.labelSmall,
    ),
  );
}
