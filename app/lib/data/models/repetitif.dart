import 'package:uuid/uuid.dart';

import 'transaction.dart';

typedef RepetitifModele = RecurrenceModele;
typedef FrequenceRepetitive = FrequenceRecurrence;

enum FrequenceRecurrence { daily, weekly, monthly, yearly }

extension LibelleFrequenceRecurrence on FrequenceRecurrence {
  String get label {
    switch (this) {
      case FrequenceRecurrence.daily:
        return 'Quotidien';
      case FrequenceRecurrence.weekly:
        return 'Hebdomadaire';
      case FrequenceRecurrence.monthly:
        return 'Mensuel';
      case FrequenceRecurrence.yearly:
        return 'Annuel';
    }
  }

  String get value {
    switch (this) {
      case FrequenceRecurrence.daily:
        return 'daily';
      case FrequenceRecurrence.weekly:
        return 'weekly';
      case FrequenceRecurrence.monthly:
        return 'monthly';
      case FrequenceRecurrence.yearly:
        return 'yearly';
    }
  }

  static FrequenceRecurrence fromValue(String value) {
    switch (value) {
      case 'weekly':
        return FrequenceRecurrence.weekly;
      case 'monthly':
        return FrequenceRecurrence.monthly;
      case 'yearly':
        return FrequenceRecurrence.yearly;
      default:
        return FrequenceRecurrence.daily;
    }
  }
}

// Transaction récurrente (loyer, abonnement, etc.)
class RecurrenceModele {
  final String id;
  final String title;
  final double amount;
  final TypeTransaction type;
  final String categoryId;
  final FrequenceRecurrence frequency;
  final int interval; // ex: toutes les 2 semaines → interval = 2
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDate;
  final String? note;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const RecurrenceModele({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.endDate,
    required this.nextDate,
    this.note,
    required this.isActive,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory RecurrenceModele.create({
    required String title,
    required double amount,
    required TypeTransaction type,
    required String categoryId,
    required FrequenceRecurrence frequency,
    int interval = 1,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) {
    final start = startDate ?? DateTime.now();
    return RecurrenceModele(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      frequency: frequency,
      interval: interval,
      startDate: start,
      endDate: endDate,
      nextDate: start,
      note: note,
      isActive: true,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory RecurrenceModele.fromMap(Map<String, dynamic> map) {
    return RecurrenceModele(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'income'
          ? TypeTransaction.income
          : TypeTransaction.expense,
      categoryId: map['category_id'] as String,
      frequency: LibelleFrequenceRecurrence.fromValue(
        map['frequency'] as String,
      ),
      interval: map['interval'] as int? ?? 1,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      nextDate: DateTime.fromMillisecondsSinceEpoch(map['next_date'] as int),
      note: map['note'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type == TypeTransaction.income ? 'income' : 'expense',
      'category_id': categoryId,
      'frequency': frequency.value,
      'interval': interval,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'next_date': nextDate.millisecondsSinceEpoch,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  RecurrenceModele copyWith({
    String? title,
    double? amount,
    TypeTransaction? type,
    String? categoryId,
    FrequenceRecurrence? frequency,
    int? interval,
    DateTime? endDate,
    DateTime? nextDate,
    String? note,
    bool? isActive,
    DateTime? deletedAt,
  }) {
    return RecurrenceModele(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      nextDate: nextDate ?? this.nextDate,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RecurrenceModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
