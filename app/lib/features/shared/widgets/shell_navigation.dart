import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../accueil/presentation/views/ecran_accueil.dart';
import '../../budgets/presentation/views/ecran_budgets.dart';
import '../../epargnes/presentation/views/ecran_epargnes.dart';
import '../../parametres/presentation/views/ecran_parametres.dart';
import '../../statistiques/presentation/views/ecran_statistiques.dart';
import '../../transactions/ajout/presentation/views/ecran_ajout_transaction.dart';
import '../../transactions/liste/presentation/views/ecran_liste_transactions.dart';
import 'barre_navigation.dart';

final _indexOngletProvider = StateProvider<int>((ref) => 0);

class ShellNavigation extends ConsumerWidget {
  const ShellNavigation({super.key});

  void _ouvrirAjout(BuildContext context) {
    // Builder garantit que le context descendant a un ProviderScope ancêtre
    final container = ProviderScope.containerOf(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderScope(
        parent: container,
        child: const EcranAjoutTransaction(),
      ),
      fullscreenDialog: true,
    ));
  }

  void _ouvrirListeTransactions(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderScope(
        parent: container,
        child: EcranListeTransactions(
          onAjouterTransaction: () => _ouvrirAjout(context),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_indexOngletProvider);

    final onglets = [
      EcranAccueil(
        onAjouterTransaction: () => _ouvrirAjout(context),
        onVoirTransactions: () => _ouvrirListeTransactions(context),
      ),
      const EcranStatistiques(),
      EcranEpargnes(onAjouterEpargne: () {}),
      const EcranParametres(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: onglets),
      bottomNavigationBar: BarreNavigationBudgetFlow(
        indexCourant: index,
        onChangement: (i) => ref.read(_indexOngletProvider.notifier).state = i,
      ),
    );
  }
}
