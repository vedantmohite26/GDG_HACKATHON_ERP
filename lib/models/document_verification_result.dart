class DocumentVerificationResult {
  final bool isValid;
  final int confidence; // 0-100
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  final String? reason;

  DocumentVerificationResult({
    required this.isValid,
    required this.confidence,
    this.warnings = const [],
    this.metadata = const {},
    this.reason,
  });

  bool get hasWarnings => warnings.isNotEmpty;

  bool get isSuspicious => confidence < 70;

  String get statusText {
    if (!isValid) return 'Invalid';
    if (confidence >= 90) return 'Verified';
    if (confidence >= 70) return 'Acceptable';
    return 'Suspicious';
  }

  factory DocumentVerificationResult.valid({
    int confidence = 100,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentVerificationResult(
      isValid: true,
      confidence: confidence,
      warnings: warnings ?? [],
      metadata: metadata ?? {},
    );
  }

  factory DocumentVerificationResult.invalid({
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentVerificationResult(
      isValid: false,
      confidence: 0,
      reason: reason,
      metadata: metadata ?? {},
    );
  }

  factory DocumentVerificationResult.suspicious({
    required List<String> warnings,
    int confidence = 50,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentVerificationResult(
      isValid: true,
      confidence: confidence,
      warnings: warnings,
      metadata: metadata ?? {},
    );
  }
}
