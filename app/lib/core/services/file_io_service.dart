import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';

class FileIoService {
  static final FileIoService instance = FileIoService._();
  FileIoService._();

  Future<void> enregistrerEtPartager({
    required String nomFichier,
    required List<int> octets,
    required String typeMime,
    String? sujet,
    String? sousDossier,
  }) async {
    if (kIsWeb) {
      declencherTelechargementWeb(
        nomFichier: nomFichier,
        octets: Uint8List.fromList(octets),
        typeMime: typeMime,
      );
      return;
    }
    final dossierBase = await getApplicationDocumentsDirectory();
    final Directory dossierCible = sousDossier != null
        ? Directory('${dossierBase.path}/$sousDossier')
        : dossierBase;
    if (sousDossier != null) {
      await dossierCible.create(recursive: true);
    }
    final cheminFichier = '${dossierCible.path}/$nomFichier';
    await File(cheminFichier).writeAsBytes(octets);
    await Share.shareXFiles(
      [XFile(cheminFichier, mimeType: typeMime)],
      subject: sujet ?? nomFichier,
    );
  }

  Future<PickedFile?> choisirFichier({
    List<String>? extensionsAutorisees,
  }) async {
    final resultat = await FilePicker.platform.pickFiles(
      type: extensionsAutorisees != null ? FileType.custom : FileType.any,
      allowedExtensions: extensionsAutorisees,
      withData: true,
    );
    if (resultat == null || resultat.files.isEmpty) return null;
    final fichier = resultat.files.first;
    final octets = fichier.bytes;
    if (octets == null) return null;
    return PickedFile(nom: fichier.name, octets: octets);
  }
}

class PickedFile {
  final String nom;
  final Uint8List octets;
  const PickedFile({required this.nom, required this.octets});
}
