import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/montant_utils.dart';
import '../../data/models/repetitif.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../core/providers/repositories.dart';
import 'repetitif_viewmodel.dart';

class RepetitifView extends ConsumerWidget {
  const RepetitifView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(repetitifViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Répétitifs')),
      body: etat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (recurrences) => RefreshIndicator(
          onRefresh: () =>
              ref.read(repetitifViewModelProvider.notifier).refresh(),
          child: recurrences.isEmpty
              ? _EtatVideRepetitif(
                  onAdd: () => _showAddSheet(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: recurrences.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _CarteRepetitive(
                    item: recurrences[i],
                    onToggle: () => ref
                        .read(repetitifViewModelProvider.notifier)
                        .toggle(recurrences[i]),
                    onDelete: () => ref
                        .read(repetitifViewModelProvider.notifier)
                        .delete(recurrences[i].id),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle opération répétitive'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final repoCategories = ref.read(repoCategorieProvider);
    final categories = await repoCategories.obtenirToutes();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeuilleAjoutRepetitif(
        categories: categories,
        onSave: (r) => ref.read(repetitifViewModelProvider.notifier).add(r),
      ),
    );
  }
}

class _CarteRepetitive extends StatelessWidget {
  final RecurrenceModele item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CarteRepetitive({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = item.type == TypeTransaction.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.repeat_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.frequency.label,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prochain: ${_formatDate(item.nextDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '−' : '+'} ${FormatteurMontant.formatCourt(item.amount)} Ar',
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Switch(
                    value: item.isActive,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppColors.income,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _FeuilleAjoutRepetitif extends StatefulWidget {
  final List<CategorieModele> categories;
  final Future<void> Function(RecurrenceModele) onSave;

  const _FeuilleAjoutRepetitif({
    required this.categories,
    required this.onSave,
  });

  @override
  State<_FeuilleAjoutRepetitif> createState() => _FeuilleAjoutRepetitifState();
}

class _FeuilleAjoutRepetitifState extends State<_FeuilleAjoutRepetitif> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TypeTransaction _type = TypeTransaction.expense;
  String? _categoryId;
  FrequenceRecurrence _frequency = FrequenceRecurrence.monthly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _categoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un titre')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide')),
      );
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final operationRepetitive = RecurrenceModele.create(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        frequency: _frequency,
      );
      await widget.onSave(operationRepetitive);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouvelle opération répétitive',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Loyer, Netflix...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffix: Text('Ar'),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TypeTransaction>(
            segments: const [
              ButtonSegment<TypeTransaction>(
                value: TypeTransaction.expense,
                label: Text('Dépense'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
              ButtonSegment<TypeTransaction>(
                value: TypeTransaction.income,
                label: Text('Revenu'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) {
              setState(() => _type = selection.first);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FrequenceRecurrence>(
            initialValue: _frequency,
            decoration: const InputDecoration(labelText: 'Fréquence'),
            items: FrequenceRecurrence.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Créer l\'opération',
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _EtatVideRepetitif extends StatelessWidget {
  final VoidCallback onAdd;
  const _EtatVideRepetitif({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.repeat_rounded, size: 64, color: AppColors.disabled),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction répétitive',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.disabled),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une opération répétitive'),
          ),
        ],
      ),
    );
  }
}
