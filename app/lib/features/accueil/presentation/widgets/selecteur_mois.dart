import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class SelecteurMoisDialog extends StatefulWidget {
  final DateTime moisActuel;
  final ValueChanged<DateTime> onSelectionne;

  const SelecteurMoisDialog({
    super.key,
    required this.moisActuel,
    required this.onSelectionne,
  });

  @override
  State<SelecteurMoisDialog> createState() => _EtatSelecteurMoisDialog();
}

class _EtatSelecteurMoisDialog extends State<SelecteurMoisDialog> {
  late int _anneeAffichee;
  late DateTime _selectionActuelle;

  static const List<String> _mois = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Jun',
    'Jul',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  @override
  void initState() {
    super.initState();
    _anneeAffichee = widget.moisActuel.year;
    _selectionActuelle = widget.moisActuel;
  }

  @override
  Widget build(BuildContext context) {
    final anneeMax = DateTime.now().year;
    final moisMaxDansAnneeMax = DateTime.now().month;

    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.lg)),
      backgroundColor: AppCouleurs.surface,
      contentPadding: const EdgeInsets.all(AppEspaces.lg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _anneeAffichee--),
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppCouleurs.accentBrun),
              ),
              Text(
                '$_anneeAffichee',
                style: AppTypographie.titleSmall,
              ),
              IconButton(
                onPressed: _anneeAffichee < anneeMax
                    ? () => setState(() => _anneeAffichee++)
                    : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _anneeAffichee < anneeMax
                      ? AppCouleurs.accentBrun
                      : AppCouleurs.texteTertiaire,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppEspaces.md),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final numeroMois = i + 1;
              final estSelectionne =
                  _selectionActuelle.year == _anneeAffichee &&
                      _selectionActuelle.month == numeroMois;
              final estFutur = _anneeAffichee == anneeMax &&
                  numeroMois > moisMaxDansAnneeMax;

              return GestureDetector(
                onTap: estFutur
                    ? null
                    : () {
                        setState(() {
                          _selectionActuelle =
                              DateTime(_anneeAffichee, numeroMois);
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: estSelectionne
                        ? AppCouleurs.primaire
                        : estFutur
                            ? AppCouleurs.fondPrincipal
                            : AppCouleurs.fondSecondaire,
                    borderRadius: BorderRadius.circular(AppRayons.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _mois[i],
                    style: AppTypographie.labelMedium.copyWith(
                      color: estSelectionne
                          ? AppCouleurs.textePrincipal
                          : estFutur
                              ? AppCouleurs.texteTertiaire
                              : AppCouleurs.textePrincipal,
                      fontWeight:
                          estSelectionne ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppEspaces.lg),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppCouleurs.texteSecondaire,
                    side: BorderSide(
                        color: AppCouleurs.textePrincipal.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRayons.md)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppEspaces.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSelectionne(_selectionActuelle);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppCouleurs.primaire,
                    foregroundColor: AppCouleurs.textePrincipal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRayons.md)),
                  ),
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
