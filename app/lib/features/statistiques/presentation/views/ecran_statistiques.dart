import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/constantes_app.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accueil/presentation/views/ecran_detail_transaction.dart';
import '../../../accueil/presentation/widgets/carte_transaction_accueil.dart';
import '../../../budgets/presentation/views/ecran_budgets.dart';
import '../../../shared/utils/depot_budgets.dart';
import '../../../shared/utils/depot_transactions.dart';
import '../../../shared/utils/modeles.dart';
import '../../../shared/widgets/app_bar_budgetflow.dart';
import '../../utils/service_export_excel.dart';

class EcranStatistiques extends ConsumerStatefulWidget {
  final bool ouvrirExportAuDemarrage;
  const EcranStatistiques({super.key, this.ouvrirExportAuDemarrage = false});

  @override
  ConsumerState<EcranStatistiques> createState() => _EtatEcranStatistiques();
}

class _EtatEcranStatistiques extends ConsumerState<EcranStatistiques> {
  bool _exportOuvert = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.ouvrirExportAuDemarrage && !_exportOuvert) {
      _exportOuvert = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _exporter(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final transactionsAsync = ref.watch(transactionsDuMoisProvider);
    ref.watch(moisSelectionneProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(
        titre: 'Statistiques',
        afficherRetour: false,
        actions: [
          IconButton(
            onPressed: () => _exporter(context),
            icon: SvgPicture.asset(
              'assets/icons/exportexcel.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(AppCouleurs.accentBrun, BlendMode.srcIn),
            ),
          ),
          IconButton(
            onPressed: () => _importer(context),
            icon: const Icon(Icons.file_upload_outlined, color: AppCouleurs.accentBrun),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppCouleurs.primaire)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (transactions) {
          final depenses = transactions
              .where((t) => t.type == TypeTransaction.depense)
              .toList();
          final revenus = transactions
              .where((t) => t.type == TypeTransaction.revenu)
              .toList();
          final totalDep = depenses.fold(0.0, (s, t) => s + t.montant);
          final totalRev = revenus.fold(0.0, (s, t) => s + t.montant);

          // Regrouper par catégorie
          final parCat = <String, double>{};
          for (final t in depenses) {
            parCat[t.categorie.nom] =
                (parCat[t.categorie.nom] ?? 0) + t.montant;
          }
          final statsTriees = parCat.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspaces.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Résumé
                Row(
                  children: [
                    Expanded(
                      child: _CarteStat(
                        label: 'Revenus',
                        montant: Devise.formater(totalRev),
                        couleur: AppCouleurs.succes,
                      ),
                    ),
                    const SizedBox(width: AppEspaces.md),
                    Expanded(
                      child: _CarteStat(
                        label: 'Dépenses',
                        montant: Devise.formater(totalDep),
                        couleur: AppCouleurs.erreur,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppEspaces.xl),

                _SectionAjoutBudget(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EcranBudgets()),
                  ),
                ),
                const SizedBox(height: AppEspaces.xl),
                if (depenses.isEmpty)
                  const _EtatVideStat()
                else ...[
                  Text('Camembert', style: AppTypographie.titleSmall),
                  const SizedBox(height: AppEspaces.md),
                  _CarteCamembert(totalDep: totalDep, statsTriees: statsTriees),
                  const SizedBox(height: AppEspaces.xl),
                  Text('Tendances - 6 mois', style: AppTypographie.titleSmall),
                  const SizedBox(height: AppEspaces.md),
                  _CarteCourbe(transactions: transactions),
                  const SizedBox(height: AppEspaces.xl),
                  Text('Détails par catégorie', style: AppTypographie.titleSmall),
                  const SizedBox(height: AppEspaces.md),
                  ...statsTriees.map((e) {
                    final pct = totalDep > 0 ? e.value / totalDep : 0.0;
                    final cat = depenses
                        .firstWhere((t) => t.categorie.nom == e.key)
                        .categorie;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppEspaces.md),
                      child: _LigneStatCategorie(
                        categorie: cat,
                        montant: e.value,
                        pourcentage: pct,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProviderScope(
                              parent: ProviderScope.containerOf(context),
                              child: _EcranTransactionsCategorie(
                                categorie: cat,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exporter(BuildContext context) async {
    final plage = await _selectionnerPeriode(context);
    if (plage == null) return;
    final okPin = await _verifierPinSiNecessaire(context);
    if (!okPin) return;
    try {
      final path = await ServiceExportExcel.instance.exporter(
        debut: plage.debut,
        fin: plage.fin,
        typePeriode: plage.type,
      );
      if (!mounted) return;
      await _partagerFichierExport(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec export: $e')),
      );
    }
  }

  Future<void> _partagerFichierExport(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier exporté introuvable.')),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(path)],
      text: 'Export BudgetFlow',
      subject: 'Fichier BudgetFlow',
    );
  }

  Future<void> _importer(BuildContext context) async {
    final okPin = await _verifierPinSiNecessaire(context);
    if (!okPin) return;
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    final path = selection?.files.single.path;
    if (path == null) return;
    try {
      await ServiceExportExcel.instance.importerDepuisFichier(path);
      invalidaterTransactions(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import terminé')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec import: $e')),
      );
    }
  }

  Future<bool> _verifierPinSiNecessaire(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(ConstantesApp.clePinLocal);
    if (pin == null || pin.isEmpty) return true;

    final verrouJusqua = prefs.getInt(ConstantesApp.clePinLockUntilMs) ?? 0;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (verrouJusqua > maintenant) {
      final sec = ((verrouJusqua - maintenant) / 1000).ceil();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trop d\'essais. Reessayez dans ${sec}s.')),
      );
      return false;
    }

    final ctrl = TextEditingController();
    final saisi = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Saisir le code PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(hintText: '••••'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Valider')),
        ],
      ),
    );
    if (saisi == null) return false;

    int echecs = prefs.getInt(ConstantesApp.clePinFailCount) ?? 0;
    if (saisi == pin) {
      await prefs.setInt(ConstantesApp.clePinFailCount, 0);
      await prefs.remove(ConstantesApp.clePinLockUntilMs);
      return true;
    }
    echecs++;
    await prefs.setInt(ConstantesApp.clePinFailCount, echecs);
    if (echecs >= 5) {
      final lock = DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch;
      await prefs.setInt(ConstantesApp.clePinLockUntilMs, lock);
      await prefs.setInt(ConstantesApp.clePinFailCount, 0);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('5 erreurs PIN. Attendez 60 secondes.')),
      );
      return false;
    }
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PIN incorrect (${5 - echecs} essais restants)')),
    );
    return false;
  }

  Future<_PlageExport?> _selectionnerPeriode(BuildContext context) async {
    TypePeriodeExport type = TypePeriodeExport.mensuelle;
    DateTime debut = DateTime.now();
    DateTime fin = DateTime.now();
    return showDialog<_PlageExport>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          Future<void> pickDebut() async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: debut,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) setSt(() => debut = d);
          }

          Future<void> pickFin() async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: fin,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) setSt(() => fin = d);
          }

          return AlertDialog(
            title: const Text('Exporter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Période',
                  style: AppTypographie.labelLarge
                      .copyWith(color: AppCouleurs.texteSecondaire),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppCouleurs.surface,
                    borderRadius: BorderRadius.circular(AppRayons.md),
                    border: Border.all(
                      color: AppCouleurs.textePrincipal.withOpacity(0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TypePeriodeExport>(
                      value: type,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(AppRayons.md),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: TypePeriodeExport.values
                          .map(
                            (e) => DropdownMenuItem<TypePeriodeExport>(
                              value: e,
                              child: Text(
                                _libelleType(e),
                                style: AppTypographie.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSt(() => type = v ?? type),
                    ),
                  ),
                ),
                if (type == TypePeriodeExport.personnalisee) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text('Debut: ${debut.day}/${debut.month}/${debut.year}'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: pickDebut,
                  ),
                  ListTile(
                    title: Text('Fin: ${fin.day}/${fin.month}/${fin.year}'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: pickFin,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  _PlageExport(type: type, debut: _normaliserDebut(type, debut), fin: _normaliserFin(type, fin)),
                ),
                child: const Text('Exporter'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _libelleType(TypePeriodeExport type) {
    switch (type) {
      case TypePeriodeExport.journaliere:
        return 'Journaliere';
      case TypePeriodeExport.hebdomadaire:
        return 'Hebdomadaire';
      case TypePeriodeExport.mensuelle:
        return 'Mensuelle';
      case TypePeriodeExport.annuelle:
        return 'Annuelle';
      case TypePeriodeExport.personnalisee:
        return 'Personnalisee';
    }
  }

  DateTime _normaliserDebut(TypePeriodeExport type, DateTime d) {
    switch (type) {
      case TypePeriodeExport.journaliere:
        return DateTime(d.year, d.month, d.day);
      case TypePeriodeExport.hebdomadaire:
        return DateTime(d.year, d.month, d.day - (d.weekday - 1));
      case TypePeriodeExport.mensuelle:
        return DateTime(d.year, d.month, 1);
      case TypePeriodeExport.annuelle:
        return DateTime(d.year, 1, 1);
      case TypePeriodeExport.personnalisee:
        return DateTime(d.year, d.month, d.day);
    }
  }

  DateTime _normaliserFin(TypePeriodeExport type, DateTime d) {
    switch (type) {
      case TypePeriodeExport.journaliere:
        return DateTime(d.year, d.month, d.day, 23, 59, 59);
      case TypePeriodeExport.hebdomadaire:
        final debut = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        return DateTime(debut.year, debut.month, debut.day + 6, 23, 59, 59);
      case TypePeriodeExport.mensuelle:
        return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
      case TypePeriodeExport.annuelle:
        return DateTime(d.year, 12, 31, 23, 59, 59);
      case TypePeriodeExport.personnalisee:
        return DateTime(d.year, d.month, d.day, 23, 59, 59);
    }
  }
}

class _PlageExport {
  final TypePeriodeExport type;
  final DateTime debut;
  final DateTime fin;
  _PlageExport({required this.type, required this.debut, required this.fin});
}

class _SectionAjoutBudget extends StatelessWidget {
  final VoidCallback onTap;
  const _SectionAjoutBudget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart_outline_rounded, color: AppCouleurs.primaire),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Mes budgets',
                style: AppTypographie.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: onTap, child: const Text('Explorer')),
        ],
      ),
    );
  }
}

