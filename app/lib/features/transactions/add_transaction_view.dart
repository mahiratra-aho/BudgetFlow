import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/category.dart';
import '../../data/models/member.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_attachment.dart';
import '../../core/providers/repositories.dart';
import '../../features/dashboard/dashboard_viewmodel.dart';
import '../../features/stats/stats_viewmodel.dart';
import 'transactions_viewmodel.dart';

// ── Pièce jointe en attente (non encore persistée en DB) ───────────────────

class _PendingFile {
  final String tempPath;
  final String mimeType;
  final String displayName;

  const _PendingFile({
    required this.tempPath,
    required this.mimeType,
    required this.displayName,
  });
}

// ── Copie vers BudgetFlow/Receipts/ ────────────────────────────────────────

Future<String> _copierVersReceipts(String sourcePath, String mimeType) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final receiptsDir = Directory(p.join(docsDir.path, 'BudgetFlow', 'Receipts'));
  await receiptsDir.create(recursive: true);
  final ext = mimeType.contains('pdf') ? 'pdf' : 'jpg';
  final filename = '${const Uuid().v4()}.$ext';
  final dest = p.join(receiptsDir.path, filename);
  await File(sourcePath).copy(dest);
  return dest;
}

// ── Widget principal ────────────────────────────────────────────────────────

class AddTransactionView extends ConsumerStatefulWidget {
  final String? editId;

  const AddTransactionView({super.key, this.editId});

  @override
  ConsumerState<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends ConsumerState<AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TypeTransaction _type = TypeTransaction.expense;
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  List<CategorieModele> _categories = [];
  List<MoyenPaiementModele> _paymentMethods = [];
  List<MembreModele> _allMembers = [];
  List<String> _selectedMemberIds = [];

  // Pièces jointes existantes (en mode édition)
  List<PieceJointeModele> _existingAttachments = [];
  // IDs à supprimer de la DB lors de la sauvegarde
  final List<PieceJointeModele> _attachmentsToDelete = [];
  // Fichiers ajoutés dans cette session (pas encore en DB)
  final List<_PendingFile> _pendingFiles = [];

  TransactionModele? _editingTransaction;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repoCategories = ref.read(repoCategorieProvider);
    final repoPayment = ref.read(repoMoyenPaiementProvider);
    final repoMembres = ref.read(repoMembreProvider);

    final results = await Future.wait([
      repoCategories.obtenirToutes(),
      repoPayment.obtenirTous(),
      repoMembres.obtenirTous(),
    ]);

    _categories = results[0] as List<CategorieModele>;
    _paymentMethods = results[1] as List<MoyenPaiementModele>;
    _allMembers = results[2] as List<MembreModele>;

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
      _selectedPaymentMethodId = tx.paymentMethodId;
      _date = tx.date;

      // Charger membres et pièces jointes existants
      final [membres, piecesJointes] = await Future.wait([
        repoTransactions.obtenirMembres(tx.id),
        repoTransactions.obtenirPiecesJointes(tx.id),
      ]);
      _selectedMemberIds =
          (membres as List<MembreModele>).map((m) => m.id).toList();
      _existingAttachments = piecesJointes as List<PieceJointeModele>;
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

  // ── Caméra / galerie / PDF ──────────────────────────────────────────────

  Future<void> _prendrePhoto() async {
    if (kIsWeb) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;
    _ajouterFichierEnAttente(image.path, 'image/jpeg', p.basename(image.path));
  }

  Future<void> _choisirImage() async {
    if (kIsWeb) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    _ajouterFichierEnAttente(image.path, 'image/jpeg', p.basename(image.path));
  }

