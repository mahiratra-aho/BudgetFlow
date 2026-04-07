import 'package:bugdetflowapp/features/inscription/view/view_inscription.dart';
import 'package:bugdetflowapp/noyau/theme/design_budgetflow.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BudgetFlowApp());
}

class BudgetFlowApp extends StatelessWidget {
  const BudgetFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetFlow',
      debugShowCheckedModeBanner: false,
      theme: SystemeDesignBudgetFlow.creerTheme(),
      home: const EcranInscription(),
    );
  }
}
