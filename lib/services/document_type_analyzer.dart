import 'analyzer_context.dart';
import 'analyzer_result.dart';

class DocumentTypeAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final lower = context.normalizedText.toLowerCase();

    if (lower.contains('gutschrift')) {
      return const AnalyzerResult(
        value: 'Gutschrift',
        confidence: 0.99,
        evidence: 'gutschrift',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (lower.contains('auftragsbestätigung') ||
        lower.contains('auftragsbestaetigung')) {
      return const AnalyzerResult(
        value: 'Auftragsbestätigung',
        confidence: 0.99,
        evidence: 'auftragsbestätigung',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (lower.contains('bestellbestätigung') ||
        lower.contains('bestellbestaetigung')) {
      return const AnalyzerResult(
        value: 'Bestellbestätigung',
        confidence: 0.99,
        evidence: 'bestellbestätigung',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (RegExp(r'\bbestellung\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Bestellung',
        confidence: 0.97,
        evidence: 'bestellung',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (lower.contains('allgemeine geschäftsbedingungen') ||
        lower.contains('allgemeine geschaeftsbedingungen') ||
        RegExp(r'\bagb\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'AGB',
        confidence: 0.99,
        evidence: 'AGB / allgemeine Geschäftsbedingungen',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (RegExp(r'\bangebot\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Angebot',
        confidence: 0.97,
        evidence: 'angebot',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (RegExp(r'\bmahnung\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Mahnung',
        confidence: 0.97,
        evidence: 'mahnung',
        source: 'DocumentTypeAnalyzer',
      );
    }
    if (RegExp(r'\brechnung\b').hasMatch(lower)) {
      return const AnalyzerResult(
        value: 'Rechnung',
        confidence: 0.99,
        evidence: 'rechnung',
        source: 'DocumentTypeAnalyzer',
      );
    }

    return const AnalyzerResult(
      value: 'Dokument',
      confidence: 0.40,
      evidence: '',
      source: 'DocumentTypeAnalyzer',
    );
  }
}
