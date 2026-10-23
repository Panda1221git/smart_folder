
import 'analyzer_context.dart';
import 'analyzer_result.dart';

class DateAnalyzer {
  static final RegExp _germanDate =
      RegExp(r'\d{1,2}\.\d{1,2}\.\d{2,4}');

  static final RegExp _isoDate =
      RegExp(r'\d{4}-\d{2}-\d{2}');

  static final RegExp _dateValue = RegExp(
    r'(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
  );

  static final List<RegExp> _preferredPatterns = [
    RegExp(
      r'\b(?:rechnungs[\s-]*datum|rechnung[\s-]*datum)\s*[:#]?\s*'
      r'(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:ausstellungsdatum|ausgestellt\s+am|belegdatum)\s*[:#]?\s*'
      r'(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
    ),
    RegExp(
      r'\brechnung\s+vom\s+'
      r'(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
    ),
  ];

  static final RegExp _genericDatePattern = RegExp(
    r'\bdatum\s*[:#]?\s*(\d{1,2}\.\d{1,2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
    caseSensitive: false,
  );

  static const List<String> _excludedLabels = [
    'lieferdatum',
    'liefertermin',
    'lieferzeitpunkt',
    'leistungsdatum',
    'leistungszeitraum',
    'faelligkeitsdatum',
    'fälligkeitsdatum',
    'zahlungsziel',
    'eingangsdatum',
    'bestelldatum',
    'versanddatum',
    'abholdatum',
  ];

  static AnalyzerResult analyze(AnalyzerContext context) {
    final lines = context.lines;

    // Pass 1: Explizite Rechnungs- und Ausstellungsdaten.
    for (var patternIndex = 0;
        patternIndex < _preferredPatterns.length;
        patternIndex++) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        if (_hasExcludedLabel(line)) continue;

        final match = _preferredPatterns[patternIndex].firstMatch(line);
        if (match != null) {
          final value = match.group(1) ?? '';
          if (_isValidDate(value)) {
            return AnalyzerResult(
              value: value,
              confidence: patternIndex == 0 ? 0.99 : 0.96,
              evidence: line,
              source: 'DateAnalyzer',
            );
          }
        }

        // Feldbezeichnung und Datum können auf getrennten Zeilen stehen.
        if (_isDateLabelOnly(line)) {
          for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
            final dateMatch = _dateValue.firstMatch(lines[j]);
            if (dateMatch == null) continue;

            final value = dateMatch.group(1)!;
            if (_isValidDate(value)) {
              return AnalyzerResult(
                value: value,
                confidence: 0.94,
                evidence: '$line → ${lines[j]}',
                source: 'DateAnalyzer',
              );
            }
          }
        }
      }
    }

    // Pass 2: Allgemeines Feld "Datum".
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_hasExcludedLabel(line)) continue;

      final match = _genericDatePattern.firstMatch(line);
      if (match != null) {
        final value = match.group(1) ?? '';
        if (_isValidDate(value)) {
          return AnalyzerResult(
            value: value,
            confidence: 0.85,
            evidence: line,
            source: 'DateAnalyzer',
          );
        }
      }

      if (RegExp(r'^\s*datum\s*[:#]?\s*$',
              caseSensitive: false)
          .hasMatch(line)) {
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final dateMatch = _dateValue.firstMatch(lines[j]);
          if (dateMatch == null) continue;

          final value = dateMatch.group(1)!;
          if (_isValidDate(value)) {
            return AnalyzerResult(
              value: value,
              confidence: 0.85,
              evidence: '$line → ${lines[j]}',
              source: 'DateAnalyzer',
            );
          }
        }
      }
    }

    return const AnalyzerResult(
      value: '',
      confidence: 0.0,
      evidence: '',
      source: 'DateAnalyzer',
    );
  }

  static bool _isDateLabelOnly(String line) {
    return RegExp(
      r'^\s*(?:rechnungs[\s-]*datum|rechnung[\s-]*datum|'
      r'ausstellungsdatum|belegdatum|datum)\s*[:#]?\s*$',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _hasExcludedLabel(String line) {
    final lower = line.toLowerCase();

    return _excludedLabels.any((label) {
      return RegExp(
        '\\b${RegExp.escape(label)}\\b',
        caseSensitive: false,
      ).hasMatch(lower);
    });
  }

  static bool _isValidDate(String value) {
    int year;
    int month;
    int day;

    if (_isoDate.hasMatch(value)) {
      final parts = value.split('-');
      year = int.parse(parts[0]);
      month = int.parse(parts[1]);
      day = int.parse(parts[2]);
    } else {
      final match = RegExp(
        r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4})$',
      ).firstMatch(value);

      if (match == null) return false;

      day = int.parse(match.group(1)!);
      month = int.parse(match.group(2)!);
      year = int.parse(match.group(3)!);

      if (year < 100) year += 2000;
    }

    if (year < 1900 || year > 2200) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    final parsed = DateTime(year, month, day);

    return parsed.year == year &&
        parsed.month == month &&
        parsed.day == day;
  }
}
