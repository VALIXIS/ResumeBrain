class KeywordExtractionResult {
  final List<String> extractedJdSkills;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final double overlapPercentage;

  const KeywordExtractionResult({
    required this.extractedJdSkills,
    required this.matchedSkills,
    required this.missingSkills,
    required this.overlapPercentage,
  });

  factory KeywordExtractionResult.empty() {
    return const KeywordExtractionResult(
      extractedJdSkills: [],
      matchedSkills: [],
      missingSkills: [],
      overlapPercentage: 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'extractedJdSkills': extractedJdSkills,
        'matchedSkills': matchedSkills,
        'missingSkills': missingSkills,
        'overlapPercentage': overlapPercentage,
      };

  factory KeywordExtractionResult.fromMap(Map<String, dynamic> map) =>
      KeywordExtractionResult(
        extractedJdSkills: List<String>.from(map['extractedJdSkills'] ?? []),
        matchedSkills: List<String>.from(map['matchedSkills'] ?? []),
        missingSkills: List<String>.from(map['missingSkills'] ?? []),
        overlapPercentage:
            (map['overlapPercentage'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordExtractionResult &&
          runtimeType == other.runtimeType &&
          extractedJdSkills.length == other.extractedJdSkills.length &&
          matchedSkills.length == other.matchedSkills.length &&
          missingSkills.length == other.missingSkills.length &&
          overlapPercentage == other.overlapPercentage;

  @override
  int get hashCode =>
      Object.hash(extractedJdSkills, matchedSkills, missingSkills, overlapPercentage);

  @override
  String toString() {
    return 'KeywordExtractionResult(extractedJdSkills: $extractedJdSkills, matchedSkills: $matchedSkills, missingSkills: $missingSkills, overlapPercentage: $overlapPercentage%)';
  }
}
