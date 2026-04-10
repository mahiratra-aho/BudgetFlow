import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../core/providers/repositories.dart';
import '../../features/dashboard/dashboard_viewmodel.dart';
import '../../features/stats/stats_viewmodel.dart';
import 'transactions_viewmodel.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? editId;

  const AddTransactionScreen({super.key, this.editId});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TypeTransaction _type = TypeTransaction.expense;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  List<CategorieModele> _categories = [];
  TransactionModele? _editingTransaction;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repoCategories = ref.read(repoCategorieProvider);
    _categories = await repoCategories.obtenirToutes();

    if (widget.editId != null) {
      final repoTransactions = ref.read(repoTransactionProvider);
      final txns = await repoTransactions.obtenirTous();
      final tx = txns.firstWhere(
        (t) => t.id == widget.editId,
        orElse: () => throw Exception('Transaction introuvable'),
      );
      _editingTransaction = tx;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _type = tx.type;
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
    } else {
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories
            .where((c) => c.type == 'expense' || c.type == 'both')
            .firstOrNull
            ?.id;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repoTransactions = ref.read(repoTransactionProvider);
      final amount = double.parse(_amountController.text.replaceAll(' ', ''));

      if (_editingTransaction != null) {
        final updated = _editingTransaction!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          date: _date,
        );
        await repoTransactions.mettreAJour(updated);
      } else {
        final tx = TransactionModele.create(
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          date: _date,
        );
        await repoTransactions.ajouter(tx);
      }

      // Rafraîchir le dashboard, les statistiques et les transactions
      ref.invalidate(dashboardViewModelProvider);
      ref.invalidate(transactionsViewModelProvider);
      ref.invalidate(statsViewModelProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = _editingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier' : 'Nouvelle transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TypeToggle(
              type: _type,
              onChanged: (t) {
                setState(() {
                  _type = t;
                  final matching = _categories
                      .where((c) => c.type == t.name || c.type == 'both')
                      .toList();
                  _selectedCategoryId =
                      matching.isNotEmpty ? matching.first.id : null;
                });
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineSmall?.copyWith(
                color: _type == TypeTransaction.expense
                    ? AppColors.expense
                    : AppColors.income,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                suffix: Text(' Ar', style: theme.textTheme.titleMedium),
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.disabled,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Montant requis';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Courses, Salaire...',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Titre requis' : null,
            ),
            const SizedBox(height: 16),

            Text('Catégorie', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final filteredCategories = _categories
                    .where((c) => c.type == _type.name || c.type == 'both')
                    .toList();

                if (filteredCategories.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aucune catégorie disponible pour ce type.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return _CategorySelector(
                  categories: filteredCategories,
                  selectedId: _selectedCategoryId,
                  onSelected: (id) => setState(() => _selectedCategoryId = id),
                );
              },
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    size: 18, color: AppColors.primary),
              ),
              title: Text(
                _formatDate(_date),
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: const Text('Date de la transaction'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Ajouter une note...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              label: isEdit ? 'Modifier' : 'Ajouter la transaction',
              icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan.',
      'fév.',
      'mar.',
      'avr.',
      'mai',
      'jun.',
      'jul.',
      'aoû.',
      'sep.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _TypeToggle extends StatelessWidget {
  final TypeTransaction type;
  final ValueChanged<TypeTransaction> onChanged;

  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Dépense',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.expense,
              selected: type == TypeTransaction.expense,
              onTap: () => onChanged(TypeTransaction.expense),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Revenu',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.income,
              selected: type == TypeTransaction.income,
              onTap: () => onChanged(TypeTransaction.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<CategorieModele> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final color = Color(cat.colorValue);
        final selected = cat.id == selectedId;
        return GestureDetector(
          onTap: () => onSelected(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_rounded, color: color, size: 14),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
