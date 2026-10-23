
import 'analyzer_context.dart';
import 'analyzer_result.dart';

class SenderAnalyzer {
  static final RegExp _legalSuffix = RegExp(
    r'\b(?:GmbH\s*&\s*Co\.?\s*KG|'
    r'mbH\s*&\s*Co\.?\s*KG|'
    r'AG\s*&\s*Co\.?\s*KG|'
    r'UG\s*\(haftungsbeschränkt\)|'
    r'GmbH|mbH|'
    r'Aktiengesellschaft|'
    r'Kommanditgesellschaft|'
    r'Inc\.?|Incorporated|LLC|Ltd\.?|Limited|PLC|'
    r'SARL|SAS|S\.A\.|S\.R\.L\.|OHG|GbR|KG|AG)'
    r'(?=\s|,|;|:|[-–—|·•]|$)',
    caseSensitive: false,
  );

  static const List<String> _recipientMarkers = [
    'rechnung an',
    'rechnungsempfänger',
    'rechnungsempfaenger',
    'lieferanschrift',
    'lieferadresse',
    'kundenadresse',
    'zahlungspflichtiger',
    'bill to',
    'invoice to',
    'ship to',
    'sold to',
  ];

  static const List<String> _issuerMarkers = [
    'impressum',
    'herausgeber',
    'aussteller',
    'firmenanschrift',
    'sitz der gesellschaft',
  ];

  static AnalyzerResult analyze(AnalyzerContext context) {
    final lines = context.lines;

    if (lines.isEmpty) {
      return const AnalyzerResult(
        value: '',
        confidence: 0,
        evidence: '',
        source: 'SenderAnalyzer',
      );
    }

    // PASS 1: Explizite Angaben zum Rechnungsaussteller.
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();

      if (!_issuerMarkers.any(lower.contains)) continue;

      for (var j = i; j < lines.length && j <= i + 5; j++) {
        final candidate = _extractLegalName(lines[j]);

        if (candidate.isNotEmpty &&
            !_isForbiddenLine(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.97,
            evidence: lines[j],
            source: 'SenderAnalyzer',
          );
        }
      }
    }

    // PASS 2: Firmennamen im gesamten Dokument suchen.
    var inRecipientBlock = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (_startsRecipientSection(lower)) {
        inRecipientBlock = true;
        continue;
      }

      if (inRecipientBlock) {
        if (_looksLikeIssuerSection(lower)) {
          inRecipientBlock = false;
        } else {
          continue;
        }
      }

      // WICHTIG:
      // Erst den Firmennamen extrahieren, dann prüfen.
      // Eine Firmenzeile darf zusätzlich eine Adresse enthalten.
      final candidate = _extractLegalName(line);

      if (candidate.isNotEmpty) {
        if (_isForbiddenLine(candidate)) continue;

        if (RegExp(
          r'\bGmbH\s*&\s*Co\.?\s*KG\b',
          caseSensitive: false,
        ).hasMatch(candidate)) {
          return AnalyzerResult(
            value: candidate,
            confidence: 0.99,
            evidence: line,
            source: 'SenderAnalyzer',
          );
        }

        return AnalyzerResult(
          value: candidate,
          confidence: i < 15 ? 0.96 : 0.88,
          evidence: line,
          source: 'SenderAnalyzer',
        );
      }

