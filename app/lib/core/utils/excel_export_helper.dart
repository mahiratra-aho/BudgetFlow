import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/pin_dialog.dart';
import '../security/security_service.dart';
import '../../features/settings/settings_viewmodel.dart';

const _kMonthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Affiche le sélecteur de mois/année, vérifie le PIN si configuré,
/// puis lance l'export Excel automatiquement.
Future<void> afficherFluxExportExcel(
  BuildContext contexte,
  WidgetRef ref,
) async {
  // 1. Vérifier le PIN si configuré (indépendamment de securityEnabled)
  final pinDefini = await SecurityService.instance.isPinSet();
  if (pinDefini) {
    if (!contexte.mounted) return;
    final estVerifie = await PinDialog.show(
      contexte,
      title: 'Code PIN',
      subtitle: 'Saisissez votre PIN pour exporter',
    );
    if (!estVerifie || !contexte.mounted) return;
  }

  // 2. Sélection du mois/année
  final maintenant = DateTime.now();
  int moisSelectionne = maintenant.month;
  int anneeSelectionnee = maintenant.year;

  if (!contexte.mounted) return;
  final estConfirme = await showDialog<bool>(
    context: contexte,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Exporter en Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sélectionnez le mois à exporter :'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: moisSelectionne,
                    decoration: const InputDecoration(labelText: 'Mois'),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_kMonthNames[i]),
                      ),
                    ),
                    onChanged: (v) => setState(() => moisSelectionne = v!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: anneeSelectionnee.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Année'),
                    onChanged: (v) {
                      final annee = int.tryParse(v);
                      if (annee != null) anneeSelectionnee = annee;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exporter'),
          ),
        ],
      ),
    ),
  );

  if (estConfirme != true || !contexte.mounted) return;

  // 3. Lancer l'export automatiquement
  try {
    await ref.read(settingsViewModelProvider.notifier).exporterExcel(
          mois: moisSelectionne,
          annee: anneeSelectionnee,
        );
    if (contexte.mounted) {
      ScaffoldMessenger.of(contexte).showSnackBar(
        const SnackBar(content: Text('Export Excel réussi ✓')),
      );
    }
  } catch (e) {
    if (contexte.mounted) {
      ScaffoldMessenger.of(contexte).showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }
}
