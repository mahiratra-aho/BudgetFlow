import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/local_auth_service.dart';

// Service de sécurité: PIN + biométrie (Android), PIN uniquement (Web).
//
// Toutes les clés de stockage sont préfixées par l'identifiant de l'utilisateur
// connecté afin d'isoler les réglages de sécurité entre plusieurs utilisateurs
// sur le même appareil.
class SecurityService {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

  // Noms de clé de base (sans préfixe utilisateur)
  static const String _kPinKey = 'bf_pin_hash';
  static const String _kPinSetKey = 'bf_pin_set';
  static const String _kSecurityEnabledKey = 'bf_security_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();
  FlutterSecureStorage? _secureStorage;

  FlutterSecureStorage get _storage {
    _secureStorage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return _secureStorage!;
  }

  // Retourne le préfixe de clé pour l'utilisateur connecté.
  // Si aucun utilisateur n'est connecté, renvoie une chaîne vide
  // (comportement héritage pour compatibilité).
  Future<String> _userPrefix() async {
    final user = await LocalAuthService.instance.getCurrentUser();
    return user != null ? '${user.id}_' : '';
  }

  // Construit une clé préfixée par l'utilisateur courant.
  Future<String> _k(String base) async {
    final prefix = await _userPrefix();
    return '$prefix$base';
  }

  // Vérifie si la sécurité est activée
  Future<bool> isSecurityEnabled() async {
    final key = await _k(_kSecurityEnabledKey);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> setSecurityEnabled(bool enabled) async {
    final key = await _k(_kSecurityEnabledKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }

  // Vérifie si un PIN est configuré
  Future<bool> isPinSet() async {
    final key = await _k(_kPinSetKey);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    }
    final value = await _storage.read(key: key);
    return value == 'true';
  }

  // Vérifie si la biométrie est disponible (Android uniquement)
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  // Enregistre un PIN (hashé avant stockage)
  Future<void> setPin(String pin) async {
    final hashed = _hashPin(pin);
    final pinKey = await _k(_kPinKey);
    final pinSetKey = await _k(_kPinSetKey);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pinKey, hashed);
      await prefs.setBool(pinSetKey, true);
    } else {
      await _storage.write(key: pinKey, value: hashed);
      await _storage.write(key: pinSetKey, value: 'true');
    }
    await setSecurityEnabled(true);
  }

  // Vérifie un PIN
  Future<bool> verifyPin(String pin) async {
    final hashed = _hashPin(pin);
    final key = await _k(_kPinKey);
    String? stored;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      stored = prefs.getString(key);
    } else {
      stored = await _storage.read(key: key);
    }
    return stored == hashed;
  }

  // Authentification biométrique
  Future<bool> authenticateWithBiometric({String? reason}) async {
    if (kIsWeb || !(await isBiometricAvailable())) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason ?? 'Confirmez votre identité pour continuer',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // Supprime le PIN et désactive la sécurité
  Future<void> clearPin() async {
    final pinKey = await _k(_kPinKey);
    final pinSetKey = await _k(_kPinSetKey);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pinKey);
      await prefs.setBool(pinSetKey, false);
    } else {
      await _storage.delete(key: pinKey);
      await _storage.write(key: pinSetKey, value: 'false');
    }
    await setSecurityEnabled(false);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}budgetflow_salt_v1');
    return sha256.convert(bytes).toString();
  }
}
