import 'dart:typed_data';

void triggerWebDownload({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  throw UnsupportedError('Web download non disponible sur cette plateforme.');
}
