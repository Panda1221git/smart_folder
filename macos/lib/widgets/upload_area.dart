import 'package:flutter/material.dart';

class UploadArea extends StatelessWidget {
  final VoidCallback onPickFiles;
  final bool isLoading;

  const UploadArea({
    super.key,
    required this.onPickFiles,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF-Rechnungen auswählen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wähle eine oder mehrere PDF-Dateien aus.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isLoading ? null : onPickFiles,
              icon: const Icon(Icons.upload_file),
              label: Text(
                isLoading ? 'Verarbeite Dateien...' : 'PDFs auswählen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}