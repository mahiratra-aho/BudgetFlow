import 'package:uuid/uuid.dart';

class PieceJointeModele {
  final String id;
  final String transactionId;
  final String path;
  final String mimeType;
  final DateTime createdAt;

  const PieceJointeModele({
    required this.id,
    required this.transactionId,
    required this.path,
    required this.mimeType,
    required this.createdAt,
  });

  factory PieceJointeModele.create({
    required String transactionId,
    required String path,
    required String mimeType,
  }) {
    return PieceJointeModele(
      id: const Uuid().v4(),
      transactionId: transactionId,
      path: path,
      mimeType: mimeType,
      createdAt: DateTime.now(),
    );
  }

  factory PieceJointeModele.fromMap(Map<String, dynamic> map) {
    return PieceJointeModele(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      path: map['path'] as String,
      mimeType: map['mime_type'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'path': path,
      'mime_type': mimeType,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PieceJointeModele && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
