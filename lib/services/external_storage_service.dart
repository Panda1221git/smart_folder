
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class ExternalStorageService {
  static const String _storagePathKey = 'smart_folder_archive_path';

  /// Gibt den gespeicherten Archivordner zurück.
  static Future<String?> getArchivePath() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storagePathKey);
  }

  /// Lässt den Benutzer einen Archivordner auswählen.
  static Future<String?> selectArchiveFolder() async {
    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'SmartFolder-Archivordner auswählen',
    );

    if (selectedPath == null) {
      return null;
    }

    final directory = Directory(selectedPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storagePathKey, directory.path);

    return directory.path;
  }

  /// Erstellt den passenden Jahres- und Quartalsordner.
  static Future<String?> getQuarterFolder({
    required DateTime invoiceDate,
  }) async {
    final archivePath = await getArchivePath();

    if (archivePath == null || archivePath.trim().isEmpty) {
      return null;
    }

    final quarter = ((invoiceDate.month - 1) ~/ 3) + 1;

    final folderPath = p.join(
      archivePath,
      invoiceDate.year.toString(),
      'Q$quarter',
    );

    final directory = Directory(folderPath);
    await directory.create(recursive: true);

    return directory.path;
  }

  /// Kopiert eine PDF ins Archiv. Das Original bleibt unverändert.
  /// Bestehende Dateien werden nicht überschrieben.
  static Future<String?> copyPdfToArchive({
    required String sourcePath,
    required DateTime invoiceDate,
    String? preferredFileName,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Die Quelldatei wurde nicht gefunden.',
        sourcePath,
      );
    }

    final folderPath = await getQuarterFolder(
      invoiceDate: invoiceDate,
    );

    if (folderPath == null) {
      return null;
    }

    final originalName = preferredFileName == null ||
            preferredFileName.trim().isEmpty
        ? p.basename(sourcePath)
        : preferredFileName.trim();

    final safeName = _sanitizeFileName(originalName);
    final extension = p.extension(safeName).isEmpty
        ? '.pdf'
        : p.extension(safeName);

    final baseName = p.basenameWithoutExtension(safeName);
    var destinationPath = p.join(folderPath, '$baseName$extension');
    var counter = 1;

    while (await File(destinationPath).exists()) {
      destinationPath = p.join(
        folderPath,
        '${baseName}_$counter$extension',
      );
      counter++;
    }

    final copiedFile = await sourceFile.copy(destinationPath);
    return copiedFile.path;
  }

  static String _sanitizeFileName(String fileName) {
    final cleaned = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim();

    return cleaned.isEmpty ? 'Dokument.pdf' : cleaned;
  }
}
