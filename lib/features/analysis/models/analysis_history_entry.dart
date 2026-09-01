import 'resume_analysis_report.dart';

/// Represents a single historical analysis snapshot for a specific resume.
class AnalysisHistoryEntry {
  final String id;
  final String resumeId;
  final int overallScore;
  final Map<String, int> categoryScores;
  final List<String> suggestions;
  final DateTime timestamp;

  const AnalysisHistoryEntry({
    required this.id,
    required this.resumeId,
    required this.overallScore,
    required this.categoryScores,
    this.suggestions = const [],
    required this.timestamp,
  });

  /// Creates a historical entry from a [ResumeAnalysisReport].
  factory AnalysisHistoryEntry.fromReport(ResumeAnalysisReport report, {String? entryId}) {
    return AnalysisHistoryEntry(
      id: entryId ?? '${report.resumeId}_${report.timestamp.millisecondsSinceEpoch}',
      resumeId: report.resumeId,
      overallScore: report.overallScore,
      categoryScores: Map<String, int>.from(report.categoryScores),
      suggestions: List<String>.from(report.suggestions),
      timestamp: report.timestamp,
    );
  }

  /// Converts this entry to a [ResumeAnalysisReport].
  ResumeAnalysisReport toReport() {
    return ResumeAnalysisReport(
      resumeId: resumeId,
      overallScore: overallScore,
      categoryScores: categoryScores,
      suggestions: suggestions,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'resumeId': resumeId,
        'overallScore': overallScore,
        'categoryScores': categoryScores,
        'suggestions': suggestions,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AnalysisHistoryEntry.fromMap(Map<String, dynamic> map) =>
      AnalysisHistoryEntry(
        id: map['id'] ?? '',
        resumeId: map['resumeId'] ?? '',
        overallScore: map['overallScore'] as int? ?? 0,
        categoryScores: Map<String, int>.from(
          (map['categoryScores'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ) ??
              {},
        ),
        suggestions: List<String>.from(map['suggestions'] ?? []),
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}