class _CarteCamembert extends StatefulWidget {
  final double totalDep;
  final List<MapEntry<String, double>> statsTriees;
  const _CarteCamembert({required this.totalDep, required this.statsTriees});

  @override
  State<_CarteCamembert> createState() => _CarteCamembertState();
}

class _CarteCamembertState extends State<_CarteCamembert> {
  static const double _chartSize = 220;
  int? _segmentActif;
  Timer? _timerInfo;

  @override
  void dispose() {
    _timerInfo?.cancel();
    super.dispose();
  }

  void _gererTap(TapDownDetails details) {
    final local = details.localPosition;
    final center = const Offset(_chartSize / 2, _chartSize / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = _chartSize * 0.42;
    final epaisseur = 38.0;
    final inner = radius - (epaisseur / 2);
    final outer = radius + (epaisseur / 2);

    if (distance < inner || distance > outer || widget.totalDep <= 0) return;

    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += math.pi * 2;
    var cursor = -1.57;
    if (cursor < 0) cursor += math.pi * 2;

    int? touche;
    for (int i = 0; i < widget.statsTriees.length; i++) {
      final sweep = (widget.statsTriees[i].value / widget.totalDep) * (math.pi * 2);
      final debut = cursor;
      final fin = (cursor + sweep) % (math.pi * 2);
      final match = fin < debut
          ? (angle >= debut || angle <= fin)
          : (angle >= debut && angle <= fin);
      if (match) {
        touche = i;
        break;
      }
      cursor = fin;
    }

    if (touche == null) return;
    setState(() => _segmentActif = touche);
    _timerInfo?.cancel();
    _timerInfo = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _segmentActif = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final segment = _segmentActif == null ? null : widget.statsTriees[_segmentActif!];
    final pct = segment == null || widget.totalDep == 0
        ? 0.0
        : (segment.value / widget.totalDep) * 100;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(AppRayons.md),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapDown: _gererTap,
                child: SizedBox(
                  width: _chartSize,
                  height: _chartSize,
                  child: CustomPaint(
                    painter: _PiePainter(
                      totalDep: widget.totalDep,
                      statsTriees: widget.statsTriees,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (segment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppCouleurs.surface,
                borderRadius: BorderRadius.circular(AppRayons.md),
              ),
              child: Text(
                '${segment.key} - ${pct.toStringAsFixed(1)}%',
                style: AppTypographie.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteCourbe extends StatelessWidget {
  final List<Transaction> transactions;
  const _CarteCourbe({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final maintenant = DateTime.now();
    final mois = List.generate(6, (i) {
      final d = DateTime(maintenant.year, maintenant.month - (5 - i));
      return DateTime(d.year, d.month);
    });
    final depenses = <double>[];
    final revenus = <double>[];
    for (final m in mois) {
      final tMois = transactions
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .toList();
      depenses.add(tMois
          .where((t) => t.type == TypeTransaction.depense)
          .fold(0.0, (s, t) => s + t.montant));
      revenus.add(tMois
          .where((t) => t.type == TypeTransaction.revenu)
          .fold(0.0, (s, t) => s + t.montant));
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(AppRayons.md),
      ),
      child: CustomPaint(
        painter: _BarsPainter(
          depenses: depenses,
          revenus: revenus,
          labels: mois
              .map((e) => _labelMoisCourt(e.month))
              .toList(),
        ),
      ),
    );
  }

  String _labelMoisCourt(int m) {
    const labels = ['jan', 'fev', 'mar', 'avr', 'mai', 'jun', 'jul', 'aou', 'sep', 'oct', 'nov', 'dec'];
    return labels[m - 1];
  }
}

class _PiePainter extends CustomPainter {
  final double totalDep;
  final List<MapEntry<String, double>> statsTriees;
  _PiePainter({
    required this.totalDep,
    required this.statsTriees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final couleurs = [
      const Color(0xFFF9C12B),
      const Color(0xFF8D5A4B),
      AppCouleurs.succes,
      AppCouleurs.erreur
    ];
    double start = -1.57;
    for (int i = 0; i < statsTriees.length; i++) {
      final sweep = totalDep == 0 ? 0.0 : (statsTriees[i].value / totalDep) * 6.28318;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 38
        ..color = couleurs[i % couleurs.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarsPainter extends CustomPainter {
  final List<double> depenses;
  final List<double> revenus;
  final List<String> labels;
  _BarsPainter({
    required this.depenses,
    required this.revenus,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - 24;
    final maxValue = [...depenses, ...revenus].fold<double>(1, (m, e) => e > m ? e : m);
    final groupWidth = size.width / labels.length;
    final barWidth = groupWidth * 0.23;
    final depPaint = Paint()..color = const Color(0xFFFA5A62);
    final revPaint = Paint()..color = const Color(0xFF8AA232);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      final leftBase = i * groupWidth + (groupWidth - barWidth * 2 - 6) / 2;
      final hDep = (depenses[i] / maxValue) * (baseY - 18);
      final hRev = (revenus[i] / maxValue) * (baseY - 18);
      final depRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftBase, baseY - hDep, barWidth, hDep),
        const Radius.circular(10),
      );
      final revRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftBase + barWidth + 6, baseY - hRev, barWidth, hRev),
        const Radius.circular(10),
      );
      canvas.drawRRect(depRect, depPaint);
      canvas.drawRRect(revRect, revPaint);

      textPainter.text = TextSpan(
        text: labels[i],
        style: AppTypographie.bodySmall.copyWith(color: AppCouleurs.texteSecondaire),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * groupWidth + (groupWidth - textPainter.width) / 2, baseY + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CarteStat extends StatelessWidget {
  final String label;
  final String montant;
  final Color couleur;

  const _CarteStat({
    required this.label,
    required this.montant,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: AppCouleurs.surface,
        borderRadius: BorderRadius.circular(AppRayons.md),
        boxShadow: [
          BoxShadow(
              color: AppCouleurs.textePrincipal.withOpacity(0.06),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: couleur, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTypographie.bodySmall
                      .copyWith(color: AppCouleurs.texteSecondaire)),
            ],
          ),
          const SizedBox(height: 6),
          Text(montant,
              style: AppTypographie.titleSmall.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _LigneStatCategorie extends StatelessWidget {
  final Categorie categorie;
  final double montant;
  final double pourcentage;
  final VoidCallback onTap;

  const _LigneStatCategorie({
    required this.categorie,
    required this.montant,
    required this.pourcentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppEspaces.md),
        decoration: BoxDecoration(
          color: AppCouleurs.surface,
          borderRadius: BorderRadius.circular(AppRayons.md),
          boxShadow: [
            BoxShadow(
                color: AppCouleurs.textePrincipal.withOpacity(0.05),
                blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(categorie.nom,
                        style: AppTypographie.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600))),
                Text(
                  '${(pourcentage * 100).toStringAsFixed(0)}%',
                  style: AppTypographie.bodySmall.copyWith(
                      color: categorie.couleur, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(Devise.formater(montant),
                    style: AppTypographie.bodySmall.copyWith(
                        color: AppCouleurs.erreur, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pourcentage,
                minHeight: 6,
                backgroundColor: categorie.couleur.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(categorie.couleur),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EcranTransactionsCategorie extends ConsumerWidget {
  final Categorie categorie;
  const _EcranTransactionsCategorie({required this.categorie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsDuMoisProvider);

    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      appBar: AppBarBudgetFlow(titre: categorie.nom),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppCouleurs.primaire),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (toutes) {
          final liste = toutes
              .where((t) => t.categorie.id == categorie.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (liste.isEmpty) {
            return Center(
              child: Text(
                'Aucune transaction pour cette catégorie',
                style: AppTypographie.bodyMedium
                    .copyWith(color: AppCouleurs.texteSecondaire),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppEspaces.lg),
            itemCount: liste.length,
            itemBuilder: (ctx, i) {
              final t = liste[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CarteTransactionAccueil(
                  transaction: t,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderScope(
                        parent: ProviderScope.containerOf(context),
                        child: EcranDetailTransaction(transaction: t),
                      ),
                    ),
                  ),
                  onSupprimer: () => _supprimer(context, ref, t.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRayons.md)),
        title: Text('Supprimer ?', style: AppTypographie.titleSmall),
        content: Text(
          'Cette transaction sera supprimée définitivement.',
          style: AppTypographie.bodyMedium
              .copyWith(color: AppCouleurs.texteSecondaire),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCouleurs.erreur,
              foregroundColor: AppCouleurs.texteInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRayons.md),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final tx = await DepotTransactions.instance.lireParId(id);
      await DepotTransactions.instance.supprimer(id);
      if (tx != null && tx.type == TypeTransaction.depense) {
        await DepotBudgets.instance.retirerDepense(
          categorieId: tx.categorie.id,
          montant: tx.montant,
        );
      }
      invalidaterTransactions(ref);
    }
  }
}

class _EtatVideStat extends StatelessWidget {
  const _EtatVideStat();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppEspaces.xxl),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 60, color: AppCouleurs.texteTertiaire),
          SizedBox(height: AppEspaces.md),
          Text(
            'Aucune donnée ce mois.\nAjoutez des transactions pour voir vos statistiques.',
            style: AppTypographie.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
