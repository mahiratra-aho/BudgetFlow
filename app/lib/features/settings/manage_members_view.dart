import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/member.dart';

// ── Couleurs prédéfinies ────────────────────────────────────────────────────

const _kCouleurs = <Color>[
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF3F51B5),
  Color(0xFF2196F3),
  Color(0xFF00BCD4),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFFF44336),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFF009688),
  Color(0xFFFF5722),
  Color(0xFF8BC34A),
  Color(0xFFFFEB3B),
  Color(0xFF9E9E9E),
];

// ── Écran principal ─────────────────────────────────────────────────────────

class ManageMembersView extends ConsumerStatefulWidget {
  const ManageMembersView({super.key});

  @override
  ConsumerState<ManageMembersView> createState() => _ManageMembersViewState();
}

class _ManageMembersViewState extends ConsumerState<ManageMembersView> {
  List<MembreModele> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final repo = ref.read(repoMembreProvider);
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
    final repo = ref.read(repoMembreProvider);
    final sortOrder = _items.isEmpty ? 0 : _items.last.sortOrder + 1;
    final nouveau = MembreModele.create(
      name: result['name'] as String,
      colorValue: result['colorValue'] as int,
      sortOrder: sortOrder,
    );
    await repo.ajouter(nouveau);
    await _charger();
  }

  Future<void> _modifier(MembreModele item) async {
    final result = await _showDialog(context, item);
    if (result == null) return;
    final repo = ref.read(repoMembreProvider);
    final updated = item.copyWith(
      name: result['name'] as String,
      colorValue: result['colorValue'] as int,
    );
    await repo.mettreAJour(updated);
    await _charger();
  }

  Future<void> _supprimer(MembreModele item) async {
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
    await ref.read(repoMembreProvider).supprimerLogiquement(item.id);
    await _charger();
  }

  Future<void> _reordonner(int ancienIndex, int nouvelIndex) async {
    if (nouvelIndex > ancienIndex) nouvelIndex -= 1;
    final liste = [..._items];
    final item = liste.removeAt(ancienIndex);
    liste.insert(nouvelIndex, item);
    setState(() => _items = liste);
    await ref
        .read(repoMembreProvider)
        .reordonner(liste.map((e) => e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_rounded,
                          size: 48, color: AppColors.disabled),
                      const SizedBox(height: 12),
                      Text('Aucun membre',
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
                          leading: CircleAvatar(
                            backgroundColor: couleur.withValues(alpha: 0.2),
                            child: Text(
                              item.name.isNotEmpty
                                  ? item.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: couleur,
                                fontWeight: FontWeight.w700,
                              ),
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
  MembreModele? existing,
) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _MemberDialog(existing: existing),
  );
}

class _MemberDialog extends StatefulWidget {
  final MembreModele? existing;
  const _MemberDialog({this.existing});

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _nameCtrl;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
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
      title: Text(widget.existing == null ? 'Nouveau membre' : 'Modifier'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Ex: Alice, Bob...',
            ),
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
                onTap: () => setState(() => _selectedColorValue = c.toARGB32()),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border:
                        sel ? Border.all(color: Colors.white, width: 2) : null,
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
              'colorValue': _selectedColorValue,
            });
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
