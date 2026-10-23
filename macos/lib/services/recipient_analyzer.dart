import 'analyzer_context.dart';
import 'analyzer_result.dart';

class RecipientAnalyzer {
  static AnalyzerResult analyze(
    AnalyzerContext context,
    String sender,
  ) {
    const labels = [
      'rechnung an',
      'rechnungsadresse',
      'rechnungsempfänger',
      'rechnungsempfaenger',
      'lieferanschrift',
      'empfänger',
      'empfaenger',
    ];

    for (var i = 0; i < context.lines.length; i++) {
      final lower = context.lines[i].toLowerCase();
      if (!labels.any(lower.contains)) continue;

      for (var j = i + 1; j < context.lines.length && j <= i + 6; j++) {
        final candidate = context.lines[j];

        if (_looksLikeBankInformation(candidate)) continue;
        if (_looksLikeDocumentField(candidate)) break;
        if (_looksLikeAddress(candidate)) continue;
        if (candidate == sender) continue;

        if (_looksLikePersonName(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.93,
            evidence: candidate,
            source: 'RecipientAnalyzer',
          );
        }

        if (candidate.length >= 3 && candidate.length <= 70) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.78,
            evidence: candidate,
            source: 'RecipientAnalyzer',
          );
        }
      }
    }

    for (var i = 0; i < context.lines.length; i++) {
      if (context.lines[i].toLowerCase() != 'rechnung') continue;

      for (var j = i + 1; j < context.lines.length && j <= i + 5; j++) {
        final candidate = context.lines[j];

        if (_looksLikeBankInformation(candidate) ||
            _looksLikeAddress(candidate) ||
            _looksLikeDocumentField(candidate)) {
          continue;
        }

        if (candidate != sender && candidate.length >= 3) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.72,
            evidence: candidate,
            source: 'RecipientAnalyzer',
          );
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'RecipientAnalyzer',
    );
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
      'lieferdatum',
    ];
    return fields.any(lower.contains);
  }

  static bool _looksLikeBankInformation(String value) {
    final lower = value.toLowerCase();
    const bankWords = [
      'iban',
      'bic',
      'bankverbindung',
      'kontoverbindung',
      'kontonummer',
      'bankkonto',
      'swift',
    ];
    return bankWords.any(lower.contains);
  }

  static bool _looksLikeAddress(String value) {
    final lower = value.toLowerCase();
    if (RegExp(r'\b\d{5}\b').hasMatch(value)) return true;
    if (RegExp(r'\b[A-Z]-\d{4}\b', caseSensitive: false).hasMatch(value)) {
      return true;
    }
    const words = [
      'straße',
      'strasse',
      'str.',
      'gasse',
      'weg',
      'platz',
      'rue',
      'avenue',
    ];
    return words.any(lower.contains);
  }

  static bool _looksLikePersonName(String value) {
    return RegExp(
      r'^[A-ZÄÖÜ][A-Za-zÄÖÜäöüß-]+\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß-]+$',
    ).hasMatch(value.trim());
  }
}
