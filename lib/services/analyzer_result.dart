class AnalyzerResult {
  final String value;
  final double confidence;
  final String evidence;
  final String source;

  const AnalyzerResult({
    required this.value,
    required this.confidence,
    required this.evidence,
    required this.source,
  });

  bool get hasValue => value.trim().isNotEmpty;
}
