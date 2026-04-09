import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/montant_utils.dart';
import '../../../data/models/goal.dart';
import 'goals_viewmodel.dart';

class GoalsView extends ConsumerWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(goalsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs d\'épargne')),
      body: etat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (objectifs) => RefreshIndicator(
          onRefresh: () => ref.read(goalsViewModelProvider.notifier).refresh(),
          child: objectifs.isEmpty
              ? _EmptyGoals(
                  onAdd: () => _showAddGoalSheet(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: objectifs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _GoalCard(
                    goal: objectifs[i],
                    onAddAmount: () =>
                        _showAddAmountSheet(context, ref, objectifs[i]),
                    onDelete: () => ref
                        .read(goalsViewModelProvider.notifier)
                        .deleteGoal(objectifs[i].id),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel objectif'),
        backgroundColor: AppColors.tertiary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showAddGoalSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddGoalSheet(
        onSave: (g) => ref.read(goalsViewModelProvider.notifier).addGoal(g),
      ),
    );
  }

  Future<void> _showAddAmountSheet(
    BuildContext context,
    WidgetRef ref,
    ObjectifModele goal,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddAmountSheet(
        goal: goal,
        onSave: (amount) => ref
            .read(goalsViewModelProvider.notifier)
            .ajouterMontant(goal.id, amount),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final ObjectifModele goal;
  final VoidCallback onAddAmount;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddAmount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(goal.colorValue);
    final progression = goal.progression;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.savings_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.titleSmall),
                    if (goal.deadline != null)
                      Text(
                        'Avant le ${_formatDate(goal.deadline!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (goal.estAtteint)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.income, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Atteint!',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: onAddAmount,
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text('+ Ajouter'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progression,
              backgroundColor: AppColors.surface,
              color: goal.estAtteint ? AppColors.income : color,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${FormatteurMontant.formatCourt(goal.currentAmount)} Ar',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
              Text(
                '${(progression * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${FormatteurMontant.formatCourt(goal.targetAmount)} Ar',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(ObjectifModele) onSave;

  const _AddGoalSheet({required this.onSave});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  int _selectedColorIndex = 0;
  bool _isSaving = false;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    Color(0xFF80CBC4),
    Color(0xFFFFB347),
    Color(0xFF81C784),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un nom d’objectif')),
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

    setState(() => _isSaving = true);
    try {
      final goal = ObjectifModele.create(
        name: _nameController.text.trim(),
        targetAmount: amount,
        icon: 'savings',
        colorValue: _colors[_selectedColorIndex].toARGB32(),
        deadline: _deadline,
      );
      await widget.onSave(goal);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: $e')),
      );
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
          Text('Nouvel objectif', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'objectif',
              hintText: 'Ex: Vacances, Voiture...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Montant cible',
              suffix: Text('Ar'),
            ),
          ),
          const SizedBox(height: 12),
          // Couleur
          Text('Couleur', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_colors.length, (i) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _colors[i],
                    shape: BoxShape.circle,
                    border: _selectedColorIndex == i
                        ? Border.all(
                            color: AppColors.onBackground,
                            width: 2,
                          )
                        : null,
                  ),
                  child: _selectedColorIndex == i
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded, color: AppColors.primary),
            title: Text(
              _deadline == null
                  ? 'Pas de date limite'
                  : 'Avant le ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    _deadline ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Créer l\'objectif',
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _AddAmountSheet extends StatefulWidget {
  final ObjectifModele goal;
  final Future<void> Function(double) onSave;

  const _AddAmountSheet({required this.goal, required this.onSave});

  @override
  State<_AddAmountSheet> createState() => _AddAmountSheetState();
}

class _AddAmountSheetState extends State<_AddAmountSheet> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(widget.goal.colorValue);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ajouter à "${widget.goal.name}"',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Montant à ajouter',
              suffix: const Text('Ar'),
              prefixIcon: Icon(Icons.add_rounded, color: color),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Ajouter',
            isLoading: _isSaving,
            onPressed: () async {
              final amount = double.tryParse(_controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez saisir un montant valide')),
                );
                return;
              }
              setState(() => _isSaving = true);
              try {
                await widget.onSave(amount);
                if (!mounted) return;
                Navigator.pop(this.context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de l’ajout: $e')),
                );
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.savings_rounded,
              size: 64, color: AppColors.disabled),
          const SizedBox(height: 16),
          Text(
            'Aucun objectif d\'épargne',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.disabled),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer mon premier objectif'),
          ),
        ],
      ),
    );
  }
}
