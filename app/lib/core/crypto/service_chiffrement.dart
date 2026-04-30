import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constantes_app.dart';

class ServiceChiffrement {
  ServiceChiffrement._();
  static final ServiceChiffrement instance = ServiceChiffrement._();

  final _stockageSecurise = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  enc.Key? _cle;

  Future<void> initialiser() async {
    final cleStockee =
        await _stockageSecurise.read(key: ConstantesApp.cleCryptoStorage);

    if (cleStockee != null) {
      _cle = enc.Key(base64Decode(cleStockee));
    } else {
      final random = Random.secure();
      final octets = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)),
      );
      _cle = enc.Key(octets);
      await _stockageSecurise.write(
        key: ConstantesApp.cleCryptoStorage,
        value: base64Encode(octets),
      );
    }
  }

  String chiffrer(String texte) {
    _verifierCle();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypteur = enc.Encrypter(enc.AES(_cle!, mode: enc.AESMode.gcm));
    final resultat = encrypteur.encrypt(texte, iv: iv);
    return '${base64Encode(iv.bytes)}:${resultat.base64}';
  }

  String dechiffrer(String donneeChiffree) {
    _verifierCle();
    try {
      final parties = donneeChiffree.split(':');
      if (parties.length != 2) return donneeChiffree;
      final iv = enc.IV(base64Decode(parties[0]));
      final encrypteur = enc.Encrypter(enc.AES(_cle!, mode: enc.AESMode.gcm));
      return encrypteur.decrypt64(parties[1], iv: iv);
    } catch (_) {
      return donneeChiffree;
    }
  }

  String chiffrerDouble(double valeur) => chiffrer(valeur.toString());

  double dechiffrerDouble(String donneeChiffree) {
    return double.tryParse(dechiffrer(donneeChiffree)) ?? 0.0;
  }

  void _verifierCle() {
    if (_cle == null) {
      throw StateError(
          'ServiceChiffrement non initialisé. Appelez initialiser() d\'abord.');
    }
  }
}
