import '../models/resume_analysis_report.dart';

/// Represents the aggregated dashboard statistics for the analysis feature.
class AnalysisDashboardStats {
  /// The total number of resumes.
  final int totalResumes;

  /// The average ATS score across all resumes, bounded between 0.0 and 100.0.
  final double averageAtsScore;

  /// Recent activity logs represented as latest analysis reports.
  final List<ResumeAnalysisReport> recentActivity;

  AnalysisDashboardStats({
    this.totalResumes = 0,
    this.averageAtsScore = 0.0,
    this.recentActivity = const [],
  }) : assert(averageAtsScore >= 0.0 && averageAtsScore <= 100.0,
            'Average ATS score must be between 0 and 100');

  /// Creates a copy of this statistics model with the given fields replaced.
  AnalysisDashboardStats copyWith({
    int? totalResumes,
    double? averageAtsScore,
    List<ResumeAnalysisReport>? recentActivity,
  }) {
    return AnalysisDashboardStats(
      totalResumes: totalResumes ?? this.totalResumes,
      averageAtsScore: averageAtsScore ?? this.averageAtsScore,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  /// Converts this stats object to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'totalResumes': totalResumes,
      'averageAtsScore': averageAtsScore,
      'recentActivity': recentActivity.map((r) => r.toMap()).toList(),
    };
  }

  /// Creates a stats object from a map representation.
  factory AnalysisDashboardStats.fromMap(Map<String, dynamic> map) {
    return AnalysisDashboardStats(
      totalResumes: map['totalResumes'] as int? ?? 0,
      averageAtsScore: (map['averageAtsScore'] as num? ?? 0.0).toDouble(),
      recentActivity: map['recentActivity'] != null
          ? (map['recentActivity'] as List)
              .map((r) => ResumeAnalysisReport.fromMap(Map<String, dynamic>.from(r)))
              .toList()
          : const [],
    );
  }
}
