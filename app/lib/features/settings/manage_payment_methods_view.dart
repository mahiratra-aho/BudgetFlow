import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/payment_method.dart';

// ── Couleurs prédéfinies ────────────────────────────────────────────────────

const _kCouleurs = <Color>[
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFF607D8B),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFF795548),
  Color(0xFFF44336),
  Color(0xFF3F51B5),
  Color(0xFF009688),
  Color(0xFFFF5722),
  Color(0xFF8BC34A),
  Color(0xFFFFEB3B),
  Color(0xFF9E9E9E),
];

// ── Icônes prédéfinies ──────────────────────────────────────────────────────

const _kIcones = <Map<String, dynamic>>[
  {'name': 'payments', 'icon': Icons.payments_rounded},
  {'name': 'credit_card', 'icon': Icons.credit_card_rounded},
  {'name': 'smartphone', 'icon': Icons.smartphone_rounded},
  {'name': 'account_balance', 'icon': Icons.account_balance_rounded},
  {'name': 'edit_document', 'icon': Icons.edit_document},
  {'name': 'contactless', 'icon': Icons.contactless_rounded},
  {'name': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
  {'name': 'qr_code', 'icon': Icons.qr_code_rounded},
  {'name': 'receipt', 'icon': Icons.receipt_rounded},
  {'name': 'store', 'icon': Icons.store_rounded},
  {'name': 'atm', 'icon': Icons.atm_rounded},
  {'name': 'money', 'icon': Icons.monetization_on_rounded},
];

IconData _iconDataFromName(String name) {
  final match = _kIcones.where((e) => e['name'] == name).firstOrNull;
  if (match != null) return match['icon'] as IconData;
  return Icons.payments_rounded;
}

// ── Écran principal ─────────────────────────────────────────────────────────

class ManagePaymentMethodsView extends ConsumerStatefulWidget {
  const ManagePaymentMethodsView({super.key});

  @override
  ConsumerState<ManagePaymentMethodsView> createState() =>
      _ManagePaymentMethodsViewState();
}

class _ManagePaymentMethodsViewState
    extends ConsumerState<ManagePaymentMethodsView> {
  List<MoyenPaiementModele> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final repo = ref.read(repoMoyenPaiementProvider);
    final items = await repo.obtenirTous();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _ajouter() async {
    final result = await _showDialog(context, null);
    if (result == null) return;
    final repo = ref.read(repoMoyenPaiementProvider);
    final sortOrder = _items.isEmpty ? 0 : _items.last.sortOrder + 1;
    final nouveau = MoyenPaiementModele.create(
      name: result['name'] as String,
      icon: result['icon'] as String,
      colorValue: result['colorValue'] as int,
      sortOrder: sortOrder,
    );
    await repo.ajouter(nouveau);
    await _charger();
  }

  Future<void> _modifier(MoyenPaiementModele item) async {
    final result = await _showDialog(context, item);
    if (result == null) return;
    final repo = ref.read(repoMoyenPaiementProvider);
    final updated = item.copyWith(
      name: result['name'] as String,
      icon: result['icon'] as String,
      colorValue: result['colorValue'] as int,
    );
    await repo.mettreAJour(updated);
    await _charger();
  }

  Future<void> _supprimer(MoyenPaiementModele item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${item.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repoMoyenPaiementProvider).supprimerLogiquement(item.id);
    await _charger();
  }

  Future<void> _reordonner(int ancienIndex, int nouvelIndex) async {
    if (nouvelIndex > ancienIndex) nouvelIndex -= 1;
    final liste = [..._items];
    final item = liste.removeAt(ancienIndex);
    liste.insert(nouvelIndex, item);
    setState(() => _items = liste);
    await ref
        .read(repoMoyenPaiementProvider)
        .reordonner(liste.map((e) => e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moyens de paiement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_rounded,
                          size: 48, color: AppColors.disabled),
                      const SizedBox(height: 12),
                      Text('Aucun moyen de paiement',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  onReorder: _reordonner,
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    final couleur = Color(item.colorValue);
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: couleur.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconDataFromName(item.icon),
                              color: couleur,
                              size: 20,
                            ),
                          ),
                          title: Text(item.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () => _modifier(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.error),
                                onPressed: () => _supprimer(item),
                              ),
                              const Icon(Icons.drag_handle_rounded,
                                  color: AppColors.disabled),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// ── Dialogue ajout / modification ───────────────────────────────────────────

Future<Map<String, dynamic>?> _showDialog(
  BuildContext context,
  MoyenPaiementModele? existing,
) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _PaymentMethodDialog(existing: existing),
  );
}

class _PaymentMethodDialog extends StatefulWidget {
  final MoyenPaiementModele? existing;
  const _PaymentMethodDialog({this.existing});

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? _kIcones.first['name'] as String;
    _selectedColorValue =
        widget.existing?.colorValue ?? _kCouleurs.first.toARGB32();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nouveau moyen' : 'Modifier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Carte, Espèces...',
              ),
            ),
            const SizedBox(height: 16),
            Text('Icône', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kIcones.map((e) {
                final name = e['name'] as String;
                final icon = e['icon'] as IconData;
                final sel = name == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: sel ? AppColors.primary : AppColors.disabled),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Couleur', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kCouleurs.map((c) {
                final sel = c.toARGB32() == _selectedColorValue;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColorValue = c.toARGB32()),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.6),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              'name': name,
              'icon': _selectedIcon,
              'colorValue': _selectedColorValue,
            });
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
