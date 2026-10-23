import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/services/document_analyzer.dart';

void main() {
  group('SmartFolder Rechnungs-Regressionstests', () {
    test('SÜWE: erkennt Absender, Rechnungsnummer, Datum und Endbetrag', () {
      final result = DocumentAnalyzer.analyze('''
SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG
Pariser Str. 16 · 67655 Kaiserslautern
Brennstoffhandel Seitz
Rechnungs-Nr. 6032837838
Kunden-Nr. 21371193
Rechnungsdatum 16.10.2026
ANZEIGENRECHNUNG
25,60
MwSt 19%: 4,86
Rechnungsendbetrag: 30,46
''');

      expect(
        result.sender,
        'SÜWE Vertriebs- und Dienstleistungsgesellschaft mbH & Co. KG',
      );
      expect(result.invoiceNumber, '6032837838');
      expect(result.date, '16.10.2026');
      expect(result.amount, '30,46 €');
    });

    test('Agricola: erkennt Nummer, Datum, Netto, Steuer und Brutto', () {
      final result = DocumentAnalyzer.analyze('''
Agricola Consultants GmbH
Olschnoegg 1, 9341 Strassburg, Austria
SEITZ BRENNSTOFFHANDEL
Datum: 14.10.2026
Rechnungs-Nr.: 2026100063
Kunden-Nr.: 22750
Rechnung
Summe 9.853,20 €
Mehrwertsteuer 7% auf 9.853,20 € netto 689,72 €
Gesamtbetrag 10.542,92 €
''');

      expect(result.sender, 'Agricola Consultants GmbH');
      expect(result.invoiceNumber, '2026100063');
      expect(result.date, '14.10.2026');
      expect(result.netAmount, '9.853,20 €');
      expect(result.taxAmount, '689,72 €');
      expect(result.amount, '10.542,92 €');
    });

    test('ZOLL-frei: erkennt Belegnummer und Gesamtbetrag', () {
      final result = DocumentAnalyzer.analyze('''
ZOLL-frei GmbH & Co. KG· Karl-Lösch-Str. 3 · 67360 Lingenfeld
Brennstoffhandel Seitz Christian
Belegnummer: 033937
Belegdatum: 16.10.2026
Rechnung
Steuerfrei (D) 560,28 EUR
*: Steuerpflichtig (19%) 130,51 EUR
19% MwSt. von 130,51 24,80 EUR
Gesamtbetrag 715,59 EUR
''');

      expect(result.sender, 'ZOLL-frei GmbH & Co. KG');
      expect(result.invoiceNumber, '033937');
      expect(result.date, '16.10.2026');
      expect(result.amount, '715,59 €');
    });
  });
}
