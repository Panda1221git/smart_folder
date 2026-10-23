import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/analyzer_context.dart';
import 'package:smart_folder/services/date_analyzer.dart';

void main() {
  group('DateAnalyzer', () {
    test('erkennt ein eindeutig beschriftetes deutsches Rechnungsdatum', () {
      final context = AnalyzerContext.fromText('Rechnungsdatum: 16.10.2026');
      final result = DateAnalyzer.analyze(context);

      expect(result.value, '16.10.2026');
      expect(result.confidence, greaterThan(0));
    });

    test('erkennt ein ISO-Datum', () {
      final context = AnalyzerContext.fromText('Rechnungsdatum: 2026-10-16');
      final result = DateAnalyzer.analyze(context);

      expect(result.value, '2026-10-16');
    });

    test('verwirft ein ungültiges Kalenderdatum', () {
      final context = AnalyzerContext.fromText('Rechnungsdatum: 31.02.2026');
      final result = DateAnalyzer.analyze(context);

      expect(result.value, isEmpty);
    });

    test('erkennt Schaltjahre korrekt', () {
      final context = AnalyzerContext.fromText('Rechnungsdatum: 29.02.2024');
      final result = DateAnalyzer.analyze(context);

      expect(result.value, '29.02.2024');
    });
  });
}
