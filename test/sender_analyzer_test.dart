
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/analyzer_context.dart';
import 'package:smart_folder/services/sender_analyzer.dart';

void main() {
  group('SenderAnalyzer', () {
    test('erkennt einen Firmennamen mit GmbH', () {
      final context = AnalyzerContext.fromText('''
Musterfirma GmbH
Musterstraße 12
12345 Musterstadt
Rechnung Nr. 12345
''');

      final result = SenderAnalyzer.analyze(context);

      expect(result.value, 'Musterfirma GmbH');
    });

    test('erkennt eine vollständige GmbH & Co. KG', () {
      final context = AnalyzerContext.fromText('''
SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG
Pariser Str. 16
67655 Kaiserslautern
''');

      final result = SenderAnalyzer.analyze(context);

      expect(
        result.value,
        'SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG',
      );
    });

    test('verwendet nicht das Stichwort als Absender', () {
      final context = AnalyzerContext.fromText('''
Auftrag/Position
11205263-020
Rubrik
Brennholz/Kaminholz
Stichwort
Brennstoffhandel
Rechnungsendbetrag:
30,46
Brennstoffhandel Seitz
Christian Seitz
Hauptstr. 6
67808 Weitersweiler
ANZEIGENRECHNUNG
SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG
Pariser Str. 16
67655 Kaiserslautern
''');

      final result = SenderAnalyzer.analyze(context);

      expect(
        result.value,
        'SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG',
      );
    });

    test('liefert keinen Rechnungsendbetrag als Absender', () {
      final context = AnalyzerContext.fromText('''
Rechnungsendbetrag:
30,46
MwSt 19%:
4,86
''');

      final result = SenderAnalyzer.analyze(context);

      expect(result.value, isNot('Rechnungsendbetrag'));
    });

    test('liefert einen leeren Wert bei unbekanntem Dokument', () {
      final context = AnalyzerContext.fromText('''
Dokument
Allgemeine Informationen
Keine Firmenangaben vorhanden
''');

      final result = SenderAnalyzer.analyze(context);

      expect(result.value, isEmpty);
    });
  });
}
