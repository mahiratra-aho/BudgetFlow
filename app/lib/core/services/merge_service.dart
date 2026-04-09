import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/repetitif.dart';
import '../../data/models/transaction.dart';

class MergeService {
  static final MergeService instance = MergeService._();
  MergeService._();

  List<TransactionModele> mergeTransactions(
    List<TransactionModele> existing,
    List<TransactionModele> incoming,
  ) {
    final byId = {for (final t in existing) t.id: t};
    final toUpsert = <TransactionModele>[];

    for (final item in incoming) {
      if (byId.containsKey(item.id)) {
        final current = byId[item.id]!;
        if (_isNewer(item.updatedAt, item.version, current.updatedAt, current.version)) {
          toUpsert.add(item);
        }
      } else {
        final duplicate = _findTransactionDuplicate(existing, item);
        if (duplicate != null) {
          if (_isNewer(item.updatedAt, item.version, duplicate.updatedAt, duplicate.version)) {
            toUpsert.add(TransactionModele(
              id: duplicate.id,
              title: item.title,
              amount: item.amount,
              type: item.type,
              categoryId: item.categoryId,
              note: item.note,
              date: item.date,
              estRepetitif: item.estRepetitif,
              idRepetition: item.idRepetition,
              updatedAt: item.updatedAt,
              deletedAt: item.deletedAt,
              version: item.version,
            ));
          }
        } else {
          toUpsert.add(item);
        }
      }
    }
    return toUpsert;
  }

  TransactionModele? _findTransactionDuplicate(
    List<TransactionModele> existing,
    TransactionModele candidate,
  ) {
    final normalizedTitle = _normalize(candidate.title);
    final dateDay = DateTime(candidate.date.year, candidate.date.month, candidate.date.day).millisecondsSinceEpoch;
    for (final e in existing) {
      final eDateDay = DateTime(e.date.year, e.date.month, e.date.day).millisecondsSinceEpoch;
      if (eDateDay == dateDay && e.amount == candidate.amount &&
          _normalize(e.title) == normalizedTitle && e.categoryId == candidate.categoryId) {
        return e;
      }
    }
    return null;
  }

  List<CategorieModele> mergeCategories(
    List<CategorieModele> existing,
    List<CategorieModele> incoming,
  ) {
    final byId = {for (final c in existing) c.id: c};
    final toUpsert = <CategorieModele>[];
    for (final item in incoming) {
      if (byId.containsKey(item.id)) {
        if (_isNewer(item.updatedAt, item.version, byId[item.id]!.updatedAt, byId[item.id]!.version)) {
          toUpsert.add(item);
        }
      } else {
        toUpsert.add(item);
      }
    }
    return toUpsert;
  }

  List<BudgetModele> mergeBudgets(
    List<BudgetModele> existing,
    List<BudgetModele> incoming,
  ) {
    final byId = {for (final b in existing) b.id: b};
    final byKey = <String, BudgetModele>{for (final b in existing) '${b.categoryId}_${b.month}_${b.year}': b};
    final toUpsert = <BudgetModele>[];
    for (final item in incoming) {
      if (byId.containsKey(item.id)) {
        if (_isNewer(item.updatedAt, item.version, byId[item.id]!.updatedAt, byId[item.id]!.version)) {
          toUpsert.add(item);
        }
      } else {
        final key = '${item.categoryId}_${item.month}_${item.year}';
        final dup = byKey[key];
        if (dup != null) {
          if (_isNewer(item.updatedAt, item.version, dup.updatedAt, dup.version)) {
            toUpsert.add(BudgetModele(
              id: dup.id, categoryId: item.categoryId, amount: item.amount,
              month: item.month, year: item.year, updatedAt: item.updatedAt,
              deletedAt: item.deletedAt, version: item.version,
            ));
          }
        } else {
          toUpsert.add(item);
        }
      }
    }
    return toUpsert;
  }

  List<ObjectifModele> mergeGoals(
    List<ObjectifModele> existing,
    List<ObjectifModele> incoming,
  ) {
    final byId = {for (final g in existing) g.id: g};
    final toUpsert = <ObjectifModele>[];
    for (final item in incoming) {
      if (byId.containsKey(item.id)) {
        if (_isNewer(item.updatedAt, item.version, byId[item.id]!.updatedAt, byId[item.id]!.version)) {
          toUpsert.add(item);
        }
      } else {
        toUpsert.add(item);
      }
    }
    return toUpsert;
  }

  List<RecurrenceModele> mergeRecurring(
    List<RecurrenceModele> existing,
    List<RecurrenceModele> incoming,
  ) {
    final byId = {for (final r in existing) r.id: r};
    final toUpsert = <RecurrenceModele>[];
    for (final item in incoming) {
      if (byId.containsKey(item.id)) {
        if (_isNewer(item.updatedAt, item.version, byId[item.id]!.updatedAt, byId[item.id]!.version)) {
          toUpsert.add(item);
        }
      } else {
        toUpsert.add(item);
      }
    }
    return toUpsert;
  }

  bool _isNewer(DateTime inD, int inV, DateTime curD, int curV) {
    if (inD.isAfter(curD)) return true;
    if (inD.isAtSameMomentAs(curD)) return inV > curV;
    return false;
  }

  String _normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
