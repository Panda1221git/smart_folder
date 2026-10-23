
import 'analyzer_context.dart';
import 'analyzer_result.dart';

class DocumentTypeAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final lower = context.normalizedText.toLowerCase();

    // 1. Gutschrift
    if (lower.contains('gutschrift')) {
      return const AnalyzerResult(
        value: 'Gutschrift',
        confidence: 0.99,
        evidence: 'gutschrift',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 2. Auftragsbestätigung
    if (lower.contains('auftragsbestätigung') ||
        lower.contains('auftragsbestaetigung')) {
      return const AnalyzerResult(
        value: 'Auftragsbestätigung',
        confidence: 0.99,
        evidence: 'auftragsbestätigung',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 3. Bestellbestätigung
    if (lower.contains('bestellbestätigung') ||
        lower.contains('bestellbestaetigung')) {
      return const AnalyzerResult(
        value: 'Bestellbestätigung',
        confidence: 0.99,
        evidence: 'bestellbestätigung',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 4. Rechnung
    // Muss vor der allgemeinen Bestellungserkennung stehen,
    // da Rechnungen auch Bestellnummern enthalten können.
    const invoiceTerms = [
      'anzeigenrechnung',
      'rechnungs-nr',
      'rechnungsnummer',
      'rechnungsdatum',
      'rechnungsendbetrag',
      'rechnungsbetrag',
      'belegnummer',
      'beleg-nr',
      'belegdatum',
      'rechnung',
    ];

    for (final term in invoiceTerms) {
      if (lower.contains(term)) {
        return AnalyzerResult(
          value: 'Rechnung',
          confidence: 0.99,
          evidence: term,
          source: 'DocumentTypeAnalyzer',
        );
      }
    }

    // 5. Allgemeine Bestellung
    // Nur wenn zuvor keine Rechnung erkannt wurde.
    if (RegExp(r'\bbestellung\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Bestellung',
        confidence: 0.97,
        evidence: 'bestellung',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 6. Allgemeine Geschäftsbedingungen
    if (lower.contains('allgemeine geschäftsbedingungen') ||
        lower.contains('allgemeine geschaeftsbedingungen') ||
        RegExp(r'\bagb\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'AGB',
        confidence: 0.95,
        evidence: 'AGB',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 7. Angebot
    if (RegExp(r'\bangebot\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Angebot',
        confidence: 0.95,
        evidence: 'angebot',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 8. Mahnung
    if (RegExp(r'\bmahnung\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Mahnung',
        confidence: 0.95,
        evidence: 'mahnung',
        source: 'DocumentTypeAnalyzer',
      );
    }

    // 9. Fallback
    return const AnalyzerResult(
      value: 'Dokument',
      confidence: 0.40,
      evidence: '',
      source: 'DocumentTypeAnalyzer',
    );
  }
}
