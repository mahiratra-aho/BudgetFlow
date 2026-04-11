import 'package:uuid/uuid.dart';

typedef TransactionModel = TransactionModele;
typedef TransactionType = TypeTransaction;

enum TypeTransaction { income, expense }

// Transaction financière (revenu ou dépense)
class TransactionModele {
  final String id;
  final String title;
  final double amount;
  final TypeTransaction type;
  final String categoryId;
  final String? note;
  final DateTime date;
  final bool estRepetitif;
  final String? idRepetition;
  final String? paymentMethodId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  const TransactionModele({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.date,
    required this.estRepetitif,
    this.idRepetition,
    this.paymentMethodId,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  factory TransactionModele.create({
    required String title,
    required double amount,
    required TypeTransaction type,
    required String categoryId,
    String? note,
    DateTime? date,
    bool estRepetitif = false,
    String? idRepetition,
    String? paymentMethodId,
  }) {
    return TransactionModele(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      date: date ?? DateTime.now(),
      estRepetitif: estRepetitif,
      idRepetition: idRepetition,
      paymentMethodId: paymentMethodId,
      updatedAt: DateTime.now(),
      version: 1,
    );
  }

  factory TransactionModele.fromMap(Map<String, dynamic> map) {
    return TransactionModele(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'income'
          ? TypeTransaction.income
          : TypeTransaction.expense,
      categoryId: map['category_id'] as String,
      note: map['note'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      estRepetitif: (map['is_recurring'] as int? ?? 0) == 1,
      idRepetition: map['recurring_id'] as String?,
      paymentMethodId: map['payment_method_id'] as String?,
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
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'is_recurring': estRepetitif ? 1 : 0,
      'recurring_id': idRepetition,
      'payment_method_id': paymentMethodId,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'version': version,
    };
  }

  TransactionModele copyWith({
    String? title,
    double? amount,
    TypeTransaction? type,
    String? categoryId,
    String? note,
    DateTime? date,
    bool? estRepetitif,
    String? idRepetition,
    String? paymentMethodId,
    DateTime? deletedAt,
  }) {
    return TransactionModele(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      estRepetitif: estRepetitif ?? this.estRepetitif,
      idRepetition: idRepetition ?? this.idRepetition,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version + 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TransactionModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
