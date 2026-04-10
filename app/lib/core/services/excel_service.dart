import 'package:excel/excel.dart';

import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/repetitif.dart';
import '../../data/models/transaction.dart';

class ExcelExportData {
  final int month;
  final int year;
  final List<TransactionModele> transactions;
  final List<CategorieModele> categories;
  final List<BudgetModele> budgets;
  final List<ObjectifModele> goals;
  final List<RecurrenceModele> recurring;

  const ExcelExportData({
    required this.month,
    required this.year,
    required this.transactions,
    required this.categories,
    required this.budgets,
    required this.goals,
    required this.recurring,
  });
}

class ExcelImportPreview {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;
  final int? month;
  final int? year;
  final List<String> warnings;

  const ExcelImportPreview({
    required this.transactions,
    required this.budgets,
    required this.goals,
    this.month,
    this.year,
    this.warnings = const [],
  });

  int get totalItems => transactions.length + budgets.length + goals.length;
}

class ExcelService {
  static final ExcelService instance = ExcelService._();
  ExcelService._();

  // Pastel colors
  static const String _colorHeaderRose = 'FFFF69B4';
  static const String _colorHeaderBlue = 'FF87CEFA';
  static const String _colorHeaderGreen = 'FF4CAF82';
  static const String _colorHeaderViolet = 'FFDDA0DD';
  static const String _colorBlack = 'FF000000';

  List<int> exporterVersExcel(ExcelExportData donnees) {
    final excel = Excel.createExcel();

    // Remove default Sheet1
    excel.delete('Sheet1');

    _buildSummarySheet(excel, donnees);
    _buildRevenusSheet(excel, donnees);
    _buildDepensesSheet(excel, donnees);
    _buildBudgetsSheet(excel, donnees);
    _buildObjectifsSheet(excel, donnees);

    final octets = excel.save();
    return octets ?? [];
  }

  String nomFichierExcel(int mois, int annee) {
    final moisTexte = mois.toString().padLeft(2, '0');
    return 'budgetflow_${annee}_$moisTexte.xlsx';
  }

  void _buildSummarySheet(Excel excel, ExcelExportData data) {
    final sheet = excel['Résumé'];
    _setHeaderRow(sheet, 0, _colorHeaderRose, [
      'Mois',
      'Année',
      'Total Revenus',
      'Total Dépenses',
      'Solde',
    ]);

    final incomes = data.transactions
        .where((t) => t.type == TypeTransaction.income && t.deletedAt == null)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = data.transactions
        .where((t) => t.type == TypeTransaction.expense && t.deletedAt == null)
        .fold(0.0, (sum, t) => sum + t.amount);

    _setRow(sheet, 1, [
      data.month.toString(),
      data.year.toString(),
      incomes.toStringAsFixed(2),
      expenses.toStringAsFixed(2),
      (incomes - expenses).toStringAsFixed(2),
    ]);
  }

  void _buildRevenusSheet(Excel excel, ExcelExportData data) {
    final sheet = excel['Revenus'];
    _setHeaderRow(sheet, 0, _colorHeaderGreen, [
      'ID',
      'Titre',
      'Montant',
      'Catégorie',
      'Date',
      'Note',
    ]);

    final catById = {for (final c in data.categories) c.id: c.name};
    final revenus = data.transactions
        .where((t) => t.type == TypeTransaction.income && t.deletedAt == null)
        .toList();

    for (var i = 0; i < revenus.length; i++) {
      final t = revenus[i];
      _setRow(sheet, i + 1, [
        t.id,
        t.title,
        t.amount.toStringAsFixed(2),
        catById[t.categoryId] ?? t.categoryId,
        _formatDate(t.date),
        t.note ?? '',
      ]);
    }
  }

  void _buildDepensesSheet(Excel excel, ExcelExportData data) {
    final sheet = excel['Dépenses'];
    _setHeaderRow(sheet, 0, _colorHeaderRose, [
      'ID',
      'Titre',
      'Montant',
      'Catégorie',
      'Date',
      'Note',
    ]);

    final catById = {for (final c in data.categories) c.id: c.name};
    final depenses = data.transactions
        .where((t) => t.type == TypeTransaction.expense && t.deletedAt == null)
        .toList();

    for (var i = 0; i < depenses.length; i++) {
      final t = depenses[i];
      _setRow(sheet, i + 1, [
        t.id,
        t.title,
        t.amount.toStringAsFixed(2),
        catById[t.categoryId] ?? t.categoryId,
        _formatDate(t.date),
        t.note ?? '',
      ]);
    }
  }

  void _buildBudgetsSheet(Excel excel, ExcelExportData data) {
    final sheet = excel['Budgets'];
    _setHeaderRow(sheet, 0, _colorHeaderBlue, [
      'ID',
      'Catégorie',
      'Montant Budget',
      'Mois',
      'Année',
    ]);

    final catById = {for (final c in data.categories) c.id: c.name};
    final budgets = data.budgets.where((b) => b.deletedAt == null).toList();

    for (var i = 0; i < budgets.length; i++) {
      final b = budgets[i];
      _setRow(sheet, i + 1, [
        b.id,
        catById[b.categoryId] ?? b.categoryId,
        b.amount.toStringAsFixed(2),
        b.month.toString(),
        b.year.toString(),
      ]);
    }
  }

