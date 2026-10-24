import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  /// Öffnet den macOS-Dateiauswahldialog und lässt mehrere PDFs auswählen.
  static Future<List<PlatformFile>> pickPdfFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    return files;
  }

  /// Öffnet den Speichern-Dialog und speichert die Datei.
  static Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return FilePicker.saveFile(fileName: fileName, bytes: bytes);
  }

/// Speichert eine dauerhafte Kopie im internen SmartFolder-Speicher.
static Future<String> storeDocument({
  required String id,
  required String fileName,
  required Uint8List bytes,
}) async {
  final appDirectory = await getApplicationSupportDirectory();

  final documentDirectory = Directory(
    p.join(appDirectory.path, 'SmartFolder', 'documents'),
  );

  if (!await documentDirectory.exists()) {
    await documentDirectory.create(recursive: true);
  }

  final safeName = fileName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .trim();

  final storedFile = File(
    p.join(documentDirectory.path, '${id}_$safeName'),
  );

  await storedFile.writeAsBytes(bytes, flush: true);

  return storedFile.path;
}


/// Löscht eine intern gespeicherte PDF-Datei.
static Future<void> deleteStoredDocument(String filePath) async {
  final appDirectory = await getApplicationSupportDirectory();

  final documentDirectory = Directory(
    p.join(appDirectory.path, 'SmartFolder', 'documents'),
  );

  final normalizedDirectory = p.normalize(documentDirectory.path);
  final normalizedFilePath = p.normalize(filePath);

  // Verhindert, dass versehentlich Dateien außerhalb
  // des internen Dokumentenordners gelöscht werden.
  final expectedPrefix =
      '$normalizedDirectory${p.separator}';

  if (!p.isWithin(normalizedDirectory, normalizedFilePath) ||
      !normalizedFilePath.startsWith(expectedPrefix)) {
    throw ArgumentError(
      'Die Datei liegt nicht im internen SmartFolder-Dokumentenordner.',
    );
  }

  final file = File(normalizedFilePath);

  if (await file.exists()) {
    await file.delete();
  }
}

}
