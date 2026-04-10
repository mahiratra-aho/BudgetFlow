import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._();
  EncryptionService._();

  static const int _kIterations = 100000;
  static const int _kSaltLength = 32;
  static const int _kFormatVersion = 1;

  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _kIterations,
    bits: 256,
  );

  final _aesGcm = AesGcm.with256bits();

  Uint8List genererSel() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_kSaltLength, (_) => random.nextInt(256)),
    );
  }

  Future<SecretKey> deriverCle(String motDePasse, Uint8List sel) async {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(motDePasse)),
      nonce: sel,
    );
  }

  Future<Map<String, dynamic>> chiffrer(
    List<int> texteClair,
    String motDePasse,
  ) async {
    final sel = genererSel();
    final cle = await deriverCle(motDePasse, sel);
    final boiteSecrete = await _aesGcm.encrypt(texteClair, secretKey: cle);

    return {
      'v': _kFormatVersion,
      'algo': 'aes-gcm-256',
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _kIterations,
      'salt': base64.encode(sel),
      'nonce': base64.encode(boiteSecrete.nonce),
      'mac': base64.encode(boiteSecrete.mac.bytes),
      'ct': base64.encode(boiteSecrete.cipherText),
    };
  }

  Future<List<int>> dechiffrer(
    Map<String, dynamic> enveloppe,
    String motDePasse,
  ) async {
    final version = enveloppe['v'] as int? ?? 1;
    if (version != _kFormatVersion) {
      throw const EncryptionException('Version de format non supportée.');
    }

    final sel = base64.decode(enveloppe['salt'] as String);
    final nonce = base64.decode(enveloppe['nonce'] as String);
    final mac = base64.decode(enveloppe['mac'] as String);
    final texteChiffre = base64.decode(enveloppe['ct'] as String);

    final cle = await deriverCle(motDePasse, Uint8List.fromList(sel));

    final boiteSecrete = SecretBox(
      texteChiffre,
      nonce: nonce,
      mac: Mac(mac),
    );

    try {
      return await _aesGcm.decrypt(boiteSecrete, secretKey: cle);
    } on SecretBoxAuthenticationError catch (_) {
      throw const EncryptionException(
        'Mot de passe incorrect ou fichier corrompu.',
      );
    }
  }
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
