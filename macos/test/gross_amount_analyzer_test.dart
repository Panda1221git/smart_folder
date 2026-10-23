import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/analyzer_context.dart';
import 'package:smart_folder/services/gross_amount_analyzer.dart';

void main() {
  group('GrossAmountAnalyzer', () {
    test('erkennt einen eindeutig beschrifteten Bruttobetrag', () {
      final context = AnalyzerContext.fromText('Rechnungsbetrag EUR 1.816,61');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '1.816,61 €');
      expect(result.confidence, greaterThan(0));
    });

    test('erkennt einen Betrag mit deutschem Tausendertrennzeichen', () {
      final context = AnalyzerContext.fromText('Gesamtbetrag: 9.690,19 €');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '9.690,19 €');
    });

    test('liefert keinen Betrag, wenn keiner vorhanden ist', () {
      final context = AnalyzerContext.fromText('Rechnung für Dienstleistungen');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, isEmpty);
    });

    test('bevorzugt den explizit beschrifteten Bruttobetrag', () {
      final context = AnalyzerContext.fromText('''
Nettobetrag: 8.143,02 EUR
Umsatzsteuer 19%: 1.547,17 EUR
Bruttobetrag: 9.690,19 EUR
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '9.690,19 €');
    });

    test('erkennt Währungsangabe vor dem Betrag beim Zahlbetrag', () {
      final context = AnalyzerContext.fromText('Noch zu zahlen: EUR 100,00');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '100,00 €');
    });

    test('erkennt den expliziten Zahlbetrag', () {
      final context = AnalyzerContext.fromText('''
Rechnungsbetrag: 120,00 EUR
Bereits bezahlt: 20,00 EUR
Noch zu zahlen: 100,00 EUR
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '100,00 €');
    });
  });
}