  Future<void> _choisirPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final sourcePath = file.path;
    if (sourcePath == null) return;
    _ajouterFichierEnAttente(sourcePath, 'application/pdf', file.name);
  }

  void _ajouterFichierEnAttente(
      String path, String mimeType, String displayName) {
    setState(() {
      _pendingFiles.add(_PendingFile(
        tempPath: path,
        mimeType: mimeType,
        displayName: displayName,
      ));
    });
  }

  void _supprimerPendingFile(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  void _marquerPourSuppression(PieceJointeModele pj) {
    setState(() {
      _attachmentsToDelete.add(pj);
      _existingAttachments.removeWhere((e) => e.id == pj.id);
    });
  }

  // ── Sauvegarde ──────────────────────────────────────────────────────────

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

      String transactionId;

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
          paymentMethodId: _selectedPaymentMethodId,
        );
        await repoTransactions.mettreAJour(updated);
        transactionId = updated.id;
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
          paymentMethodId: _selectedPaymentMethodId,
        );
        await repoTransactions.ajouter(tx);
        transactionId = tx.id;
      }

      // Membres
      await repoTransactions.definirMembres(transactionId, _selectedMemberIds);

      // Supprimer les pièces jointes marquées
      for (final pj in _attachmentsToDelete) {
        try {
          await File(pj.path).delete();
        } catch (_) {}
        await repoTransactions.supprimerPieceJointe(pj.id);
      }

      // Copier et enregistrer les nouveaux fichiers (uniquement sur mobile)
      if (!kIsWeb) {
        for (final pending in _pendingFiles) {
          final destPath =
              await _copierVersReceipts(pending.tempPath, pending.mimeType);
          final pj = PieceJointeModele.create(
            transactionId: transactionId,
            path: destPath,
            mimeType: pending.mimeType,
          );
          await repoTransactions.ajouterPieceJointe(pj);
        }
      }

      // Rafraîchir les providers
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

            // ── Moyen de paiement ────────────────────────────────────────
            if (_paymentMethods.isNotEmpty) ...[
              Text('Moyen de paiement', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _PaymentMethodSelector(
                paymentMethods: _paymentMethods,
                selectedId: _selectedPaymentMethodId,
                onSelected: (id) =>
                    setState(() => _selectedPaymentMethodId = id),
              ),
              const SizedBox(height: 16),
            ],

            // ── Membres ──────────────────────────────────────────────────
            if (_allMembers.isNotEmpty) ...[
              Text('Membres', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _MembersSelector(
                members: _allMembers,
                selectedIds: _selectedMemberIds,
                onToggle: (id) {
                  setState(() {
                    if (_selectedMemberIds.contains(id)) {
                      _selectedMemberIds.remove(id);
                    } else {
                      _selectedMemberIds.add(id);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Ajouter une note...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // ── Section Tickets ──────────────────────────────────────────
            _TicketsSection(
              existingAttachments: _existingAttachments,
              pendingFiles: _pendingFiles,
              onPrendrePhoto: _prendrePhoto,
              onChoisirImage: _choisirImage,
              onChoisirPDF: _choisirPDF,
              onDeleteExisting: _marquerPourSuppression,
              onDeletePending: _supprimerPendingFile,
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

// ── Sélecteur de moyen de paiement ─────────────────────────────────────────

class _PaymentMethodSelector extends StatelessWidget {
  final List<MoyenPaiementModele> paymentMethods;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _PaymentMethodSelector({
    required this.paymentMethods,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Chip "Aucun" pour désélectionner
        GestureDetector(
          onTap: () => onSelected(null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedId == null
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    selectedId == null ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              'Aucun',
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    selectedId == null ? AppColors.primary : AppColors.disabled,
                fontWeight:
                    selectedId == null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        ...paymentMethods.map((pm) {
          final color = Color(pm.colorValue);
          final selected = pm.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(pm.id),
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
                  Icon(Icons.payments_rounded, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    pm.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Sélecteur de membres (multi-select chips) ───────────────────────────────

class _MembersSelector extends StatelessWidget {
  final List<MembreModele> members;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _MembersSelector({
    required this.members,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: members.map((m) {
        final color = Color(m.colorValue);
        final selected = selectedIds.contains(m.id);
        return GestureDetector(
          onTap: () => onToggle(m.id),
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
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle_rounded,
                        color: color, size: 14),
                  ),
                Text(
                  m.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

// ── Section Tickets ─────────────────────────────────────────────────────────

class _TicketsSection extends StatelessWidget {
  final List<PieceJointeModele> existingAttachments;
  final List<_PendingFile> pendingFiles;
  final VoidCallback onPrendrePhoto;
  final VoidCallback onChoisirImage;
  final VoidCallback onChoisirPDF;
  final ValueChanged<PieceJointeModele> onDeleteExisting;
  final ValueChanged<int> onDeletePending;

  const _TicketsSection({
    required this.existingAttachments,
    required this.pendingFiles,
    required this.onPrendrePhoto,
    required this.onChoisirImage,
    required this.onChoisirPDF,
    required this.onDeleteExisting,
    required this.onDeletePending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = existingAttachments.isNotEmpty || pendingFiles.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tickets', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),

          // Boutons d'ajout (caméra et galerie uniquement sur mobile)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!kIsWeb) ...[
                _TicketButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Prendre une photo',
                  onTap: onPrendrePhoto,
                ),
                _TicketButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Choisir une image',
                  onTap: onChoisirImage,
                ),
              ],
              _TicketButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Choisir un PDF',
                onTap: onChoisirPDF,
              ),
            ],
          ),

          // Liste des pièces jointes
          if (hasItems) ...[
            const SizedBox(height: 12),
            // Pièces jointes existantes (mode édition)
            ...existingAttachments.map((pj) => _AttachmentRow(
                  path: pj.path,
                  mimeType: pj.mimeType,
                  onDelete: () => onDeleteExisting(pj),
                )),
            // Fichiers en attente (ajoutés cette session)
            ...pendingFiles.asMap().entries.map(
                  (entry) => _AttachmentRow(
                    path: entry.value.tempPath,
                    mimeType: entry.value.mimeType,
                    onDelete: () => onDeletePending(entry.key),
                    isPending: true,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _TicketButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TicketButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final String path;
  final String mimeType;
  final VoidCallback onDelete;
  final bool isPending;

  const _AttachmentRow({
    required this.path,
    required this.mimeType,
    required this.onDelete,
    this.isPending = false,
  });

  bool get _isPdf => mimeType.contains('pdf');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filename = path.split('/').last;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (_isPdf)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.error, size: 24),
            )
          else if (!kIsWeb)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.disabled),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image_rounded,
                  color: AppColors.disabled, size: 24),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (isPending)
                  Text(
                    'En attente d\'enregistrement',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
