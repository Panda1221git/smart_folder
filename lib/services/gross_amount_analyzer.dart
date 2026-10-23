
import 'analyzer_context.dart';
import 'analyzer_result.dart';

class GrossAmountAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final lines = context.lines;

    const preferredLabels = <String>[
      'rechnungsendbetrag',
      'noch zu zahlen',
      'gesamtbetrag',
      'zahlbetrag',
      'bruttobetrag',
      'gesamtpreis brutto',
      'offener betrag',
      'restbetrag',
      'zu zahlen',
      'rechnungsbetrag',
      'endbetrag',
    ];

    // PASS 1:
    // Zuerst Beträge NACH einem Label suchen.
    // Das umfasst dieselbe Zeile und bis zu drei Folgezeilen.
    // So wird bei SÜWE nicht versehentlich ein vorheriger Betrag gewählt.
    for (final label in preferredLabels) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        final index = lower.indexOf(label);

        if (index < 0) continue;

        final tail = line.substring(index + label.length);
        final after = _moneyMatches(tail);

        if (after.isNotEmpty) {
          return AnalyzerResult(
            value: after.first,
            confidence: 0.99,
            evidence: '$label → $tail',
            source: 'GrossAmountAnalyzer',
          );
        }

        // Betrag steht möglicherweise in einer Folgezeile.
        for (var forward = 1;
            forward <= 3 && i + forward < lines.length;
            forward++) {
          final next = lines[i + forward].trim();

          if (next.isEmpty || _isCurrencyOnly(next)) {
            continue;
          }

          // Steuer-/Nettozeilen nicht als Brutto-Folgezeile verwenden.
          if (_isTaxOrNetLine(next.toLowerCase())) break;
          if (_looksLikeDocumentField(next)) break;

          final money = _moneyMatches(next);

          if (money.isNotEmpty) {
            return AnalyzerResult(
              value: money.first,
              confidence: 0.95,
              evidence: '$line → $next',
              source: 'GrossAmountAnalyzer',
            );
          }
        }
      }
    }

    // PASS 2:
    // Erst wenn nach keinem Label ein Betrag gefunden wurde,
    // Beträge VOR Labels prüfen. Das unterstützt ZOLL-frei.
    for (final label in preferredLabels) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        final index = lower.indexOf(label);

        if (index < 0) continue;

        final before = _moneyMatches(line.substring(0, index));

        if (before.isNotEmpty) {
          return AnalyzerResult(
            value: before.last,
            confidence: 0.90,
            evidence: '${line.substring(0, index)} → $label',
            source: 'GrossAmountAnalyzer',
          );
        }

        // Betrag kann in einer der vorherigen Zeilen stehen.
        for (var back = 1; back <= 3 && i - back >= 0; back++) {
          final previous = lines[i - back].trim();

          if (previous.isEmpty || _isCurrencyOnly(previous)) {
            continue;
          }

          if (_isTaxOrNetLine(previous.toLowerCase())) break;
          if (_looksLikeDocumentField(previous)) break;

          final money = _moneyMatches(previous);

          if (money.isNotEmpty) {
            return AnalyzerResult(
              value: money.last,
              confidence: 0.85,
              evidence: '$previous → $label',
              source: 'GrossAmountAnalyzer',
            );
          }
        }
      }
    }

    // PASS 3:
    // Fallback für Summenzeilen, wenn kein passendes Label gefunden wurde.
    for (final line in lines) {
      final lower = line.toLowerCase().trim();

      if (!lower.startsWith('summe')) continue;
      if (_isTaxOrNetLine(lower)) continue;

      final money = _moneyMatches(line);

      if (money.isNotEmpty) {
        return AnalyzerResult(
          value: money.last,
          confidence: 0.65,
          evidence: line,
          source: 'GrossAmountAnalyzer',
        );
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'GrossAmountAnalyzer',
    );
  }

  static bool _isTaxOrNetLine(String lower) {
    return lower.contains('mehrwertsteuer') ||
        lower.contains('umsatzsteuer') ||
        lower.contains('mwst') ||
        lower.contains('steuerbetrag') ||
        RegExp(r'\bnetto\b').hasMatch(lower) ||
        RegExp(r'\bust\.?\b').hasMatch(lower);
  }

  static bool _isCurrencyOnly(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'EUR' || normalized == '€';
  }

  static bool _looksLikeDocumentField(String value) {
    final lower = value.toLowerCase();

    const fields = <String>[
      'rechnungsnummer',
      'rechnungs-nr',
      'rechnungs nr',
      'rechnungsdatum',
      'belegnummer',
      'belegdatum',
      'kundennummer',
      'bestellnummer',
      'auftragsnummer',
      'abrechnungszeitraum',
    ];

    return fields.any(lower.contains);
  }

  static List<String> _moneyMatches(String text) {
    final regex = RegExp(
      r'(?<![\d.])'
      r'(?:(?:EUR|€)\s*)?'
      r'((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})'
      r'\s*(?:€|EUR)?',
      caseSensitive: false,
    );

    return [
      for (final match in regex.allMatches(text))
        '${match.group(1)!} €',
    ];
  }
}
