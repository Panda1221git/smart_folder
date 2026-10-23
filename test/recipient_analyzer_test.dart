import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/analyzer_context.dart';
import 'package:smart_folder/services/recipient_analyzer.dart';

void main() {
  group('RecipientAnalyzer', () {
    test('erkennt einen Empfänger mit einer eindeutigen Beschriftung', () {
      final context = AnalyzerContext.fromText('''
Rechnungsempfänger:
Muster & Partner
Hauptstraße 12
12345 Musterstadt
''');

      final result = RecipientAnalyzer.analyze(context, 'Lieferant GmbH');

      expect(result.value, 'Muster & Partner');
      expect(result.confidence, greaterThan(0));
    });

    test('ist nicht auf den bisherigen Testbetrieb zugeschnitten', () {
      final context = AnalyzerContext.fromText('''
Rechnung an:
Beispieltechnik GmbH
Werkstraße 5
12345 Beispielstadt
''');

      final result = RecipientAnalyzer.analyze(context, 'Lieferant GmbH');

      expect(result.value, 'Beispieltechnik GmbH');
    });

    test('liefert keinen Empfänger, wenn keine Beschriftung vorhanden ist', () {
      final context = AnalyzerContext.fromText('''
Lieferant GmbH
Rechnungsnummer: RG-12345
Gesamtbetrag: 99,00 EUR
''');

      final result = RecipientAnalyzer.analyze(context, 'Lieferant GmbH');

      expect(result.value, isEmpty);
    });
  });
}
