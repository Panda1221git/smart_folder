import 'package:flutter/material.dart';

import '../models/document_info.dart';
import 'info_chip.dart';

class DocumentCard extends StatelessWidget {
  final String originalFileName;
  final DocumentInfo info;
  final TextEditingController fileNameController;

  final bool isSaving;
  final bool isSaved;
  final VoidCallback onSave;
  final String? storedFilePath;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DocumentCard({
    super.key,
    required this.originalFileName,
    required this.info,
    required this.fileNameController,
    required this.isSaving,
    required this.isSaved,
    required this.onSave,
    this.storedFilePath,
    this.onOpen,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // Dateiname
            // ------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.picture_as_pdf),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    originalFileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // Erkannte Informationen
            // ------------------------------------------------------------
            const Text(
              'Erkannte Informationen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  icon: Icons.description,
                  label: 'Typ',
                  value: info.documentType,
                ),
                InfoChip(
                  icon: Icons.business,
                  label: 'Absender',
                  value: info.sender,
                ),
                InfoChip(
                  icon: Icons.calendar_today,
                  label: 'Datum',
                  value: info.date,
                ),
                InfoChip(
                  icon: Icons.numbers,
                  label: 'Rechnungsnummer',
                  value: info.invoiceNumber,
                ),
                InfoChip(icon: Icons.euro, label: 'Betrag', value: info.amount),
              ],
            ),

ExpansionTile(
  tilePadding: EdgeInsets.zero,
  childrenPadding: const EdgeInsets.only(bottom: 12),
  title: const Text(
    'Alle Rechnungsdaten anzeigen',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
  children: [
    _detailRow('Empfänger', info.recipient),
    _detailRow('Abrechnungszeitraum', info.billingPeriod),
    _detailRow('Nettobetrag', info.netAmount),
    _detailRow('Steuerbetrag', info.taxAmount),
    _detailRow('Steuersatz', info.taxRate),
  ],
),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // Vorgeschlagener Dateiname
            // ------------------------------------------------------------
            const Text(
              'Dateiname',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
                hintText: 'Dateiname',
              ),
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------------
            
if (onEdit != null) ...[
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_note),
      label: const Text('Rechnungsdaten bearbeiten'),
    ),
  ),
  const SizedBox(height: 12),
],

            // Speichern
            // ------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving || isSaved ? null : onSave,
                icon: Icon(isSaved ? Icons.check : Icons.save),
                label: Text(
                  isSaved
                      ? 'Gespeichert'
                      : isSaving
                      ? 'Speichere...'
                      : 'Datei speichern',
                ),
              ),
            ),

            
if (storedFilePath != null && onOpen != null) ...[
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.open_in_new),
      label: const Text('PDF öffnen'),
    ),
  ),
  const SizedBox(height: 12),
],


if (onDelete != null) ...[
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Dokument löschen'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    ),
  ),
  const SizedBox(height: 12),
],


            const SizedBox(height: 12),

            // ------------------------------------------------------------
            // Rohtext
            // ------------------------------------------------------------
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                'Extrahierter Text',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      info.rawText.isEmpty
                          ? 'Kein Text gefunden.'
                          : info.rawText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'Nicht erkannt' : value,
            ),
          ),
        ],
      ),
    );
  }
}
