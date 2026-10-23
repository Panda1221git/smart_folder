import 'analyzer_context.dart';
import 'analyzer_result.dart';

class DateAnalyzer {
  static final _germanDate = RegExp(r'\d{1,2}\.\d{1,2}\.\d{2,4}');
  static final _isoDate = RegExp(r'\d{4}-\d{2}-\d{2}');

  static AnalyzerResult analyze(AnalyzerContext context) {
    final patterns = [
      RegExp(
        r'(?:rechnungs[\s-]*datum|rechnung[\s-]*datum)\s*:?\s*(' +
            _germanDate.pattern + r'|' + _isoDate.pattern + r')',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:ausstellungsdatum|ausgestellt\s+am|belegdatum)\s*:?\s*(' +
            _germanDate.pattern + r'|' + _isoDate.pattern + r')',
        caseSensitive: false,
      ),
      RegExp(
        r'\bdatum\s*:?\s*(' +
            _germanDate.pattern + r'|' + _isoDate.pattern + r')',
        caseSensitive: false,
      ),
      RegExp(
        r'\brechnung\s+vom\s+(' +
            _germanDate.pattern + r'|' + _isoDate.pattern + r')',
        caseSensitive: false,
      ),
    ];

    for (var patternIndex = 0; patternIndex < patterns.length; patternIndex++) {
      for (final line in context.lines) {
        final match = patterns[patternIndex].firstMatch(line);
        if (match == null) continue;

        final value = match.group(1) ?? '';
        if (!_isValidDate(value)) continue;

        return AnalyzerResult(
          value: value,
          confidence: patternIndex == 0 ? 0.99 : patternIndex == 3 ? 0.90 : 0.96,
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

  static bool _isValidDate(String value) {
    int year;
    int month;
    int day;

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      final parts = value.split('-');
      year = int.parse(parts[0]);
      month = int.parse(parts[1]);
      day = int.parse(parts[2]);
    } else {
      final match = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4})$')
          .firstMatch(value);
      if (match == null) return false;
      day = int.parse(match.group(1)!);
      month = int.parse(match.group(2)!);
      year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
    }

    if (year < 1900 || year > 2200 || month < 1 || month > 12) return false;
    final lastDay = DateTime(year, month + 1, 0).day;
    return day >= 1 && day <= lastDay;
  }
}
