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
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
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
