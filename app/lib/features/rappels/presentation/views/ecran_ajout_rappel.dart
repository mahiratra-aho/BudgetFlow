import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/widgets/bouton_primaire.dart';
import '../../../shared/utils/depot_entites_simples.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../../shared/widgets/champ_formulaire.dart';

const _cleRappels = 'rappels_budgetflow';

class EcranAjoutRappel extends StatefulWidget {
  final EntiteSimple? itemExistant;
  const EcranAjoutRappel({super.key, this.itemExistant});

  @override
  State<EcranAjoutRappel> createState() => _EtatEcranAjoutRappel();
}

class _EtatEcranAjoutRappel extends State<EcranAjoutRappel> {
  late final TextEditingController _titreCtrl;
  late final TextEditingController _heureCtrl;
  final Set<int> _jours = {};
  bool _actif = true;
  bool _repeter = false;
  String? _errTitre;
  String? _errHeure;

  @override
  void initState() {
    super.initState();
    final detail = _DetailRappel.fromRaw(widget.itemExistant?.detail);
    _titreCtrl = TextEditingController(text: widget.itemExistant?.nom ?? '');
    _heureCtrl = TextEditingController(text: detail.heure);
    _jours.addAll(detail.jours);
    _actif = detail.actif;
    _repeter = detail.jours.isNotEmpty;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _heureCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final titre = _titreCtrl.text.trim();
    final heure = _heureCtrl.text.trim();
    if (titre.isEmpty) {
      setState(() => _errTitre = 'Champ requis');
      return;
    }
    if (heure.isEmpty) {
      setState(() => _errHeure = 'Champ requis');
      return;
    }
    final jours = _repeter ? (_jours.toList()..sort()) : <int>[];
    final detail = _DetailRappel(
      heure: heure,
      jours: jours,
      actif: _actif,
    ).toRaw();
    if (widget.itemExistant == null) {
      await DepotEntitesSimples.instance
          .ajouter(_cleRappels, titre, detail: detail);
    } else {
      await DepotEntitesSimples.instance.mettreAJour(
        _cleRappels,
        widget.itemExistant!.copyWith(nom: titre, detail: detail),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: widget.itemExistant == null ? 'Ajouter rappel' : 'Modifier rappel',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppEspaces.lg,
            AppEspaces.lg,
            AppEspaces.lg,
            AppEspaces.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              ChampFormulaire(
                label: 'Titre',
                placeholder: 'Ex: Enregistrer mes dépenses quotidiennes',
                controleur: _titreCtrl,
                messageErreur: _errTitre,
              ),
              const SizedBox(height: AppEspaces.md),
              ChampFormulaire(
                label: 'Heure du rappel',
                placeholder: '19:30',
                controleur: _heureCtrl,
                messageErreur: _errHeure,
                readOnly: true,
                onTap: _choisirHeure,
                prefixIcone: const Icon(Icons.access_time_rounded),
              ),
              const SizedBox(height: AppEspaces.md),
              SwitchListTile(
                value: _repeter,
                onChanged: (v) => setState(() => _repeter = v),
                title: const Text('Répéter'),
              ),
              if (_repeter)
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                    final selected = _jours.contains(i + 1);
                    return ChoiceChip(
                      label: Text(labels[i]),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        if (selected) {
                          _jours.remove(i + 1);
                        } else {
                          _jours.add(i + 1);
                        }
                      }),
                    );
                  }),
                ),
              SwitchListTile(
                value: _actif,
                onChanged: (v) => setState(() => _actif = v),
                title: const Text('Activer le rappel'),
              ),
              const SizedBox(height: AppEspaces.lg),
              BoutonPrimaire(libelle: 'Enregistrer', onPress: _save),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choisirHeure() async {
    final now = TimeOfDay.now();
    final initial = _parseHeure(_heureCtrl.text) ?? now;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) {
      return;
    }
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() {
      _heureCtrl.text = '$hh:$mm';
      _errHeure = null;
    });
  }

  TimeOfDay? _parseHeure(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      return null;
    }
    if (h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

class _DetailRappel {
  final String heure;
  final List<int> jours;
  final bool actif;
  _DetailRappel({required this.heure, required this.jours, required this.actif});

  String toRaw() => jsonEncode({'heure': heure, 'jours': jours, 'actif': actif});

  static _DetailRappel fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) {
      return _DetailRappel(heure: '', jours: const [], actif: true);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _DetailRappel(
        heure: map['heure'] as String? ?? '',
        jours: (map['jours'] as List<dynamic>? ?? const []).cast<int>(),
        actif: map['actif'] as bool? ?? true,
      );
    } catch (_) {
      return _DetailRappel(heure: raw, jours: const [], actif: true);
    }
  }
}
