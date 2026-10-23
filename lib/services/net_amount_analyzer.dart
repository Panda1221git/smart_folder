import 'analyzer_context.dart';
import 'analyzer_result.dart';

class NetAmountAnalyzer {
  static AnalyzerResult analyze(AnalyzerContext context) {
    for (final line in context.lines) {
      final lower = line.toLowerCase();

      for (final label in ['nettobetrag', 'gesamtpreis netto']) {
        final index = lower.indexOf(label);
        if (index < 0) continue;

        final money = _moneyMatches(
          line.substring(index + label.length),
        );
        if (money.isNotEmpty) {
          return AnalyzerResult(
            value: money.first,
            confidence: 0.98,
            evidence: line,
            source: 'NetAmountAnalyzer',
          );
        }
      }

      if ((lower.contains('mehrwertsteuer') ||
              lower.contains('umsatzsteuer') ||
              lower.contains('mwst')) &&
          lower.contains('netto')) {
        final aufIndex = lower.indexOf('auf');
        if (aufIndex >= 0) {
          final money = _moneyMatches(line.substring(aufIndex + 3));
          if (money.isNotEmpty) {
            return AnalyzerResult(
              value: money.first,
              confidence: 0.94,
              evidence: line,
              source: 'NetAmountAnalyzer',
            );
          }
        }
      }

      if (lower.startsWith('summe ')) {
        final money = _moneyMatches(line);
        if (money.isNotEmpty) {
          return AnalyzerResult(
            value: money.first,
            confidence: 0.75,
            evidence: line,
            source: 'NetAmountAnalyzer',
          );
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'NetAmountAnalyzer',
    );
  }

  static List<String> _moneyMatches(String line) {
    final regex = RegExp(
      r'(?<![\d.])(?:EUR|€)?\s*((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})\s*(?:€|EUR)?',
      caseSensitive: false,
    );
    return [
      for (final match in regex.allMatches(line))
        '${match.group(1)!} €',
    ];
  }
}
