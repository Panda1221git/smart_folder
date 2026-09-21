import 'analyzer_context.dart';
import 'analyzer_result.dart';

class DateAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    final patterns = [
      RegExp(
        r'(?:rechnungs[\s-]*datum|rechnung[\s-]*datum)\s*:?\s*(\d{1,2}\.\d{1,2}\.\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:ausstellungsdatum|ausgestellt\s+am|belegdatum|datum)\s*:?\s*(\d{1,2}\.\d{1,2}\.\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final line in context.lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final value = match.group(1) ?? '';
          return AnalyzerResult(
            value: value,
            confidence: 0.98,
            evidence: line,
            source: 'DateAnalyzer',
          );
        }
      }
    }

    final fromPattern = RegExp(
      r'\brechnung\s+vom\s+(\d{1,2}\.\d{1,2}\.\d{2,4})',
      caseSensitive: false,
    );

    for (final line in context.lines) {
      final match = fromPattern.firstMatch(line);
      if (match != null) {
        return AnalyzerResult(
          value: match.group(1) ?? '',
          confidence: 0.90,
          evidence: line,
          source: 'DateAnalyzer',
        );
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'DateAnalyzer',
    );
  }
}
