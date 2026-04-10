import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de couleurs BudgetFlow
abstract class AppColors {
  static const Color primary = Color(0xFFFF69B4); // Rose chaud
  static const Color secondary = Color(0xFF87CEFA); // Bleu ciel
  static const Color tertiary = Color(0xFFDDA0DD); // Prune pastel
  static const Color background = Color(0xFFF8F8FF); // Blanc lavande
  static const Color surface = Color(0xFFDFDFE5); // Gris translucide

  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Color(0xFF1A1A2E);
  static const Color onBackground = Color(0xFF2D2D3A);
  static const Color onSurface = Color(0xFF2D2D3A);

  static const Color income = Color(0xFF4CAF82); // Vert menthe
  static const Color expense = Color(0xFFFF6B8A); // Rose dépense
  static const Color warning = Color(0xFFFFB347); // Orange doux
  static const Color error = Color(0xFFFF5252);

  static const Color divider = Color(0xFFEAEAF0);
  static const Color disabled = Color(0xFFBDBDC9);

  static const Color cardShadow = Color(0x14000000); // 8% noir
}

/// Thème BudgetFlow – Material 3 "cute"
class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primary.withValues(alpha: 0.15),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      onSecondaryContainer: const Color(0xFF0D4F8C),
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.2),
      onTertiaryContainer: const Color(0xFF5A275A),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.15),
      onErrorContainer: AppColors.error,
      surface: Colors.white,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surface,
      onSurfaceVariant: const Color(0xFF5A5A6E),
      outline: AppColors.divider,
      shadow: AppColors.cardShadow,
    );

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.disabled,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.disabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AppColors.disabled,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.disabled);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelSmall,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: AppColors.onBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 8,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    // Titres : Comic Neue ; Texte/UI : Nunito
    const comicNeue = GoogleFonts.comicNeue;
    const nunito = GoogleFonts.nunito;

    return TextTheme(
      displayLarge: comicNeue(fontSize: 57, fontWeight: FontWeight.w700),
      displayMedium: comicNeue(fontSize: 45, fontWeight: FontWeight.w700),
      displaySmall: comicNeue(fontSize: 36, fontWeight: FontWeight.w700),
      headlineLarge: comicNeue(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: comicNeue(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: comicNeue(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: comicNeue(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: nunito(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: nunito(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: nunito(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: nunito(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: nunito(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: nunito(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: nunito(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: nunito(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
