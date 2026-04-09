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

  Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_kSaltLength, (_) => random.nextInt(256)),
    );
  }

  Future<SecretKey> deriveKey(String password, Uint8List salt) async {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<Map<String, dynamic>> encrypt(
    List<int> plaintext,
    String password,
  ) async {
    final normalized = _normalizePlaintext(plaintext);
    final salt = generateSalt();
    final key = await deriveKey(password, salt);
    final secretBox = await _aesGcm.encrypt(
      normalized.bytes,
      secretKey: key,
    );

    return {
      'v': _kFormatVersion,
      'algo': 'aes-gcm-256',
      'kdf': 'pbkdf2-hmac-sha256',
      'encoding': normalized.encoding,
      'iterations': _kIterations,
      'salt': base64.encode(salt),
      'nonce': base64.encode(secretBox.nonce),
      'mac': base64.encode(secretBox.mac.bytes),
      'ct': base64.encode(secretBox.cipherText),
    };
  }

  Future<List<int>> decrypt(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    final version = envelope['v'] as int? ?? 1;
    if (version != _kFormatVersion) {
      throw const EncryptionException('Version de format non supportée.');
    }

    final encoding = envelope['encoding'] as String? ?? 'bytes';
    final salt = base64.decode(envelope['salt'] as String);
    final nonce = base64.decode(envelope['nonce'] as String);
    final mac = base64.decode(envelope['mac'] as String);
    final ciphertext = base64.decode(envelope['ct'] as String);

    final key = await deriveKey(password, Uint8List.fromList(salt));

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );

    try {
      final decrypted = await _aesGcm.decrypt(secretBox, secretKey: key);
      if (encoding == 'utf8-string') {
        return utf8.decode(decrypted).codeUnits;
      }
      return decrypted;
    } on SecretBoxAuthenticationError catch (_) {
      throw const EncryptionException(
        'Mot de passe incorrect ou fichier corrompu.',
      );
    }
  }

  _NormalizedPlaintext _normalizePlaintext(List<int> plaintext) {
    final hasNonByteValue = plaintext.any((value) => value < 0 || value > 255);
    if (!hasNonByteValue) {
      return _NormalizedPlaintext(
        bytes: List<int>.from(plaintext),
        encoding: 'bytes',
      );
    }

    return _NormalizedPlaintext(
      bytes: utf8.encode(String.fromCharCodes(plaintext)),
      encoding: 'utf8-string',
    );
  }
}

class _NormalizedPlaintext {
  final List<int> bytes;
  final String encoding;

  const _NormalizedPlaintext({required this.bytes, required this.encoding});
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
