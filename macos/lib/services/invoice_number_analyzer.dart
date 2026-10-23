import 'analyzer_context.dart';
import 'analyzer_result.dart';

class InvoiceNumberAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final labelPatterns = [
      RegExp(
        r'\brechnungs[\s-]*nummer\s*:?\s*(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'\brechnungs[\s-]*nr\.?\s*:?\s*(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'\brechnung[\s-]*nummer\s*:?\s*(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'\brechnung[\s-]*nr\.?\s*:?\s*(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final line in context.lines) {
      for (final pattern in labelPatterns) {
        final match = pattern.firstMatch(line);
        if (match == null) continue;

        final candidate = _firstIdentifier(match.group(1)!);
        if (_valid(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.99,
            evidence: line,
            source: 'InvoiceNumberAnalyzer',
          );
        }
      }
    }

    for (var i = 0; i < context.lines.length; i++) {
      if (!_isInvoiceLabelOnly(context.lines[i])) continue;

      for (var j = i + 1; j < context.lines.length && j <= i + 3; j++) {
        final next = context.lines[j];
        if (_isOtherNumberField(next) || _isOtherInvoiceField(next)) break;

        final candidate = _firstIdentifier(next);
        if (_valid(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.96,
            evidence: '${context.lines[i]} → $next',
            source: 'InvoiceNumberAnalyzer',
          );
        }
      }
    }

    final compact = RegExp(
      r'^\s*rechnung\s+([A-Z0-9][A-Z0-9._/-]{2,})\s*$',
      caseSensitive: false,
    );

    for (final line in context.lines) {
      final match = compact.firstMatch(line);
      if (match == null) continue;

      final candidate = _firstIdentifier(match.group(1)!);
      if (_valid(candidate)) {
        return AnalyzerResult(
          value: candidate,
          confidence: 0.94,
          evidence: line,
          source: 'InvoiceNumberAnalyzer',
        );
      }
    }

    if (_containsInvoiceLabel(context.lines)) {
      final standalone = RegExp(
        r'^(?:RE|RG|R)\d{5,}$',
        caseSensitive: false,
      );

      for (final line in context.lines) {
        final candidate = _firstIdentifier(line);
        if (standalone.hasMatch(candidate) && _valid(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.88,
            evidence: line,
            source: 'InvoiceNumberAnalyzer',
          );
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'InvoiceNumberAnalyzer',
    );
  }

  static bool _isInvoiceLabelOnly(String line) {
    return RegExp(
      r'^\s*(?:rechnungs[\s-]*(?:nummer|nr\.?)|rechnung[\s-]*(?:nummer|nr\.?))\s*:?\s*$',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _containsInvoiceLabel(List<String> lines) {
    return lines.any(
      (line) => RegExp(
        r'\brechnungs[\s-]*(?:nummer|nr\.?)\b',
        caseSensitive: false,
      ).hasMatch(line),
    );
  }

  static bool _isOtherNumberField(String line) {
    final lower = line.toLowerCase();
    const fields = [
      'auftragsnummer',
      'auftrags-nr',
      'auftrags nr',
      'bestellnummer',
      'bestell-nr',
      'bestell nr',
      'kundennummer',
      'kunden-nr',
      'kunden nr',
      'kundenummer',
    ];
    return fields.any(lower.contains);
  }

  static bool _isOtherInvoiceField(String line) {
    final lower = line.toLowerCase();
    return lower.contains('sachbearbeiter') ||
        lower.contains('rechnungsdatum') ||
        lower.contains('rechnungs datum') ||
        lower.contains('rechnungsbetrag') ||
        lower.contains('abrechnungszeitraum') ||
        lower.contains('lieferdatum');
  }

  static String _firstIdentifier(String value) {
    var cleaned = value.trim().replaceFirst(RegExp(r'^[:#\s]+'), '');

    final separator = RegExp(
      r'\s+(?=(?:kunde|kunden[- ]?nummer|datum|auftragsnummer|auftrags[- ]?nr|bestellnummer|bestell[- ]?nr|sachbearbeiter)\b)',
      caseSensitive: false,
    );

    cleaned = cleaned.split(separator).first.trim();

    final match = RegExp(
      r'^([A-Z0-9][A-Z0-9._/-]*)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    return match?.group(1) ?? '';
  }

  static bool _valid(String value) {
    if (value.length < 3 || value.length > 35) return false;
    if (!RegExp(r'\d').hasMatch(value)) return false;
    if (RegExp(r'^\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(value) ||
        RegExp(r'^\d+,\d{2}$').hasMatch(value)) {
      return false;
    }

    final lower = value.toLowerCase();
    const blocked = [
      'datum',
      'kunde',
      'kundennummer',
      'kundenummer',
      'bestellung',
      'bestellnummer',
      'auftrag',
      'auftragsnummer',
      'sachbearbeiter',
      'rechnungsnummer',
      'rechnungsdatum',
      'rechnungsbetrag',
    ];
    return !blocked.any(lower.contains);
  }
}
