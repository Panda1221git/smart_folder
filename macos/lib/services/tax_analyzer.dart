import 'analyzer_context.dart';
import 'analyzer_result.dart';

class TaxAnalyzer {
  static AnalyzerResult analyzeAmount(AnalyzerContext context) {
    for (var i = 0; i < context.lines.length; i++) {
      final line = context.lines[i];
      final lower = line.toLowerCase();

      if (!(lower.contains('mehrwertsteuer') ||
          lower.contains('umsatzsteuer') ||
          RegExp(r'\bmwst\.?\b').hasMatch(lower) ||
          RegExp(r'\bust\.?\b').hasMatch(lower))) {
        continue;
      }

      final money = _moneyMatches(line);
      if (money.isNotEmpty) {
        return AnalyzerResult(
          value: money.last,
          confidence: 0.96,
          evidence: line,
          source: 'TaxAmountAnalyzer',
        );
      }

      if (i > 0) {
        final previous = _moneyMatches(context.lines[i - 1]);
        if (previous.isNotEmpty) {
          return AnalyzerResult(
            value: previous.last,
            confidence: 0.82,
            evidence: context.lines[i - 1],
            source: 'TaxAmountAnalyzer',
          );
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'TaxAmountAnalyzer',
    );
  }

  static AnalyzerResult analyzeRate(AnalyzerContext context) {
    final rateRegex = RegExp(r'(\d{1,2}(?:[,.]\d+)?)\s*%');

    for (final line in context.lines) {
      final lower = line.toLowerCase();

      if (!(lower.contains('mehrwertsteuer') ||
          lower.contains('umsatzsteuer') ||
          lower.contains('mwst') ||
          lower.contains('ust'))) {
        continue;
      }

      final matches = rateRegex.allMatches(line);
      if (matches.isNotEmpty) {
        return AnalyzerResult(
          value: '${matches.first.group(1)} %',
          confidence: 0.98,
          evidence: line,
          source: 'TaxRateAnalyzer',
        );
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'TaxRateAnalyzer',
    );
  }

  static List<String> _moneyMatches(String line) {
    final regex = RegExp(
      r'(?<![\d.])(?:EUR|€)?\s*((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})\s*(?:€|EUR)?',
      caseSensitive: false,
    );
    return [for (final match in regex.allMatches(line)) '${match.group(1)!} €'];
  }
}
