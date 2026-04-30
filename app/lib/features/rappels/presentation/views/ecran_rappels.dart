import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import 'ecran_ajout_rappel.dart';

const _cleRappels = 'rappels_budgetflow';

class EcranRappels extends StatefulWidget {
  const EcranRappels({super.key});

  @override
  State<EcranRappels> createState() => _EtatEcranRappels();
}

class _EtatEcranRappels extends State<EcranRappels> {
  List<EntiteSimple> _items = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await DepotEntitesSimples.instance.lireTous(_cleRappels);
    if (!mounted) {
      return;
    }
    setState(() => _items = data);
  }

  Future<void> _ouvrirForm([EntiteSimple? item]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EcranAjoutRappel(itemExistant: item)),
    );
    if (ok == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: const AppBarBudgetFlow(titre: 'Rappels'),
      body: _items.isEmpty
          ? const Center(child: Text('Aucun rappel'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppEspaces.lg),
              itemBuilder: (_, i) {
                final item = _items[i];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppCouleurs.erreur,
                      borderRadius: BorderRadius.circular(AppRayons.md),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppCouleurs.texteInverse),
                  ),
                  confirmDismiss: (_) async {
                    await DepotEntitesSimples.instance.supprimer(_cleRappels, item.id);
                    _charger();
                    return false;
                  },
                  child: ListTile(
                    onTap: () => _ouvrirForm(item),
                    tileColor: AppCouleurs.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRayons.md)),
                    title: Text(item.nom),
                    subtitle: Text(_resume(item.detail)),
                    trailing: Switch(
                      value: _actif(item.detail),
                      onChanged: (v) async {
                        final maj = _majActif(item, v);
                        await DepotEntitesSimples.instance.mettreAJour(_cleRappels, maj);
                        _charger();
                      },
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _items.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirForm(),
        backgroundColor: AppCouleurs.primaire,
        child: const Icon(Icons.add_rounded, color: AppCouleurs.textePrincipal),
      ),
    );
  }

  bool _actif(String? raw) {
    try {
      final map = jsonDecode(raw ?? '') as Map<String, dynamic>;
      return map['actif'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  String _resume(String? raw) {
    try {
      final map = jsonDecode(raw ?? '') as Map<String, dynamic>;
      final heure = map['heure'] as String? ?? '--:--';
      final jours = (map['jours'] as List<dynamic>? ?? const []).cast<int>();
      if (jours.isEmpty) {
        return 'Heure: $heure';
      }
      const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
      final txt = jours.where((j) => j >= 1 && j <= 7).map((j) => labels[j - 1]).join(', ');
      return 'Heure: $heure  |  Jours: $txt';
    } catch (_) {
      return raw ?? '';
    }
  }

  EntiteSimple _majActif(EntiteSimple item, bool actif) {
    try {
      final map = jsonDecode(item.detail ?? '') as Map<String, dynamic>;
      map['actif'] = actif;
      return item.copyWith(detail: jsonEncode(map));
    } catch (_) {
      return item.copyWith(detail: jsonEncode({'heure': item.detail ?? '', 'jours': <int>[], 'actif': actif}));
    }
  }
}
