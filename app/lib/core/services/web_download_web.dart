import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void declencherTelechargementWeb({
  required String nomFichier,
  required Uint8List octets,
  required String typeMime,
}) {
  final blob = web.Blob(
    [octets.toJS].toJS,
    web.BlobPropertyBag(type: typeMime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = nomFichier
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
