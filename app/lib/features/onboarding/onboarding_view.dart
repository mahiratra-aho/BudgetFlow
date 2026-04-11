import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/local_auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/primary_button.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.primary,
      title: 'Bienvenue sur\nBudgetFlow',
      description:
          'Gérez vos finances en toute simplicité. Suivez vos dépenses, planifiez vos budgets et atteignez vos objectifs.',
    ),
    _OnboardingPage(
      icon: Icons.pie_chart_rounded,
      color: AppColors.secondary,
      title: 'Visualisez vos\ndépenses',
      description:
          'Des graphiques clairs et colorés pour comprendre où va votre argent chaque mois.',
    ),
    _OnboardingPage(
      icon: Icons.savings_rounded,
      color: AppColors.tertiary,
      title: 'Atteignez vos\nobjectifs',
      description:
          'Définissez des objectifs d\'épargne et suivez votre progression pas à pas.',
    ),
    _OnboardingPage(
      icon: Icons.security_rounded,
      color: Color(0xFF80CBC4),
      title: 'Sécurité\navant tout',
      description:
          'Vos données restent sur votre appareil. Protégez l\'accès avec un PIN ou votre empreinte digitale.',
    ),
  ];

  Future<void> _finish() async {
    final user = await LocalAuthService.instance.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final key = user != null ? 'onboarding_done_${user.id}' : 'onboarding_done';
    await prefs.setBool(key, true);
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Passer'),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPageWidget(page: _pages[i]),
              ),
            ),
            // Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _currentPage < _pages.length - 1
                  ? PrimaryButton(
                      label: 'Suivant',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Commencer',
                      onPressed: _finish,
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration placeholder
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.color.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    page.icon,
                    size: 80,
                    color: page.color,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  page.title,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
