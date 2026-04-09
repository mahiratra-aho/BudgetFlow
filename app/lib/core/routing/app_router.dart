import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/dashboard/dashboard_view.dart';
import '../../features/transactions/transactions_view.dart';
import '../../features/transactions/add_transaction_view.dart';
import '../../features/budgets/budgets_view.dart';
import '../../features/goals/goals_view.dart';
import '../../features/stats/stats_view.dart';
import '../../features/repetitif/repetitif_view.dart';
import '../../features/settings/settings_view.dart';
import '../navbottom/main_navbottom.dart';

/// Noms des routes
abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static const budgets = '/budgets';
  static const goals = '/goals';
  static const stats = '/stats';
  static const repetitif = '/repetitif';
  static const recurring = repetitif;
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (!onboardingDone && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (onboardingDone && state.matchedLocation == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const TransactionsView(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardView(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (_, __) => const TransactionsView(),
          ),
          GoRoute(
            path: AppRoutes.budgets,
            builder: (_, __) => const BudgetsView(),
          ),
          GoRoute(
            path: AppRoutes.goals,
            builder: (_, __) => const GoalsView(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsView(),
          ),
        ],
      ),
      // Écrans modaux (hors shell)
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionView(editId: extra?['editId'] as String?);
        },
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (_, __) => const StatsView(),
      ),
      GoRoute(
        path: AppRoutes.repetitif,
        builder: (_, __) => const RepetitifView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.error}'),
      ),
    ),
  );
});
