import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../epargnes/utils/depot_epargnes.dart';
import '../../shared/utils/depot_categories.dart';
import '../../shared/utils/depot_transactions.dart';
import '../../shared/utils/modeles.dart';

enum TypePeriodeExport { journaliere, hebdomadaire, mensuelle, annuelle, personnalisee }

class ServiceExportExcel {
  ServiceExportExcel._();
  static final ServiceExportExcel instance = ServiceExportExcel._();

  static final CellStyle _styleTitre = CellStyle(
    bold: true,
    fontSize: 14,
    backgroundColorHex: ExcelColor.fromHexString('#F9C12B'),
    horizontalAlign: HorizontalAlign.Center,
  );

  static final CellStyle _styleEntete = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#FDE7A8'),
    horizontalAlign: HorizontalAlign.Center,
  );

  static final CellStyle _styleTexte = CellStyle(
    horizontalAlign: HorizontalAlign.Left,
  );

  static final CellStyle _styleMontant = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
  );

  Future<String> exporter({
    required DateTime debut,
    required DateTime fin,
    required TypePeriodeExport typePeriode,
    String? cheminSortie,
  }) async {
    final excel = Excel.createExcel();
    final transactions = await DepotTransactions.instance.lireEntre(debut, fin);
    final epargnes = await DepotEpargnes.instance.lireTous();

    _remplirResume(excel, debut: debut, fin: fin, typePeriode: typePeriode);
    _remplirTransactions(excel, transactions, debut: debut, fin: fin);
    _remplirEpargnes(excel, epargnes);
    _remplirBudgets(excel);
    _remplirStatistiques(excel, transactions);

    final nom =
        'budgetflow_${typePeriode.name}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final dir = cheminSortie ?? (await getApplicationDocumentsDirectory()).path;
    await Directory(dir).create(recursive: true);
    final path = '$dir/$nom';
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Impossible de generer le fichier');
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> importerDepuisFichier(String fichierPath) async {
    final file = File(fichierPath);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    await DepotTransactions.instance.supprimerTous();
    await DepotEpargnes.instance.supprimerTous();
    await _importerTransactions(excel);
    await _importerEpargnes(excel);
  }

  void _styleHeader(Sheet sheet, int rowIndex, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _styleEntete;
    }
  }

  void _remplirResume(
    Excel excel, {
    required DateTime debut,
    required DateTime fin,
    required TypePeriodeExport typePeriode,
  }) {
    final sheet = excel['Resume'];
    final titre = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titre.value = TextCellValue('BudgetFlow - Export');
    titre.cellStyle = _styleTitre;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('Periode');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        TextCellValue(typePeriode.name);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Date debut');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        TextCellValue(_fmtDate(debut));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('Date fin');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value =
        TextCellValue(_fmtDate(fin));
  }

  void _remplirTransactions(
    Excel excel,
    List<Transaction> transactions, {
    required DateTime debut,
    required DateTime fin,
  }) {
    final sheet = excel['Transactions'];
    _ecrireTitreSection(sheet, 'Transactions', 0);
    _styleHeader(sheet, 2, ['Date', 'Type', 'Titre', 'Categorie', 'Montant (Ar)', 'Note']);
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final row = i + 3;
      _setText(sheet, 0, row, _fmtDate(t.date));
      _setText(sheet, 1, row, t.type.libelle);
      _setText(sheet, 2, row, t.titre);
      _setText(sheet, 3, row, t.categorie.nom);
      _setMontant(sheet, 4, row, t.montant);
      _setText(sheet, 5, row, t.note ?? '');
    }
  }

  void _remplirEpargnes(Excel excel, List<EpargneObjectif> epargnes) {
    final sheet = excel['Epargnes'];
    _ecrireTitreSection(sheet, 'Objectifs d\'epargne', 0);
    _styleHeader(sheet, 2, ['Objectif', 'Cible (Ar)', 'Actuel (Ar)', 'Progression %']);
    for (int i = 0; i < epargnes.length; i++) {
      final e = epargnes[i];
      final progression = e.objectif == 0 ? 0.0 : (e.montantActuel / e.objectif) * 100;
      final row = i + 3;
      _setText(sheet, 0, row, e.nom);
      _setMontant(sheet, 1, row, e.objectif);
      _setMontant(sheet, 2, row, e.montantActuel);
      _setText(sheet, 3, row, '${progression.toStringAsFixed(1)} %');
    }
  }

  void _remplirBudgets(Excel excel) {
    final sheet = excel['Budgets'];
    _ecrireTitreSection(sheet, 'Budgets', 0);
    _styleHeader(sheet, 2, ['Nom', 'Total', 'Depense', 'Restant']);
    _setText(sheet, 0, 3, 'Aucun budget configure');
  }

  void _remplirStatistiques(Excel excel, List<Transaction> transactions) {
    final sheet = excel['Statistiques'];
    _ecrireTitreSection(sheet, 'Statistiques', 0);
    _styleHeader(sheet, 2, ['Section', 'Libelle', 'Valeur']);
    final depenses = transactions.where((e) => e.type == TypeTransaction.depense).toList();
    final revenus = transactions.where((e) => e.type == TypeTransaction.revenu).toList();
    final totalDep = depenses.fold(0.0, (s, t) => s + t.montant);
    final totalRev = revenus.fold(0.0, (s, t) => s + t.montant);
    _setText(sheet, 0, 3, 'Resume');
    _setText(sheet, 1, 3, 'Revenus');
    _setMontant(sheet, 2, 3, totalRev);
    _setText(sheet, 0, 4, 'Resume');
    _setText(sheet, 1, 4, 'Depenses');
    _setMontant(sheet, 2, 4, totalDep);

    final parCat = <String, double>{};
    for (final t in depenses) {
      parCat[t.categorie.nom] = (parCat[t.categorie.nom] ?? 0) + t.montant;
    }
    int row = 5;
    for (final entry in parCat.entries) {
      final pct = totalDep == 0 ? 0.0 : (entry.value / totalDep) * 100;
      _setText(sheet, 0, row, 'Graphique categorie');
      _setText(sheet, 1, row, entry.key);
      _setText(sheet, 2, row, '${pct.toStringAsFixed(1)} %');
      row++;
    }
  }

  void _ecrireTitreSection(Sheet sheet, String titre, int rowIndex) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell.value = TextCellValue(titre);
    cell.cellStyle = _styleTitre;
  }

  void _setText(Sheet sheet, int col, int row, String text) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = _styleTexte;
  }

  void _setMontant(Sheet sheet, int col, int row, double value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue('${value.toStringAsFixed(0)} Ar');
    cell.cellStyle = _styleMontant;
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  double _parseMontant(String value) {
    return double.tryParse(
          value.replaceAll('Ar', '').replaceAll(' ', '').replaceAll(',', '.'),
        ) ??
        0.0;
  }

  Future<void> _importerTransactions(Excel excel) async {
    final sheet = excel.tables['Transactions'];
    if (sheet == null || sheet.rows.length < 4) return;
    final depotCat = DepotCategories.instance;
    final depotTx = DepotTransactions.instance;
    final categories = await depotCat.lireTout();
    for (int i = 3; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final dateTexte = row[0]?.value?.toString() ?? '';
      final typeTexte = row[1]?.value?.toString() ?? 'Depense';
      final titre = row[2]?.value?.toString() ?? '';
      final nomCategorie = row[3]?.value?.toString() ?? '';
      final montant = _parseMontant(row[4]?.value?.toString() ?? '0');
      final note = row[5]?.value?.toString();
      if (titre.isEmpty || dateTexte.isEmpty || montant <= 0) continue;
      final type = typeTexte.toLowerCase().contains('revenu')
          ? TypeTransaction.revenu
          : TypeTransaction.depense;
      Categorie? categorie;
      for (final c in categories) {
        if (c.nom.toLowerCase() == nomCategorie.toLowerCase() && c.type == type) {
          categorie = c;
          break;
        }
      }
      if (categorie == null) {
        final id = 'imp_${const Uuid().v4()}';
        categorie = Categorie(
          id: id,
          nom: nomCategorie.isEmpty ? (type == TypeTransaction.depense ? 'Divers' : 'Autre revenu') : nomCategorie,
          iconeCode: 0xe7c9,
          couleurHex: 'F9C12B',
          type: type,
          estDefaut: false,
        );
        await depotCat.inserer(categorie);
        categories.add(categorie);
      }
      await depotTx.inserer(
        titre: titre,
        montant: montant,
        type: type,
        categorie: categorie,
        date: _parseDate(dateTexte),
        note: note,
      );
    }
  }

  Future<void> _importerEpargnes(Excel excel) async {
    final sheet = excel.tables['Epargnes'];
    if (sheet == null || sheet.rows.length < 4) return;
    for (int i = 3; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nom = row[0]?.value?.toString() ?? '';
      final objectif = _parseMontant(row[1]?.value?.toString() ?? '0');
      final actuel = _parseMontant(row[2]?.value?.toString() ?? '0');
      if (nom.isEmpty || objectif <= 0) continue;
      final e = await DepotEpargnes.instance.ajouter(nom: nom, objectif: objectif);
      await DepotEpargnes.instance
          .mettreAJour(e.copyWith(montantActuel: actuel.clamp(0, objectif).toDouble()));
    }
  }
}
