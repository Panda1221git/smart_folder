import 'analyzer_context.dart';
import 'analyzer_result.dart';

class InvoiceNumberAnalyzer {
  static final List<RegExp> _labelPatterns = [
    RegExp(r'\b(?:rechnungs[\s-]*(?:nummer|nr\.?)|rechnung[\s-]*(?:nummer|nr\.?))\s*:?\s*(.+)$', caseSensitive: false),
    RegExp(r'\bbeleg[\s-]*(?:nummer|nr\.?)\s*:?\s*(.+)$', caseSensitive: false),
    RegExp(r'\b(?:invoice\s*(?:number|no\.?|#)|document\s*(?:number|no\.?))\s*:?\s*(.+)$', caseSensitive: false),
  ];

  static AnalyzerResult analyze(AnalyzerContext context) {
    for (final line in context.lines) {
      for (final pattern in _labelPatterns) {
        final match = pattern.firstMatch(line);
        if (match == null) continue;
        final candidate = _firstIdentifier(match.group(1)!);
        if (_valid(candidate)) {
          return AnalyzerResult(value: candidate, confidence: 0.98, evidence: line, source: 'InvoiceNumberAnalyzer');
        }
      }
    }

    // OCR/PDF extraction may put label and value on separate lines.
    final labelOnly = RegExp(r'^\s*(?:rechnungs[\s-]*(?:nummer|nr\.?)|rechnung[\s-]*(?:nummer|nr\.?)|beleg[\s-]*(?:nummer|nr\.?))\s*:?\s*$', caseSensitive: false);
    for (var i = 0; i < context.lines.length; i++) {
      if (!labelOnly.hasMatch(context.lines[i])) continue;
      for (var j = i + 1; j < context.lines.length && j <= i + 2; j++) {
        final next = context.lines[j];
        if (_isOtherField(next)) break;
        final candidate = _firstIdentifier(next);
        if (_valid(candidate)) {
          return AnalyzerResult(value: candidate, confidence: 0.94, evidence: '${context.lines[i]} → $next', source: 'InvoiceNumberAnalyzer');
        }
      }
    }

    return const AnalyzerResult(value: '', confidence: 0, evidence: '', source: 'InvoiceNumberAnalyzer');
  }

  static String _firstIdentifier(String value) {
    var cleaned = value.trim().replaceFirst(RegExp(r'^[:#\s]+'), '');
    // When PDF columns are flattened, stop before the next known field label.
    cleaned = cleaned.split(RegExp(r'\s+(?=(?:kunden?[- ]?(?:nummer|nr)|datum|auftrags(?:nummer|nr)|bestell(?:nummer|nr)|sachbearbeiter|ihre\s+uid)\b)', caseSensitive: false)).first.trim();
    final match = RegExp(r'^([A-Z0-9][A-Z0-9._/-]*)', caseSensitive: false).firstMatch(cleaned);
    return match?.group(1) ?? '';
  }

  static bool _isOtherField(String line) {
    final lower = line.toLowerCase();
    return ['kundennummer', 'kunden-nr', 'kunden nr', 'rechnungsdatum', 'belegdatum', 'sachbearbeiter', 'auftragsnummer', 'bestellnummer', 'ihre uid'].any(lower.contains);
  }

  static bool _valid(String value) {
    if (value.length < 3 || value.length > 40 || !RegExp(r'\d').hasMatch(value)) return false;
    if (RegExp(r'^\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(value) || RegExp(r'^\d+,\d{2}$').hasMatch(value)) return false;
    final lower = value.toLowerCase();
    const blocked = ['datum', 'kunde', 'kundennummer', 'bestellung', 'bestellnummer', 'auftrag', 'auftragsnummer', 'sachbearbeiter', 'rechnungsnummer', 'rechnungsdatum', 'belegnummer', 'belegdatum'];
    return !blocked.any(lower.contains);
  }
}
