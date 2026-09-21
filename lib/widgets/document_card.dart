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

  const DocumentCard({
    super.key,
    required this.originalFileName,
    required this.info,
    required this.fileNameController,
    required this.isSaving,
    required this.isSaved,
    required this.onSave,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                InfoChip(
                  icon: Icons.euro,
                  label: 'Betrag',
                  value: info.amount,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // Vorgeschlagener Dateiname
            // ------------------------------------------------------------
            const Text(
              'Dateiname',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
            // Speichern
            // ------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving || isSaved ? null : onSave,
                icon: Icon(
                  isSaved ? Icons.check : Icons.save,
                ),
                label: Text(
                  isSaved
                      ? 'Gespeichert'
                      : isSaving
                          ? 'Speichere...'
                          : 'Datei speichern',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------------
            // Rohtext
            // ------------------------------------------------------------
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                'Extrahierter Text',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
}