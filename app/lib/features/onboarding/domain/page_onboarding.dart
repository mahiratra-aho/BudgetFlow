import 'package:flutter/widgets.dart';

class PageOnboarding {
  final String titre;
  final String description;
  final String cheminIcone;
  final Color? couleurIcone;

  const PageOnboarding({
    required this.titre,
    required this.description,
    required this.cheminIcone,
    this.couleurIcone,
  });
}
