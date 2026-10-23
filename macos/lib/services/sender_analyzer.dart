import 'analyzer_context.dart';
import 'analyzer_result.dart';

class SenderAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final lines = context.lines;
    final headerLimit = lines.length < 25 ? lines.length : 25;

    for (var i = 0; i < headerLimit; i++) {
      final raw = lines[i];
      if (_isForbiddenSenderLine(raw)) continue;

      final company = _extractCompanyName(raw);
      if (company.isEmpty) continue;
      if (!_hasCompanySuffix(company)) continue;

      return AnalyzerResult(
        value: company,
        confidence: 0.97,
        evidence: raw,
        source: 'SenderAnalyzer',
      );
    }

    for (var i = 0; i < headerLimit && i < 12; i++) {
      final raw = lines[i];
      if (_isForbiddenSenderLine(raw)) continue;

      final company = _extractCompanyName(raw);
      if (company.isEmpty || _looksLikePersonName(company)) continue;
      if (!_containsBusinessWord(company)) continue;

      return AnalyzerResult(
        value: company,
        confidence: 0.82,
        evidence: raw,
        source: 'SenderAnalyzer',
      );
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'SenderAnalyzer',
    );
  }

  static bool _isForbiddenSenderLine(String value) {
    final lower = value.toLowerCase();
    if (_looksLikeBankInformation(value)) return true;
    if (_looksLikeAddress(value)) return true;
    if (lower.contains('@') || _containsUrl(value)) return true;

    const forbidden = [
      'rechnungsnummer',
      'rechnungs-nr',
      'rechnungs nr',
      'rechnungsdatum',
      'rechnungs datum',
      'rechnungsbetrag',
      'abrechnungszeitraum',
      'leistungszeitraum',
      'gesamtbetrag',
      'gesamtpreis',
      'mehrwertsteuer',
      'umsatzsteuer',
      'kundennummer',
      'kunden-nr',
      'sachbearbeiter',
      'bestellnummer',
      'bestell-nr',
      'auftragsnummer',
      'auftrags-nr',
      'lieferdatum',
      'lieferanschrift',
      'zahlung',
      'zahlungsart',
      'kunden',
    ];

    return forbidden.any(lower.contains);
  }

  static String _extractCompanyName(String raw) {
    var value = raw.trim();

    for (final separator in [',', ' - ', ' | ']) {
      final index = value.indexOf(separator);
      if (index <= 0) continue;

      final before = value.substring(0, index).trim();
      if (_hasCompanySuffix(before) || _containsBusinessWord(before)) {
        value = before;
        break;
      }
    }

    final legalName = RegExp(
      r'^(.+?(?:GmbH\s*&\s*Co\.\s*KG|GmbH|AG|KG|UG|OHG|GbR|e\.?\s*K\.?|S\.?\s*A\.?|SARL|Ltd\.?|Limited))(?:\s|,|-|$)',
      caseSensitive: false,
    ).firstMatch(value);

    if (legalName != null) {
      value = legalName.group(1)!.trim();
    }

    final suffixEnd = RegExp(
      r'^(.+?(?:GmbH\s*&\s*Co\.\s*KG|GmbH|AG|KG|UG|OHG|GbR|e\.?\s*K\.?|S\.?\s*A\.?|SARL|Ltd\.?|Limited))$',
      caseSensitive: false,
    ).firstMatch(value);

    if (suffixEnd != null) {
      value = suffixEnd.group(1)!.trim();
    }

    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _hasCompanySuffix(String value) {
    return RegExp(
      r'(?:GmbH\s*&\s*Co\.\s*KG|GmbH|AG|KG|UG|OHG|GbR|e\.?\s*K\.?|S\.?\s*A\.?|SARL|Ltd\.?|Limited)\s*$',
      caseSensitive: false,
    ).hasMatch(value.trim());
  }

  static bool _containsBusinessWord(String value) {
    final lower = value.toLowerCase();
    const words = [
      'consultants',
      'consulting',
      'handel',
      'services',
      'solutions',
      'logistik',
      'versicherung',
      'parts',
      'buchhaltung',
      'agentur',
      'technik',
      'shop',
      'essentialbag',
      'unzer',
      'agricola',
    ];
    return words.any(lower.contains);
  }

  static bool _looksLikePersonName(String value) {
    return RegExp(
      r'^[A-ZÄÖÜ][A-Za-zÄÖÜäöüß-]+\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß-]+$',
    ).hasMatch(value.trim());
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
      'zahlungsdaten',
      'zahlungsempfänger',
      'zahlungsempfaenger',
    ];
    if (bankWords.any(lower.contains)) return true;

    final compact = value.replaceAll(RegExp(r'\s+'), '');
    return RegExp(
      r'^(?:DE|AT|LU|CH|FR|BE|NL|IT|ES|PT|IE|DK|SE|NO|FI)[A-Z0-9]{12,}$',
      caseSensitive: false,
    ).hasMatch(compact);
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
      'boulevard',
      'allee',
      'road',
    ];
    return words.any(lower.contains);
  }

  static bool _containsUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('www.') ||
        lower.contains('http://') ||
        lower.contains('https://');
  }
}