  void _buildObjectifsSheet(Excel excel, ExcelExportData data) {
    final sheet = excel['Objectifs'];
    _setHeaderRow(sheet, 0, _colorHeaderViolet, [
      'ID',
      'Nom',
      'Montant Cible',
      'Montant Actuel',
      'Progression (%)',
    ]);

    final goals = data.goals.where((g) => g.deletedAt == null).toList();

    for (var i = 0; i < goals.length; i++) {
      final g = goals[i];
      _setRow(sheet, i + 1, [
        g.id,
        g.name,
        g.targetAmount.toStringAsFixed(2),
        g.currentAmount.toStringAsFixed(2),
        (g.progression * 100).toStringAsFixed(1),
      ]);
    }
  }

  void _setHeaderRow(
      Sheet sheet, int rowIndex, String bgColor, List<String> headers) {
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(bgColor),
        fontColorHex: ExcelColor.fromHexString(_colorBlack),
      );
    }
  }

  void _setRow(Sheet sheet, int rowIndex, List<String> values) {
    for (var col = 0; col < values.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(values[col]);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  ExcelImportPreview importerDepuisExcel(
    List<int> octets, {
    int? mois,
    int? annee,
  }) {
    final excel = Excel.decodeBytes(octets);
    final warnings = <String>[];
    final transactions = <Map<String, dynamic>>[];
    final budgets = <Map<String, dynamic>>[];
    final goals = <Map<String, dynamic>>[];
    int? detectedMonth = mois;
    int? detectedYear = annee;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      final lower = sheetName.toLowerCase();

      if (lower == 'revenus' || lower == 'dépenses' || lower == 'depenses') {
        final colMap = _detectColumns(sheet.rows.first, [
          'id',
          'titre',
          'montant',
          'catégorie',
          'categorie',
          'date',
          'note',
        ]);
        final isRevenu = lower == 'revenus';
        for (var r = 1; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          final titre = _cellStr(row, colMap['titre'] ?? colMap['title'] ?? 1);
          final montant =
              _cellDouble(row, colMap['montant'] ?? colMap['amount'] ?? 2);
          if (titre.isEmpty) continue;
          transactions.add({
            'titre': titre,
            'montant': montant,
            'type': isRevenu ? 'income' : 'expense',
            'categorie':
                _cellStr(row, colMap['catégorie'] ?? colMap['categorie'] ?? 3),
            'date': _cellStr(row, colMap['date'] ?? 4),
            'note': _cellStr(row, colMap['note'] ?? 5),
          });
        }
      } else if (lower == 'budgets') {
        final colMap = _detectColumns(sheet.rows.first, [
          'id',
          'catégorie',
          'categorie',
          'montant budget',
          'montant',
          'mois',
          'année',
          'annee',
        ]);
        for (var r = 1; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          final cat =
              _cellStr(row, colMap['catégorie'] ?? colMap['categorie'] ?? 1);
          final montant = _cellDouble(
              row, colMap['montant budget'] ?? colMap['montant'] ?? 2);
          if (cat.isEmpty) continue;
          final mois = _cellInt(row, colMap['mois'] ?? 3);
          final annee = _cellInt(row, colMap['année'] ?? colMap['annee'] ?? 4);
          if (mois != null) detectedMonth ??= mois;
          if (annee != null) detectedYear ??= annee;
          budgets.add({
            'categorie': cat,
            'montant': montant,
            'mois': mois,
            'annee': annee,
          });
        }
      } else if (lower == 'objectifs') {
        final colMap = _detectColumns(sheet.rows.first, [
          'id',
          'nom',
          'montant cible',
          'montant actuel',
          'progression (%)',
        ]);
        for (var r = 1; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          final nom = _cellStr(row, colMap['nom'] ?? 1);
          final cible = _cellDouble(row, colMap['montant cible'] ?? 2);
          if (nom.isEmpty) continue;
          goals.add({
            'nom': nom,
            'montant_cible': cible,
            'montant_actuel': _cellDouble(row, colMap['montant actuel'] ?? 3),
          });
        }
      } else if (lower != 'résumé' && lower != 'resume') {
        warnings.add('Feuille inconnue ignorée: $sheetName');
      }
    }

    return ExcelImportPreview(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      month: detectedMonth,
      year: detectedYear,
      warnings: warnings,
    );
  }

  Map<String, int> _detectColumns(
      List<Data?> headerRow, List<String> knownHeaders) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final val = headerRow[i]?.value?.toString().toLowerCase().trim() ?? '';
      if (val.isNotEmpty) {
        map[val] = i;
      }
    }
    return map;
  }

  String _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return '';
    return row[col]?.value?.toString().trim() ?? '';
  }

  double _cellDouble(List<Data?> row, int col) {
    final s = _cellStr(row, col);
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  int? _cellInt(List<Data?> row, int col) {
    final s = _cellStr(row, col);
    return int.tryParse(s);
  }
}
