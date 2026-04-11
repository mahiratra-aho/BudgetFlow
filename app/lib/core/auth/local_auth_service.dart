import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'local_user.dart';

// Service d'authentification locale (offline, pas de serveur).
//
// Stockage dans SharedPreferences :
// - `bf_users`        → liste JSON des [LocalUser]
// - `bf_current_user` → email de l'utilisateur connecté (null = déconnecté)
class LocalAuthService {
  static final LocalAuthService instance = LocalAuthService._();
  LocalAuthService._();

  static const String _kUsersKey = 'bf_users';
  static const String _kCurrentUserKey = 'bf_current_user';

  // ─────────────────────────────────────────────────────────────────────────
  // API publique
  // ─────────────────────────────────────────────────────────────────────────

  // Crée un compte et ouvre la session.
  //
  // Lève [AuthException] si l'email est déjà utilisé.
  Future<LocalUser> signUp({
    required String email,
    required String password,
    required String pseudo,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    if (users.any((u) => u.email == trimmedEmail)) {
      throw const AuthException('Cet e-mail est déjà utilisé.');
    }

    final salt = _generateSalt();
    final hash = await _hashPassword(password, salt);

    final user = LocalUser(
      id: const Uuid().v4(),
      email: trimmedEmail,
      pseudo: pseudo.trim(),
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.now(),
    );

    await _saveUsers([...users, user]);
    await _setCurrentUser(trimmedEmail);
    return user;
  }

  // Connecte un utilisateur existant.
  //
  // Lève [AuthException] si les identifiants sont incorrects.
  Future<LocalUser> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    final user = users.where((u) => u.email == trimmedEmail).firstOrNull;
    if (user == null) {
      throw const AuthException('Aucun compte trouvé avec cet e-mail.');
    }

    final hash = await _hashPassword(password, user.salt);
    if (hash != user.passwordHash) {
      throw const AuthException('Mot de passe incorrect.');
    }

    await _setCurrentUser(trimmedEmail);
    return user;
  }

  // Déconnecte l'utilisateur courant.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserKey);
  }

  // Retourne l'utilisateur courant, ou null si non connecté.
  Future<LocalUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kCurrentUserKey);
    if (email == null) return null;

    final users = await _loadUsers();
    return users.where((u) => u.email == email).firstOrNull;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Méthodes privées
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<LocalUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return LocalUser.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveUsers(List<LocalUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsersKey, LocalUser.listToJson(users));
  }

  Future<void> _setCurrentUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUserKey, email);
  }

  // Génère un sel aléatoire 32 hex chars.
  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Hache le mot de passe avec SHA-256 + sel (10 000 itérations) dans un
  // isolate séparé pour ne pas bloquer le thread UI.
  Future<String> _hashPassword(String password, String salt) {
    return compute(_hashPasswordSync, (password: password, salt: salt));
  }
}

// Fonction top-level exigée par [compute] (doit être isolable).
String _hashPasswordSync(({String password, String salt}) args) {
  var bytes = utf8.encode('${args.password}:${args.salt}:bf_auth_v1');
  var hash = sha256.convert(bytes);
  // Key stretching : 10 000 itérations pour ralentir les attaques par force brute
  for (var i = 0; i < 10000; i++) {
    hash = sha256.convert([...hash.bytes, ...utf8.encode(args.salt)]);
  }
  return hash.toString();
}

// Exception levée par [LocalAuthService].
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
