import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

import '../models/document_info.dart';
import '../services/document_analyzer.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_area.dart';
import '../services/document_database_service.dart';

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

  
final TextEditingController _searchController =
    TextEditingController();

String _searchQuery = '';
  
@override
void initState() {
  super.initState();
  _loadSavedDocuments();
}

Future<void> _loadSavedDocuments() async {
  try {
    final savedDocuments =
        await DocumentDatabaseService.instance.getAllDocuments();

    if (!mounted) return;

    for (final row in savedDocuments) {
      final document = AnalyzedDocument(
        id: row['id'] as String?,
        originalFileName:
            row['original_file_name'] as String? ?? 'Unbekanntes Dokument',
        bytes: null,
        storedFilePath: row['stored_file_path'] as String?,
        info: DocumentInfo(
          documentType: row['document_type'] as String? ?? '',
          sender: row['sender'] as String? ?? '',
          date: row['document_date'] as String? ?? '',
          billingPeriod: row['billing_period'] as String? ?? '',
          invoiceNumber: row['invoice_number'] as String? ?? '',
          amount: row['amount'] as String? ?? '',
          netAmount: row['net_amount'] as String? ?? '',
          taxAmount: row['tax_amount'] as String? ?? '',
          taxRate: row['tax_rate'] as String? ?? '',
          recipient: row['recipient'] as String? ?? '',
          suggestedFileName:
              row['suggested_file_name'] as String? ??
              row['original_file_name'] as String? ??
              '',
          rawText: row['raw_text'] as String? ?? '',
        ),
        isSaved: true,
      );

      _documents.add(document);
    }

    setState(() {});
  } catch (e, stackTrace) {
    debugPrint('Fehler beim Laden der Dokumente: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}


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
  if (!mounted) return;

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
      String? storedFilePath;

      try {
        // 1. PDF einlesen
        final bytes = await file.readAsBytes();

        // 2. Vorhandene Dokumentenanalyse ausführen
        final text = PdfService.extractText(bytes);
        final info = DocumentAnalyzer.analyze(text);

        // 3. Eindeutige ID für den Datenbankeintrag erzeugen
        final id = DateTime.now().microsecondsSinceEpoch.toString();

        // 4. PDF dauerhaft im internen SmartFolder-Speicher ablegen
        storedFilePath = await FileService.storeDocument(
          id: id,
          fileName: file.name,
          bytes: bytes,
        );

        // 5. Analysierte Daten dauerhaft in SQLite speichern
        await DocumentDatabaseService.instance.saveDocument({
          'id': id,
          'original_file_name': file.name,
          'suggested_file_name': info.suggestedFileName,
          'stored_file_path': storedFilePath,
          'document_type': info.documentType,
          'sender': info.sender,
          'document_date': info.date,
          'billing_period': info.billingPeriod,
          'invoice_number': info.invoiceNumber,
          'amount': info.amount,
          'net_amount': info.netAmount,
          'tax_amount': info.taxAmount,
          'tax_rate': info.taxRate,
          'recipient': info.recipient,
          'raw_text': info.rawText,
          'imported_at': DateTime.now().toIso8601String(),
        });

        // 6. Dokument wie bisher in der Oberfläche anzeigen
        
final document = AnalyzedDocument(
  id: id,
  originalFileName: file.name,
  bytes: bytes,
  storedFilePath: storedFilePath,
  info: info,
  isSaved: true,
);


        if (!mounted) {
          document.dispose();
          return;
        }

        setState(() {
          _documents.add(document);
        });
      } catch (e) {
        debugPrint(
          'Fehler beim Importieren von ${file.name}: $e',
        );

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
          error: 'Import fehlgeschlagen: $e',
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

  
Future<void> _deleteDocument(AnalyzedDocument document) async {
  if (document.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dieses Dokument kann nicht gelöscht werden.'),
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Dokument löschen?'),
      content: Text(
        'Möchtest du „${document.originalFileName}“ '
        'dauerhaft aus SmartFolder löschen?\n\n'
        'Die interne PDF-Datei und der Datenbankeintrag '
        'werden dabei entfernt.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Endgültig löschen'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  try {
    // 1. Interne PDF-Datei entfernen, sofern vorhanden.
    if (document.storedFilePath != null) {
      await FileService.deleteStoredDocument(
        document.storedFilePath!,
      );
    }

    // 2. Datenbankeintrag entfernen.
    await DocumentDatabaseService.instance.deleteDocument(
      document.id!,
    );

    if (!mounted) return;

    // 3. Dokument aus der Oberfläche entfernen.
    setState(() {
      _documents.remove(document);
    });

    document.dispose();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dokument erfolgreich gelöscht.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fehler beim Löschen: $e'),
      ),
    );
  }
}


Future<void> _editDocument(AnalyzedDocument document) async {
  if (document.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dieses Dokument ist nicht dauerhaft gespeichert.'),
      ),
    );
    return;
  }

  final info = document.info;

  final typeController = TextEditingController(text: info.documentType);
  final senderController = TextEditingController(text: info.sender);
  final dateController = TextEditingController(text: info.date);
  final periodController = TextEditingController(text: info.billingPeriod);
  final numberController = TextEditingController(text: info.invoiceNumber);
  final amountController = TextEditingController(text: info.amount);
  final netController = TextEditingController(text: info.netAmount);
  final taxController = TextEditingController(text: info.taxAmount);
  final rateController = TextEditingController(text: info.taxRate);
  final recipientController = TextEditingController(text: info.recipient);

  try {
    final result = await showDialog<DocumentInfo>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechnungsdaten bearbeiten'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField('Dokumenttyp', typeController),
                _editField('Absender / Firma', senderController),
                _editField('Rechnungsdatum', dateController),
                _editField('Abrechnungszeitraum', periodController),
                _editField('Rechnungsnummer', numberController),
                _editField('Bruttobetrag', amountController),
                _editField('Nettobetrag', netController),
                _editField('Steuerbetrag', taxController),
                _editField('Steuersatz', rateController),
                _editField('Empfänger', recipientController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                DocumentInfo(
                  documentType: typeController.text.trim(),
                  sender: senderController.text.trim(),
                  date: dateController.text.trim(),
                  billingPeriod: periodController.text.trim(),
                  invoiceNumber: numberController.text.trim(),
                  amount: amountController.text.trim(),
                  netAmount: netController.text.trim(),
                  taxAmount: taxController.text.trim(),
                  taxRate: rateController.text.trim(),
                  recipient: recipientController.text.trim(),
                  suggestedFileName: info.suggestedFileName,
                  rawText: info.rawText,
                ),
              );
            },
            child: const Text('Änderungen speichern'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    await DocumentDatabaseService.instance.updateDocument(
      id: document.id!,
      values: {
        'document_type': result.documentType,
        'sender': result.sender,
        'document_date': result.date,
        'billing_period': result.billingPeriod,
        'invoice_number': result.invoiceNumber,
        'amount': result.amount,
        'net_amount': result.netAmount,
        'tax_amount': result.taxAmount,
        'tax_rate': result.taxRate,
        'recipient': result.recipient,
      },
    );

    if (!mounted) return;

    setState(() {
      document.info = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rechnungsdaten erfolgreich aktualisiert.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fehler beim Aktualisieren: $e'),
      ),
    );
  } finally {
    typeController.dispose();
    senderController.dispose();
    dateController.dispose();
    periodController.dispose();
    numberController.dispose();
    amountController.dispose();
    netController.dispose();
    taxController.dispose();
    rateController.dispose();
    recipientController.dispose();
  }
}

Widget _editField(
  String label,
  TextEditingController controller,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
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
              const SizedBox(height: 16),

              // Suchfeld
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Firma, Rechnungsnummer, Betrag oder Datum suchen ...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Suche zurücksetzen',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),

              const SizedBox(height: 16),
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
  final query = _searchQuery.trim().toLowerCase();

  final filteredDocuments = _documents.where((document) {
    if (query.isEmpty) {
      return true;
    }

    final info = document.info;

    final searchableText = [
      document.originalFileName,
      info.documentType,
      info.sender,
      info.date,
      info.billingPeriod,
      info.invoiceNumber,
      info.amount,
      info.netAmount,
      info.taxAmount,
      info.taxRate,
      info.recipient,
      info.rawText,
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }).toList();

  if (filteredDocuments.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Noch keine Dokumente vorhanden.'
                  : 'Keine passenden Dokumente gefunden.',
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Text('Suche zurücksetzen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  return ListView.builder(
    itemCount: filteredDocuments.length,
    itemBuilder: (context, index) {
      final document = filteredDocuments[index];

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
  onEdit: () => _editDocument(document),
  onDelete: () => _deleteDocument(document),
  storedFilePath: document.storedFilePath,
  onOpen: document.storedFilePath == null
      ? null
      : () async {
          await OpenFile.open(document.storedFilePath!);
        },
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
  DocumentInfo info;
  final String? error;

  // Daten für dauerhaft gespeicherte Dokumente
  final String? id;
  final String? storedFilePath;

  final TextEditingController fileNameController;

  bool isSaving;
  bool isSaved;

  AnalyzedDocument({
    required this.originalFileName,
    required this.bytes,
    required this.info,
    this.error,
    this.id,
    this.storedFilePath,
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
