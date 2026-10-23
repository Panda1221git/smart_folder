import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/analyzer_context.dart';
import 'package:smart_folder/services/gross_amount_analyzer.dart';

void main() {
  group('GrossAmountAnalyzer', () {
    test('erkennt einen eindeutig beschrifteten Rechnungsbetrag', () {
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

    test('Agricola: bevorzugt Gesamtbetrag vor Netto und Steuer', () {
      final context = AnalyzerContext.fromText('''
Summe 9.853,20 €
Mehrwertsteuer 7% auf 9.853,20 € netto 689,72 €
Gesamtbetrag 10.542,92 €689,72 €Mehrwertsteuer 7% auf 9.853,20 € netto
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '10.542,92 €');
    });

    test('ZOLL-frei: erkennt Betrag vor mehrzeiligem Gesamtbetrag', () {
      final context = AnalyzerContext.fromText('''
Steuerpflichtig (19%) 130,51
19% MwSt. von 130,51
24,80
EUR
715,59
EUR
D: Diese Leistung ist in Deutschland nicht steuerbar.
Gesamtbetrag
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '715,59 €');
    });

    test('Einzelposition wird nicht statt Gesamtbetrag ausgewählt', () {
      final context = AnalyzerContext.fromText('''
Rechnungsposition: 4,00 EUR
Weitere Position: 120,00 EUR
Gesamtbetrag: 124,00 EUR
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '124,00 €');
    });

    test('SÜWE: erkennt Rechnungsendbetrag statt Mehrwertsteuer', () {
      final context = AnalyzerContext.fromText('''
Größe/Anzahl 1 SP x 8 MM = 8 SMM à 3,20 EUR 25,60
25,60
MwSt 19%: 4,86
Rechnungsendbetrag: 30,46
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '30,46 €');
    });

    test('SÜWE: erkennt Rechnungsendbetrag in der Folgezeile', () {
      final context = AnalyzerContext.fromText('''
MwSt 19%: 4,86
Rechnungsendbetrag:
30,46
''');

      final result = GrossAmountAnalyzer.analyze(context);

      expect(result.value, '30,46 €');
    });
  });
}
