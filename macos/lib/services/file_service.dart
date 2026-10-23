import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
  }
}