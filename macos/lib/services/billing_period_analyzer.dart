import 'analyzer_context.dart';
import 'analyzer_result.dart';

class BillingPeriodAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final match = RegExp(
      r'(?:abrechnungszeitraum|leistungszeitraum)\s*:?\s*'
      r'(\d{1,2}\.\d{1,2}\.\d{2,4})\s*(?:-|–|—|bis)\s*'
      r'(\d{1,2}\.\d{1,2}\.\d{2,4})',
      caseSensitive: false,
    ).firstMatch(context.normalizedText);

    if (match == null) {
      return const AnalyzerResult(
        value: '',
        confidence: 0.0,
        evidence: '',
        source: 'BillingPeriodAnalyzer',
      );
    }

    return AnalyzerResult(
      value: '${match.group(1)} - ${match.group(2)}',
      confidence: 0.98,
      evidence: match.group(0) ?? '',
      source: 'BillingPeriodAnalyzer',
    );
  }
}
