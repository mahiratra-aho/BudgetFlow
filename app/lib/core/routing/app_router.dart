import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/login_view.dart';
import '../../features/auth/signup_view.dart';
import '../../features/onboarding/onboarding_view.dart';
import '../../features/dashboard/dashboard_view.dart';
import '../../features/transactions/transactions_view.dart';
import '../../features/transactions/add_transaction_view.dart';
import '../../features/budgets/budgets_view.dart';
import '../../features/goals/goals_view.dart';
import '../../features/stats/stats_view.dart';
import '../../features/repetitif/repetitif_view.dart';
import '../../features/settings/manage_members_view.dart';
import '../../features/settings/manage_payment_methods_view.dart';
import '../../features/settings/settings_view.dart';
import '../auth/auth_viewmodel.dart';
import '../auth/local_user.dart';
import '../navbottom/main_navbottom.dart';

// Noms des routes
abstract class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
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
  static const managePaymentMethods = '/settings/payment-methods';
  static const manageMembers = '/settings/members';
}

// Routes accessibles sans être connecté.
const _publicRoutes = {AppRoutes.login, AppRoutes.signup};

// Notifier qui écoute authViewModelProvider et notifie GoRouter à chaque changement
// d'état (loading → data → null) pour déclencher le recalcul du redirect.
class _RouterNotifier extends Notifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    ref.listen<AsyncValue<LocalUser?>>(
      authViewModelProvider,
      (_, __) => _routerListener?.call(),
    );
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

final _routerNotifierProvider =
    NotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    // Le router se rafraîchit automatiquement à chaque changement d'état auth.
    refreshListenable: notifier,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      // 1. Auth en cours de chargement (démarrage de l'app) → rester sur splash
      //    pour éviter la race condition avec appDatabaseProvider.
      final authState = ref.read(authViewModelProvider);
      if (authState.isLoading) {
        return location == '/' ? null : '/';
      }

      final currentUser = authState.valueOrNull;
      final isLoggedIn = currentUser != null;

      // 2. Si non connecté → rediriger vers /login (sauf routes publiques)
      if (!isLoggedIn) {
        if (_publicRoutes.contains(location)) return null;
        return AppRoutes.login;
      }

      // 3. Si connecté sur la route splash ou une route publique → continuer vers l'app
      if (location == '/' || _publicRoutes.contains(location)) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone =
            prefs.getBool('onboarding_done_${currentUser.id}') ?? false;
        return onboardingDone ? AppRoutes.dashboard : AppRoutes.onboarding;
      }

      // 4. Connecté : gérer l'onboarding
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool('onboarding_done_${currentUser.id}') ?? false;
      if (!onboardingDone && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (onboardingDone && location == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Route splash (écran de chargement initial)
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupView(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingView(),
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
      GoRoute(
        path: AppRoutes.managePaymentMethods,
        builder: (_, __) => const ManagePaymentMethodsView(),
      ),
      GoRoute(
        path: AppRoutes.manageMembers,
        builder: (_, __) => const ManageMembersView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.error}'),
      ),
    ),
  );
});
