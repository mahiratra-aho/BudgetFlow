import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de sécurité: PIN + biométrie (Android), PIN uniquement (Web)
class SecurityService {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

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

  /// Vérifie si la sécurité est activée
  Future<bool> isSecurityEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSecurityEnabledKey) ?? false;
  }

  Future<void> setSecurityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSecurityEnabledKey, enabled);
  }

  /// Vérifie si un PIN est configuré
  Future<bool> isPinSet() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPinSetKey) ?? false;
    }
    final value = await _storage.read(key: _kPinSetKey);
    return value == 'true';
  }

  /// Vérifie si la biométrie est disponible (Android uniquement)
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

  /// Enregistre un PIN (hashé avant stockage)
  Future<void> setPin(String pin) async {
    final hashed = _hashPin(pin);
    if (kIsWeb) {
      // Sur le Web: stockage dans SharedPreferences (chiffrement limité)
      // Pour une vraie app Web, utiliser le Web Crypto API
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPinKey, hashed);
      await prefs.setBool(_kPinSetKey, true);
    } else {
      await _storage.write(key: _kPinKey, value: hashed);
      await _storage.write(key: _kPinSetKey, value: 'true');
    }
    await setSecurityEnabled(true);
  }

  /// Vérifie un PIN
  Future<bool> verifyPin(String pin) async {
    final hashed = _hashPin(pin);
    String? stored;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      stored = prefs.getString(_kPinKey);
    } else {
      stored = await _storage.read(key: _kPinKey);
    }
    return stored == hashed;
  }

  /// Authentification biométrique
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

  /// Supprime le PIN et désactive la sécurité
  Future<void> clearPin() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPinKey);
      await prefs.setBool(_kPinSetKey, false);
    } else {
      await _storage.delete(key: _kPinKey);
      await _storage.write(key: _kPinSetKey, value: 'false');
    }
    await setSecurityEnabled(false);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}budgetflow_salt_v1');
    return sha256.convert(bytes).toString();
  }
}
