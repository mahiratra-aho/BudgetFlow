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

// Affiche le sélecteur de mois/année, vérifie le PIN si configuré,
// puis lance l'export Excel automatiquement.
Future<void> showExcelExportFlow(BuildContext context, WidgetRef ref) async {
  // 1. Vérifier le PIN si configuré (indépendamment de securityEnabled)
  final pinSet = await SecurityService.instance.isPinSet();
  if (pinSet) {
    if (!context.mounted) return;
    final verified = await PinDialog.show(
      context,
      title: 'Code PIN',
      subtitle: 'Saisissez votre PIN pour exporter',
    );
    if (!verified || !context.mounted) return;
  }

  // 2. Sélection du mois/année
  final now = DateTime.now();
  int selectedMonth = now.month;
  int selectedYear = now.year;

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
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
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(labelText: 'Mois'),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_kMonthNames[i]),
                      ),
                    ),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: selectedYear.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Année'),
                    onChanged: (v) {
                      final y = int.tryParse(v);
                      if (y != null) selectedYear = y;
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

  if (confirmed != true || !context.mounted) return;

  // 3. Lancer l'export automatiquement
  try {
    await ref
        .read(settingsViewModelProvider.notifier)
        .exportExcel(month: selectedMonth, year: selectedYear);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export Excel réussi ✓')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }
}
