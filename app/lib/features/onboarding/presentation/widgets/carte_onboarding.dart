import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/page_onboarding.dart';

class CarteOnboarding extends StatelessWidget {
  final PageOnboarding pageOnboarding;

  const CarteOnboarding({
    super.key,
    required this.pageOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppEspaces.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _construireIllustration(),
          const SizedBox(height: AppEspaces.xxl),

          Text(
            pageOnboarding.titre,
            style: AppTypographie.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppEspaces.lg),

          Text(
            pageOnboarding.description,
            style: AppTypographie.bodyMedium.copyWith(
              color: AppCouleurs.texteSecondaire,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _construireIllustration() {
    return SizedBox(
      width: 160,
      height: 160,
      child: SvgPicture.asset(
        pageOnboarding.cheminIcone,
        fit: BoxFit.contain,
      ),
    );
  }
}
