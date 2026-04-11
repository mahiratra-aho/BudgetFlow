import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/pin_dialog.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/excel_export_helper.dart';
import '../../core/widgets/app_card.dart';
import 'settings_viewmodel.dart';
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête
            _ProfileHeader(),
            const SizedBox(height: 20),

            // Section Sécurité
            const _SectionTitle('Sécurité'),
            AppCard(
              child: Column(
                children: [
                  // Web info banner
                  if (kIsWeb)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.secondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sur le Web, la biométrie n\'est pas disponible. '
                              'Seul le PIN est supporté.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF0D4F8C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Sécurité activée
                  SwitchListTile(
                    title: const Text('Activer la sécurité'),
                    subtitle: const Text('Protéger les actions sensibles'),
                    value: settings.securityEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: settings.pinSet
                        ? (v) => ref
                            .read(settingsViewModelProvider.notifier)
                            .setSecurityEnabled(v)
                        : null,
                    secondary: const Icon(Icons.security_rounded),
                  ),
                  const Divider(indent: 56),
                  // Biométrie (Android uniquement)
                  if (!kIsWeb && settings.biometricAvailable)
                    ListTile(
                      leading: const Icon(Icons.fingerprint_rounded),
                      title: const Text('Biométrie'),
                      subtitle: const Text('Utiliser l\'empreinte digitale'),
                      trailing: settings.securityEnabled
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.income)
                          : const Icon(Icons.circle_outlined,
                              color: AppColors.disabled),
                    ),
                  if (!kIsWeb && settings.biometricAvailable)
                    const Divider(indent: 56),
                  // Configurer PIN
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: Text(
                      settings.pinSet ? 'Modifier le PIN' : 'Configurer le PIN',
                    ),
                    subtitle: Text(
                      settings.pinSet
                          ? 'PIN configuré ✓'
                          : 'Aucun PIN configuré',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _setupPin(context, ref),
                  ),
                  if (settings.pinSet) ...[
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.error),
                      title: const Text(
                        'Supprimer le PIN',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => _confirmDeletePin(context, ref),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Gestion
            const _SectionTitle('Gestion'),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.payments_rounded),
                    title: const Text('Moyens de paiement'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        context.push(AppRoutes.managePaymentMethods),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.group_rounded),
                    title: const Text('Membres'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.manageMembers),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Données
            const _SectionTitle('Données'),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded),
                    title: const Text('Statistiques'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.stats),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.repeat_rounded),
                    title: const Text('Répétitifs'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.repetitif),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Import / Export
            const _SectionTitle('Import / Export'),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.table_view_rounded),
                    title: const Text('Exporter (Excel)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showExcelExportFlow(context, ref),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.upload_file_rounded),
                    title: const Text('Importer (Excel)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _importExcel(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section À propos
            const _SectionTitle('À propos'),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    trailing: Text(
                      settings.appVersion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Divider(indent: 56),
                  const ListTile(
                    leading: Icon(Icons.account_balance_wallet_rounded),
                    title: Text('BudgetFlow'),
                    subtitle: Text(
                      'Application de gestion budgétaire offline-first',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Compte
            const _SectionTitle('Compte'),
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous serez redirigé vers l\'écran de connexion. '
          'Vos données locales restent intactes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authViewModelProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  Future<void> _setupPin(BuildContext context, WidgetRef ref) async {
    final ok = await PinDialog.show(
      context,
      title: 'Créer un PIN',
      subtitle: 'Choisissez un code PIN à 4 chiffres',
      confirmMode: true,
    );
    if (ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN configuré avec succès ✓')),
        );
      }
      ref.invalidate(settingsViewModelProvider);
    }
  }

  Future<void> _confirmDeletePin(BuildContext context, WidgetRef ref) async {
    // Vérifier d'abord l'ancien PIN
    final verified = await PinDialog.show(
      context,
      title: 'Confirmation',
      subtitle: 'Saisissez votre PIN actuel pour le supprimer',
    );
    if (!verified || !context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le PIN ?'),
        content: const Text(
          'La sécurité sera désactivée. Vous pourrez la reconfigurer à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(settingsViewModelProvider.notifier).clearPin();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN supprimé')),
        );
      }
    }
  }

  // ─── Import Excel ──────────────────────────────────────────────────────

  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    try {
      final preview = await ref
          .read(settingsViewModelProvider.notifier)
          .pickAndPreviewExcel();
      if (preview == null || !context.mounted) return;

      // Afficher une boîte de confirmation avec le résumé avant d'importer.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer l\'import'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${preview.transactions.length} transaction(s)'),
              Text('${preview.budgets.length} budget(s)'),
              Text('${preview.goals.length} objectif(s)'),
              if (preview.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview.warnings.join('\n'),
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final count = await ref
          .read(settingsViewModelProvider.notifier)
          .applyExcelImport(preview);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import terminé : $count élément(s) importé(s) ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur import : $e')),
        );
      }
    }
  }
}

class _ProfileHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.valueOrNull;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.pseudo ?? 'BudgetFlow',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                user?.email ?? 'Mode hors-ligne',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
