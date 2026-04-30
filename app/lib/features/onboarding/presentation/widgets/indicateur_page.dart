import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class IndicateurPage extends StatelessWidget {
  final int nombrePages;
  final int indexCourant;

  const IndicateurPage({
    super.key,
    required this.nombrePages,
    required this.indexCourant,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        nombrePages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == indexCourant ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: index == indexCourant
                ? AppCouleurs.primaire
                : AppCouleurs.accentBrun,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}
