import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/depot_onboarding.dart';
import '../../domain/page_onboarding.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PageController controleurPage;
  int _indexCourant = 0;

  OnboardingViewModel() : controleurPage = PageController();

  int get indexCourant => _indexCourant;

  List<PageOnboarding> get pages => DepotOnboarding.pages;

  bool get estDernierePage => _indexCourant == pages.length - 1;

  void pageSuivante() {
    if (!estDernierePage) {
      controleurPage.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void passer() {
    controleurPage.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void mettreAJourIndex(int index) {
    _indexCourant = index;
    notifyListeners();
  }

  @override
  void dispose() {
    controleurPage.dispose();
    super.dispose();
  }
}

final onboardingViewModelProvider =
    ChangeNotifierProvider<OnboardingViewModel>((ref) {
  return OnboardingViewModel();
});
