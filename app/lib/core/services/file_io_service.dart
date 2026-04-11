import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';

class FileIoService {
  static final FileIoService instance = FileIoService._();
  FileIoService._();

  Future<void> saveAndShare({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    String? subject,
    String? subDirectory,
  }) async {
    if (kIsWeb) {
      triggerWebDownload(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
      );
      return;
    }
    final baseDir = await getApplicationDocumentsDirectory();
    final Directory targetDir = subDirectory != null
        ? Directory('${baseDir.path}/$subDirectory')
        : baseDir;
    if (subDirectory != null) {
      await targetDir.create(recursive: true);
    }
    final filePath = '${targetDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(filePath, mimeType: mimeType)],
      subject: subject ?? fileName,
    );
  }

  Future<PickedFile?> pickFile({List<String>? extensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: extensions != null ? FileType.custom : FileType.any,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final data = file.bytes;
    if (data == null) return null;
    return PickedFile(name: file.name, bytes: data);
  }
}

class PickedFile {
  final String name;
  final Uint8List bytes;
  const PickedFile({required this.name, required this.bytes});
}