      // Zeilen ohne Rechtsform weiterhin filtern.
      if (_isForbiddenLine(line)) continue;
    }

    // PASS 3: Fallback für Firmennamen ohne Rechtsform.
    final fallbackLimit = lines.length < 15 ? lines.length : 15;

    for (var i = 0; i < fallbackLimit; i++) {
      final line = lines[i].trim();

      if (_isForbiddenLine(line)) continue;
      if (_startsRecipientSection(line.toLowerCase())) continue;
      if (_looksLikeAddress(line)) continue;

      final candidate = _stripContactInfo(line);

      if (candidate.length < 3 || candidate.length > 90) continue;
      if (!_containsBusinessWord(candidate)) continue;

      return AnalyzerResult(
        value: candidate,
        confidence: 0.65,
        evidence: line,
        source: 'SenderAnalyzer',
      );
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0,
      evidence: '',
      source: 'SenderAnalyzer',
    );
  }

  static String _extractLegalName(String raw) {
    final normalized = raw
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final match = _legalSuffix.firstMatch(normalized);

    if (match == null) return '';

    return normalized
        .substring(0, match.end)
        .replaceAll(RegExp(r'[\s,;:·•|-]+$'), '')
        .trim();
  }

  static bool _startsRecipientSection(String lower) {
    return _recipientMarkers.any(
      (marker) =>
          lower == marker ||
          lower.startsWith('$marker:') ||
          lower.startsWith('$marker '),
    );
  }

  static bool _looksLikeIssuerSection(String lower) {
    return _issuerMarkers.any(lower.contains);
  }

  static bool _isForbiddenLine(String value) {
    final lower = value.toLowerCase().trim();

    if (lower.isEmpty) return true;
    if (_looksLikeAddress(value)) return true;
    if (_looksLikeBankInformation(value)) return true;

    if (lower.contains('@') ||
        lower.contains('www.') ||
        lower.contains('http://') ||
        lower.contains('https://')) {
      return true;
    }

    const forbidden = <String>[
      'rechnungsnummer',
      'rechnungs-nr',
      'rechnungs nr',
      'rechnungsdatum',
      'rechnungsbetrag',
      'rechnungsendbetrag',
      'abrechnungszeitraum',
      'leistungszeitraum',
      'gesamtbetrag',
      'gesamtpreis',
      'mehrwertsteuer',
      'umsatzsteuer',
      'kundennummer',
      'kunden-nr',
      'bestellnummer',
      'auftragsnummer',
      'lieferdatum',
      'lieferanschrift',
      'lieferadresse',
      'zahlung',
      'zahlungsart',
      'zahlungsempfänger',
      'zahlungsempfaenger',
      'zahlungspflichtiger',
      'rechnung an',
      'rechnungsempfänger',
      'rechnungsempfaenger',
      'stichwort',
      'rubrik',
      'auftrag/position',
      'iban',
      'bic',
      'bankverbindung',
      'kontoverbindung',
      'telefon',
      'tel.',
      'fax',
      'e-mail',
      'email:',
      'sepa-lastschriftmandat',
      'einzugsermächtigung',
    ];

    return forbidden.any(lower.contains);
  }

  static bool _containsBusinessWord(String value) {
    final lower = value.toLowerCase();

    const words = <String>[
      'handel',
      'consultants',
      'consulting',
      'services',
      'solutions',
      'logistik',
      'versicherung',
      'agentur',
      'technik',
      'verlag',
      'vertrieb',
      'dienstleistung',
      'spedition',
      'software',
      'systems',
      'engineering',
      'industries',
      'manufaktur',
      'apotheke',
      'praxis',
      'klinik',
      'hotel',
      'immobilien',
      'maschinenbau',
      'metallbau',
      'recycling',
      'energie',
    ];

    return words.any(lower.contains);
  }

  static String _stripContactInfo(String raw) {
    var value = raw.trim();

    value = value.replaceAll(
      RegExp(r'\s+[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}.*$'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\s+https?://\S+.*$', caseSensitive: false),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\s+www\.\S+.*$', caseSensitive: false),
      '',
    );

    return value.trim();
  }

  static bool _looksLikeAddress(String value) {
    final lower = value.toLowerCase();

    if (RegExp(r'\b\d{5}\b').hasMatch(value)) return true;

    if (RegExp(r'\b[A-Z]-\d{4}\b', caseSensitive: false).hasMatch(value)) {
      return true;
    }

    const addressWords = <String>[
      'straße',
      'strasse',
      'str.',
      'gasse',
      'weg',
      'platz',
      'rue',
      'avenue',
      'boulevard',
      'allee',
      'road',
      'street',
      'drive',
      'lane',
      'highway',
    ];

    return addressWords.any(lower.contains);
  }

  static bool _looksLikeBankInformation(String value) {
    final lower = value.toLowerCase();

    const words = <String>[
      'iban',
      'bic',
      'bankverbindung',
      'kontoverbindung',
      'kontonummer',
      'bankkonto',
      'swift',
    ];

    if (words.any(lower.contains)) return true;

    final compact = value.replaceAll(RegExp(r'\s+'), '');

    return RegExp(
      r'^(?:DE|AT|LU|CH|FR|BE|NL|IT|ES|PT|IE|DK|SE|NO|FI)[A-Z0-9]{12,}$',
      caseSensitive: false,
    ).hasMatch(compact);
  }
}
