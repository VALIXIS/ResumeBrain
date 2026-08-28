import 'dart:convert';

/// Represents the result of an ATS resume analysis.
class ResumeAnalysisReport {
  /// The unique identifier of the resume that was analyzed.
  final String resumeId;

  /// The overall ATS score, between 0 and 100.
  final int overallScore;

  /// Granular scores for individual resume categories/sections.
  final Map<String, int> categoryScores;

  /// Collection of actionable suggestions or feedback for improvement.
  final List<String> suggestions;

  /// The timestamp when the analysis was performed.
  final DateTime timestamp;

  ResumeAnalysisReport({
    required this.resumeId,
    required this.overallScore,
    this.categoryScores = const {},
    this.suggestions = const [],
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        assert(overallScore >= 0 && overallScore <= 100, 'Score must be between 0 and 100');

  /// Creates a copy of this report with the given fields replaced.
  ResumeAnalysisReport copyWith({
    String? resumeId,
    int? overallScore,
    Map<String, int>? categoryScores,
    List<String>? suggestions,
    DateTime? timestamp,
  }) {
    return ResumeAnalysisReport(
      resumeId: resumeId ?? this.resumeId,
      overallScore: overallScore ?? this.overallScore,
      categoryScores: categoryScores ?? this.categoryScores,
      suggestions: suggestions ?? this.suggestions,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this report to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'resumeId': resumeId,
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'suggestions': suggestions,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a report from a map representation.
  factory ResumeAnalysisReport.fromMap(Map<String, dynamic> map) {
    return ResumeAnalysisReport(
      resumeId: map['resumeId'] as String? ?? '',
      overallScore: map['overallScore'] as int? ?? 0,
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
      suggestions: List<String>.from(map['suggestions'] ?? []),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : null,
    );
  }

  /// Converts this report to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a report from a JSON string.
  factory ResumeAnalysisReport.fromJson(String source) =>
      ResumeAnalysisReport.fromMap(json.decode(source) as Map<String, dynamic>);
}
