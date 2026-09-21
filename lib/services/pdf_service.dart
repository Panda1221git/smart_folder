import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Extrahiert den Text aus einem PDF.
  static String extractText(Uint8List bytes) {
    final PdfDocument document = PdfDocument(
      inputBytes: bytes,
    );

    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }
}