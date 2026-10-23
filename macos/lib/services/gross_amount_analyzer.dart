import 'analyzer_context.dart';
import 'analyzer_result.dart';

class GrossAmountAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    const priorityLabels = [
      'noch zu zahlen',
      'zahlbetrag',
      'restbetrag',
      'offener betrag',
      'zu zahlen',
    ];

    for (final line in context.lines) {
      final lower = line.toLowerCase();

      for (final label in priorityLabels) {
        final index = lower.indexOf(label);
        if (index < 0) continue;

        final tail = line.substring(index + label.length);
        final money = _moneyMatches(tail);

        if (money.isNotEmpty) {
          return AnalyzerResult(
            value: money.first,
            confidence: 0.99,
            evidence: line,
            source: 'GrossAmountAnalyzer',
          );
        }
      }
    }

    const labels = [
      'rechnungsbetrag',
      'gesamtbetrag',
      'gesamtpreis brutto',
      'bruttobetrag',
      'endbetrag',
      'zahlbetrag',
      'zu zahlen',
    ];

    for (final line in context.lines) {
      final lower = line.toLowerCase();

      for (final label in labels) {
        final index = lower.indexOf(label);
        if (index < 0) continue;

        final tail = line.substring(index + label.length);

        // Explicitly handles "Rechnungsbetrag EUR 1.816,61".
        final explicit = RegExp(
          r'(?:EUR|€)\s*((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})',
          caseSensitive: false,
        ).firstMatch(tail);

        if (explicit != null) {
          return AnalyzerResult(
            value: '${explicit.group(1)} €',
            confidence: 0.99,
            evidence: line,
            source: 'GrossAmountAnalyzer',
          );
        }

        final money = _moneyMatches(tail);
        if (money.isNotEmpty) {
          return AnalyzerResult(
            value: money.first,
            confidence: 0.95,
            evidence: line,
            source: 'GrossAmountAnalyzer',
          );
        }
      }
    }

    for (var i = 0; i < context.lines.length; i++) {
      final lower = context.lines[i].toLowerCase();
      if (!labels.any(lower.contains)) continue;

      for (var j = i + 1; j < context.lines.length && j <= i + 2; j++) {
        final money = _moneyMatches(context.lines[j]);
        if (money.isNotEmpty) {
          return AnalyzerResult(
            value: money.first,
            confidence: 0.88,
            evidence: '${context.lines[i]} → ${context.lines[j]}',
            source: 'GrossAmountAnalyzer',
          );
        }
        if (_looksLikeDocumentField(context.lines[j])) break;
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'GrossAmountAnalyzer',
    );
  }

  static List<String> _moneyMatches(String line) {
    final regex = RegExp(
      r'(?<![\d.])(?:EUR|€)?\s*((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})\s*(?:€|EUR)?',
      caseSensitive: false,
    );

    return [for (final match in regex.allMatches(line)) '${match.group(1)!} €'];
  }

  static bool _looksLikeDocumentField(String value) {
    final lower = value.toLowerCase();
    const fields = [
      'rechnungsnummer',
      'rechnungs-nr',
      'rechnungs nr',
      'rechnungsdatum',
      'rechnungsbetrag',
      'kundennummer',
      'bestellnummer',
      'auftragsnummer',
      'abrechnungszeitraum',
      'gesamtbetrag',
      'mehrwertsteuer',
      'umsatzsteuer',
    ];
    return fields.any(lower.contains);
  }
}
