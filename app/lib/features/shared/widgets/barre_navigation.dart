import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_theme.dart';

class BarreNavigationBudgetFlow extends StatelessWidget {
  final int indexCourant;
  final ValueChanged<int> onChangement;

  const BarreNavigationBudgetFlow({
    super.key,
    required this.indexCourant,
    required this.onChangement,
  });

  static const List<_ElementNav> _elements = [
    _ElementNav(icone: 'assets/icons/accueil.svg', label: 'Accueil'),
    _ElementNav(icone: 'assets/icons/stat.svg', label: 'Stats'),
    _ElementNav(icone: 'assets/icons/pigmenu.svg', label: 'Épargnes'),
    _ElementNav(icone: 'assets/icons/parametre.svg', label: 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.textePrincipal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_elements.length, (i) {
              final estActif = i == indexCourant;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChangement(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: estActif
                              ? AppCouleurs.primaire.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          _elements[i].icone,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            estActif
                                ? AppCouleurs.primaire
                                : AppCouleurs.texteSecondaire,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _elements[i].label,
                        style: AppTypographie.labelSmall.copyWith(
                          color: estActif
                              ? AppCouleurs.primaire
                              : AppCouleurs.texteSecondaire,
                          fontWeight: estActif
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ElementNav {
  final String icone;
  final String label;
  const _ElementNav({required this.icone, required this.label});
}
