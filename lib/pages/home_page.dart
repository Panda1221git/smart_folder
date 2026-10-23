import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/document_info.dart';
import '../services/document_analyzer.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_area.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AnalyzedDocument> _documents = [];

  // Behält die zuletzt ausgewählten Dateien im Speicher,
  // damit wir sie mit "Aktualisieren" erneut analysieren können.
  List<PlatformFile> _lastPickedFiles = [];

  bool _isLoading = false;

  Future<void> _pickFiles() async {
    final files = await FileService.pickPdfFiles();

    if (files.isEmpty) {
      return;
    }

    _lastPickedFiles = List<PlatformFile>.from(files);
    await _analyzeFiles(files);
  }

  Future<void> _refreshDocuments() async {
    if (_lastPickedFiles.isEmpty) {
      return;
    }

    await _analyzeFiles(
      _lastPickedFiles,
      replaceExisting: true,
    );
  }

  Future<void> _analyzeFiles(
    List<PlatformFile> files, {
    bool replaceExisting = false,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (replaceExisting) {
      for (final document in _documents) {
        document.dispose();
      }

      setState(() {
        _documents.clear();
      });
    }

    try {
      for (final file in files) {
        try {
          final bytes = await file.readAsBytes();
          final text = PdfService.extractText(bytes);
          final info = DocumentAnalyzer.analyze(text);

          final document = AnalyzedDocument(
            originalFileName: file.name,
            bytes: bytes,
            info: info,
          );

          if (!mounted) {
            document.dispose();
            return;
          }

          setState(() {
            _documents.add(document);
          });
        } catch (e) {
          final document = AnalyzedDocument(
            originalFileName: file.name,
            bytes: null,
            info: DocumentInfo(
              documentType: 'Fehler',
              sender: '',
              date: '',
              billingPeriod: '',
              invoiceNumber: '',
              amount: '',
              netAmount: '',
              taxAmount: '',
              taxRate: '',
              recipient: '',
              suggestedFileName: '',
              rawText: '',
            ),
            error: e.toString(),
          );

          if (!mounted) {
            document.dispose();
            return;
          }

          setState(() {
            _documents.add(document);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDocument(AnalyzedDocument document) async {
    if (document.bytes == null) {
      return;
    }

    setState(() {
      document.isSaving = true;
    });

    try {
      final result = await FileService.saveFile(
        fileName: document.fileNameController.text,
        bytes: document.bytes!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        document.isSaving = false;
        if (result != null) {
          document.isSaved = true;
        }
      });

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datei erfolgreich gespeichert.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        document.isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
        ),
      );
    }
  }

  void _clearDocuments() {
    for (final document in _documents) {
      document.dispose();
    }

    setState(() {
      _documents.clear();
    });
  }

  @override
  void dispose() {
    for (final document in _documents) {
      document.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_special),
            SizedBox(width: 10),
            Text(
              'SmartFolder',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (_lastPickedFiles.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _refreshDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Aktualisieren'),
            ),
          if (_documents.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _clearDocuments,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Leeren'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                UploadArea(
                  onPickFiles: _pickFiles,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _documents.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deine Dokumente.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'SmartFolder erkennt wichtige Informationen und schlägt '
          'einen sinnvollen Dateinamen vor.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

 
Widget _buildEmptyState() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Noch keine Dokumente',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wähle oben eine oder mehrere PDF-Rechnungen aus.',
            textAlign: TextAlign.center,
          ),
          if (_lastPickedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _refreshDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Letzte PDFs erneut analysieren'),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildDocumentList() {
    return ListView.builder(
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];

        if (document.error != null) {
          return _buildErrorCard(document);
        }

        return DocumentCard(
          originalFileName: document.originalFileName,
          info: document.info,
          fileNameController: document.fileNameController,
          isSaving: document.isSaving,
          isSaved: document.isSaved,
          onSave: () => _saveDocument(document),
        );
      },
    );
  }

  Widget _buildErrorCard(AnalyzedDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.originalFileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dieses Dokument konnte nicht verarbeitet werden.',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.error ?? 'Unbekannter Fehler',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyzedDocument {
  final String originalFileName;
  final Uint8List? bytes;
  final DocumentInfo info;
  final String? error;
  final TextEditingController fileNameController;

  bool isSaving;
  bool isSaved;

  AnalyzedDocument({
    required this.originalFileName,
    required this.bytes,
    required this.info,
    this.error,
    TextEditingController? fileNameController,
    this.isSaving = false,
    this.isSaved = false,
  }) : fileNameController = fileNameController ??
            TextEditingController(
              text: info.suggestedFileName,
            );

  void dispose() {
    fileNameController.dispose();
  }
}
