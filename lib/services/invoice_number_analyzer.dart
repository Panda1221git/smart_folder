
import 'analyzer_context.dart';
import 'analyzer_result.dart';

class InvoiceNumberAnalyzer {
  static final List<RegExp> _labelPatterns = [
    RegExp(
      r'\b(?:rechnungs[\s-]*(?:nummer|nr\.?)|'
      r'rechnung[\s-]*(?:nummer|nr\.?))\s*[:#]?\s*(.+)$',
      caseSensitive: false,
    ),
    RegExp(
      r'\bbeleg[\s-]*(?:nummer|nr\.?)\s*[:#]?\s*(.+)$',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:invoice\s*(?:number|no\.?|#)|'
      r'document\s*(?:number|no\.?))\s*[:#]?\s*(.+)$',
      caseSensitive: false,
    ),
    // Neues Format: "Rechnung 2026338754"
    RegExp(
      r'\brechnung\s*[:#]?\s*(\d{4,})\b',
      caseSensitive: false,
    ),
  ];

  static final RegExp _labelOnly = RegExp(
    r'^\s*(?:'
    r'rechnungs[\s-]*(?:nummer|nr\.?)|'
    r'rechnung[\s-]*(?:nummer|nr\.?)|'
    r'beleg[\s-]*(?:nummer|nr\.?)|'
    r'invoice\s*(?:number|no\.?)|'
    r'document\s*(?:number|no\.?)'
    r')\s*[:#]?\s*$',
    caseSensitive: false,
  );

  static AnalyzerResult analyze(AnalyzerContext context) {
    final lines = context.lines;

    // Pass 1: Bezeichnung und Nummer in derselben Zeile.
    for (final line in lines) {
      for (final pattern in _labelPatterns) {
        final match = pattern.firstMatch(line);
        if (match == null) continue;

        final candidate = _firstIdentifier(match.group(1)!);

        if (_valid(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.98,
            evidence: line,
            source: 'InvoiceNumberAnalyzer',
          );
        }
      }
    }

    // Pass 2: Bezeichnung und Nummer in getrennten Zeilen.
    for (var i = 0; i < lines.length; i++) {
      if (!_labelOnly.hasMatch(lines[i])) continue;

      for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
        final next = lines[j].trim();

        if (next.isEmpty) continue;
        if (_isOtherField(next)) break;

        final candidate = _firstIdentifier(next);

        if (_valid(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.94,
            evidence: '${lines[i]} → $next',
            source: 'InvoiceNumberAnalyzer',
          );
        }
      }
    }

    // Pass 3: Nummer steht vor dem Feldlabel, z. B. ZOLL-frei.
    for (var i = 0; i < lines.length; i++) {
      final label = lines[i].toLowerCase().trim();

      if (!_labelOnly.hasMatch(lines[i])) continue;

      if (label.contains('belegnummer') || label.contains('beleg-nr')) {
        if (i >= 2) {
          final candidate = _firstIdentifier(lines[i - 2]);

          if (_valid(candidate) &&
              RegExp(r'^\d{6}$').hasMatch(candidate)) {
            return AnalyzerResult(
              value: candidate,
              confidence: 0.99,
              evidence: '${lines[i - 2]} → ${lines[i]}',
              source: 'InvoiceNumberAnalyzer',
            );
          }
        }

        if (i >= 1) {
          final candidate = _firstIdentifier(lines[i - 1]);

          if (_valid(candidate)) {
            return AnalyzerResult(
              value: candidate,
              confidence: 0.90,
              evidence: '${lines[i - 1]} → ${lines[i]}',
              source: 'InvoiceNumberAnalyzer',
            );
          }
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0,
      evidence: '',
      source: 'InvoiceNumberAnalyzer',
    );
  }

  static String _firstIdentifier(String value) {
    var cleaned = value.trim().replaceFirst(
      RegExp(r'^[:#\s]+'),
      '',
    );

    cleaned = cleaned
        .split(
          RegExp(
            r'\s+(?=(?:'
            r'kunden?[- ]?(?:nummer|nr\.?)|'
            r'kundennummer|'
            r'rechnungsdatum|belegdatum|'
            r'auftrags(?:nummer|nr\.?)|'
            r'bestell(?:nummer|nr\.?)|'
            r'sachbearbeiter|'
            r'ihre\s+uid|'
            r'gesamtbetrag|rechnungsendbetrag'
            r')\b)',
            caseSensitive: false,
          ),
        )
        .first
        .trim();

    final match = RegExp(
      r'^([A-Z0-9][A-Z0-9._/-]*)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    return match?.group(1) ?? '';
  }

  static bool _isOtherField(String line) {
    final lower = line.toLowerCase().trim();

    const otherFields = <String>[
      'kundennummer',
      'kunden-nr',
      'kunden nr',
      'kunden nr.',
      'rechnungsdatum',
      'belegdatum',
      'sachbearbeiter',
      'auftragsnummer',
      'auftrags-nr',
      'bestellnummer',
      'bestell-nr',
      'ihre uid',
      'gesamtbetrag',
      'rechnungsendbetrag',
    ];

    return otherFields.any(
      (field) =>
          lower == field ||
          lower.startsWith('$field:') ||
          lower.startsWith('$field '),
    );
  }

  static bool _valid(String value) {
    if (value.length < 3 || value.length > 40) return false;
    if (!RegExp(r'\d').hasMatch(value)) return false;

    if (RegExp(r'^\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(value)) {
      return false;
    }

    if (RegExp(r'^\d+,\d{2}$').hasMatch(value)) {
      return false;
    }

    final lower = value.toLowerCase();

    const blocked = <String>[
      'datum',
      'kunde',
      'kundennummer',
      'bestellung',
      'bestellnummer',
      'auftrag',
      'auftragsnummer',
      'sachbearbeiter',
      'rechnungsnummer',
      'rechnungsdatum',
      'belegnummer',
      'belegdatum',
    ];

    return !blocked.any(lower.contains);
  }
}
