
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dart:io';

class DocumentDatabaseService {
  DocumentDatabaseService._();

  static final DocumentDatabaseService instance =
      DocumentDatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    // SQLite für Windows initialisieren.
    sqfliteFfiInit();

    final databaseFactory = databaseFactoryFfi;
    final appDirectory = await getApplicationSupportDirectory();

    // SmartFolder erhält einen eigenen, dauerhaften Speicherort.
    final databaseDirectory = Directory(
      p.join(appDirectory.path, 'SmartFolder'),
    );

    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(recursive: true);
    }

    final databasePath = p.join(
      databaseDirectory.path,
      'smart_folder.db',
    );

    return databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,

        onUpgrade: (db, oldVersion, newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      ALTER TABLE documents
      ADD COLUMN suggested_file_name TEXT NOT NULL DEFAULT ''
    ''');

    await db.execute('''
      UPDATE documents
      SET suggested_file_name = original_file_name
      WHERE suggested_file_name = ''
    ''');
  }
},
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              original_file_name TEXT NOT NULL,
              suggested_file_name TEXT NOT NULL DEFAULT '',
              stored_file_path TEXT NOT NULL,
              document_type TEXT NOT NULL DEFAULT '',
              sender TEXT NOT NULL DEFAULT '',
              document_date TEXT NOT NULL DEFAULT '',
              billing_period TEXT NOT NULL DEFAULT '',
              invoice_number TEXT NOT NULL DEFAULT '',
              amount TEXT NOT NULL DEFAULT '',
              net_amount TEXT NOT NULL DEFAULT '',
              tax_amount TEXT NOT NULL DEFAULT '',
              tax_rate TEXT NOT NULL DEFAULT '',
              recipient TEXT NOT NULL DEFAULT '',
              raw_text TEXT NOT NULL DEFAULT '',
              imported_at TEXT NOT NULL
            )
          ''');

          await db.execute(
            'CREATE INDEX idx_documents_sender ON documents(sender)',
          );

          await db.execute(
            'CREATE INDEX idx_documents_date ON documents(document_date)',
          );

          await db.execute(
            'CREATE INDEX idx_documents_invoice_number '
            'ON documents(invoice_number)',
          );
        },
      ),
    );
  }

  /// Speichert ein Dokument oder aktualisiert einen vorhandenen Eintrag.
  Future<void> saveDocument(Map<String, Object?> document) async {
    final db = await database;

    await db.insert(
      'documents',
      document,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Liefert alle gespeicherten Dokumente.
  Future<List<Map<String, Object?>>> getAllDocuments() async {
    final db = await database;

    return db.query(
      'documents',
      orderBy: 'imported_at DESC',
    );
  }

  /// Sucht nach Firma, Rechnungsnummer, Betrag, Datum oder Dokumenttext.
  Future<List<Map<String, Object?>>> searchDocuments(
    String query,
  ) async {
    final db = await database;
    final searchTerm = '%${query.trim()}%';

    if (query.trim().isEmpty) {
      return getAllDocuments();
    }

    return db.query(
      'documents',
      where: '''
        sender LIKE ? OR
        invoice_number LIKE ? OR
        amount LIKE ? OR
        net_amount LIKE ? OR
        tax_amount LIKE ? OR
        document_date LIKE ? OR
        document_type LIKE ? OR
        raw_text LIKE ?
      ''',
      whereArgs: List.filled(8, searchTerm),
      orderBy: 'imported_at DESC',
    );
  }

  /// Löscht nur den Datenbankeintrag, nicht die PDF-Datei.
  Future<void> deleteDocument(String id) async {
    final db = await database;

    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


/// Aktualisiert die erkannten Rechnungsdaten eines Dokuments.
Future<void> updateDocument({
  required String id,
  required Map<String, Object?> values,
}) async {
  final db = await database;

  await db.update(
    'documents',
    values,
    where: 'id = ?',
    whereArgs: [id],
  );
}

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
