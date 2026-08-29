import 'package:uuid/uuid.dart';

/// Severity / priority level of an analysis suggestion.
enum SuggestionPriority {
  high,
  medium,
  low,
}

/// An actionable feedback item derived from resume analysis.
class AnalysisSuggestion {
  final String id;
  final String text;
  final String? section;
  final SuggestionPriority priority;

  AnalysisSuggestion({
    String? id,
    required this.text,
    this.section,
    this.priority = SuggestionPriority.medium,
  }) : id = id ?? const Uuid().v4();

  AnalysisSuggestion copyWith({
    String? text,
    String? section,
    SuggestionPriority? priority,
  }) {
    return AnalysisSuggestion(
      id: id,
      text: text ?? this.text,
      section: section ?? this.section,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'section': section,
        'priority': priority.name,
      };

  factory AnalysisSuggestion.fromMap(Map<String, dynamic> map) =>
      AnalysisSuggestion(
        id: map['id'],
        text: map['text'] ?? '',
        section: map['section'],
        priority: SuggestionPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => SuggestionPriority.medium,
        ),
      );
}

/// Evaluation score and qualitative grade for a specific resume section.
class SectionGrade {
  final String sectionName;
  final double score; // 0 to 100
  final String grade; // e.g. 'A+', 'B', 'C', 'Needs Work'
  final String feedback;

  const SectionGrade({
    required this.sectionName,
    required this.score,
    required this.grade,
    this.feedback = '',
  });

  SectionGrade copyWith({
    String? sectionName,
    double? score,
    String? grade,
    String? feedback,
  }) {
    return SectionGrade(
      sectionName: sectionName ?? this.sectionName,
      score: score ?? this.score,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toMap() => {
        'sectionName': sectionName,
        'score': score,
        'grade': grade,
        'feedback': feedback,
      };

  factory SectionGrade.fromMap(Map<String, dynamic> map) => SectionGrade(
        sectionName: map['sectionName'] ?? '',
        score: (map['score'] as num?)?.toDouble() ?? 0.0,
        grade: map['grade'] ?? 'N/A',
        feedback: map['feedback'] ?? '',
      );
}

/// Complete ATS and structure analysis report for a resume.
class ResumeAnalysisReport {
  final String id;
  final String resumeId;
  final double overallScore; // 0 to 100
  final String summary;
  final List<SectionGrade> sectionGrades;
  final List<AnalysisSuggestion> suggestions;
  final DateTime createdAt;

  ResumeAnalysisReport({
    String? id,
    required this.resumeId,
    required this.overallScore,
    this.summary = '',
    this.sectionGrades = const [],
    this.suggestions = const [],
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ResumeAnalysisReport copyWith({
    String? resumeId,
    double? overallScore,
    String? summary,
    List<SectionGrade>? sectionGrades,
    List<AnalysisSuggestion>? suggestions,
    DateTime? createdAt,
  }) {
    return ResumeAnalysisReport(
      id: id,
      resumeId: resumeId ?? this.resumeId,
      overallScore: overallScore ?? this.overallScore,
      summary: summary ?? this.summary,
      sectionGrades: sectionGrades ?? this.sectionGrades,
      suggestions: suggestions ?? this.suggestions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'resumeId': resumeId,
        'overallScore': overallScore,
        'summary': summary,
        'sectionGrades': sectionGrades.map((g) => g.toMap()).toList(),
        'suggestions': suggestions.map((s) => s.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ResumeAnalysisReport.fromMap(Map<String, dynamic> map) =>
      ResumeAnalysisReport(
        id: map['id'],
        resumeId: map['resumeId'] ?? '',
        overallScore: (map['overallScore'] as num?)?.toDouble() ?? 0.0,
        summary: map['summary'] ?? '',
        sectionGrades: map['sectionGrades'] != null
            ? (map['sectionGrades'] as List)
                .map((g) => SectionGrade.fromMap(Map<String, dynamic>.from(g)))
                .toList()
            : [],
        suggestions: map['suggestions'] != null
            ? (map['suggestions'] as List)
                .map((s) =>
                    AnalysisSuggestion.fromMap(Map<String, dynamic>.from(s)))
                .toList()
            : [],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}
