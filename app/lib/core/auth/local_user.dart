import 'dart:convert';

// Modèle d'utilisateur local (stockage SharedPreferences)
class LocalUser {
  final String id;
  final String email;
  final String pseudo;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const LocalUser({
    required this.id,
    required this.email,
    required this.pseudo,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'pseudo': pseudo,
        'passwordHash': passwordHash,
        'salt': salt,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
        id: json['id'] as String,
        email: json['email'] as String,
        pseudo: json['pseudo'] as String,
        passwordHash: json['passwordHash'] as String,
        salt: json['salt'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<LocalUser> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LocalUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<LocalUser> users) =>
      jsonEncode(users.map((u) => u.toJson()).toList());
}
