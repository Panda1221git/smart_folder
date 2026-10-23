
class AnalyzerContext {
  final String rawText;
  final String normalizedText;
  final List<String> lines;

  const AnalyzerContext({
    required this.rawText,
    required this.normalizedText,
    required this.lines,
  });

  static AnalyzerContext fromText(String text) {
    var normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Fehlende Trennzeichen vor bekannten Rechnungsfeldern ergänzen.
    // Beispiel: "DE441621658Datum:14.10.2026"
    // wird zu:   "DE441621658\nDatum:14.10.2026"
    const fieldLabels = [
      'Rechnungs-Nr.',
      'Rechnungsnummer',
      'Rechnungs-Nr',
      'Rechnungsdatum',
      'Belegnummer',
      'Beleg-Nr.',
      'Belegdatum',
      'Kundennummer',
      'Kunden-Nr.',
      'Sachbearbeiter/-in',
      'Sachbearbeiter',
      'Ihre UID-Nr.',
      'Ihre USt-ID',
      'Rechnungsendbetrag',
      'Gesamtbetrag',
      'Mehrwertsteuer',
      'Nettobetrag',
      'Bruttobetrag',
      'Datum',
    ];

    for (final label in fieldLabels) {
      final escapedLabel = RegExp.escape(label);

      // Trennt ein Feldlabel vom unmittelbar davor stehenden Inhalt,
      // sofern es nicht bereits am Zeilenanfang steht.
      normalized = normalized.replaceAllMapped(
        RegExp(
          '([^\\n])($escapedLabel)(\\s*[:#])',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}\n${match.group(2)}${match.group(3)}',
      );
    }

    // Bei Feldlabel und Wert in derselben Zeile den Doppelpunkt
    // als Feldtrenner beibehalten; die Spezial-Analyzer lesen beides.
    normalized = normalized
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return AnalyzerContext(
      rawText: text,
      normalizedText: normalized,
      lines: lines,
    );
  }
}
