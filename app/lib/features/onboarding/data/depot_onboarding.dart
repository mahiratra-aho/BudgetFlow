import '../domain/page_onboarding.dart';

class DepotOnboarding {
  static const List<PageOnboarding> pages = [
    PageOnboarding(
      titre: 'Bienvenue sur\nBudgetFlow',
      description:
          'Gérez vos finances en toute simplicité.\nSuivez vos dépenses,\nplanifiez vos budgets et atteignez vos objectifs.',
      cheminIcone: 'assets/icons/wallet.svg',
    ),
    PageOnboarding(
      titre: 'Visualisez vos\ndépenses',
      description:
          'Des graphiques clairs et colorés\npour comprendre où va votre argent\nchaque mois.',
      cheminIcone: 'assets/icons/graphic.svg',
    ),
    PageOnboarding(
      titre: 'Atteignez vos\nobjectifs',
      description:
          'Définissez des objectifs d\'épargne et\nsuivez votre progression pas à pas.',
      cheminIcone: 'assets/icons/pig.svg',
    ),
    PageOnboarding(
      titre: 'BudgetFlow',
      description:
          'Vos finances en une seule application.\nSoyez serein à chaque instant.',
      cheminIcone: 'assets/icons/logo.svg',
    ),
  ];
}
