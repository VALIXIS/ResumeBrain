import 'package:flutter/foundation.dart';
import '../services/salary_analyzer_service.dart';
import '../services/seniority_analyzer_service.dart';

class KeywordExtractionResult {
  final List<String> extractedJdSkills;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final double overlapPercentage;
  final Map<String, double> tfidfScores;
  final Map<String, String> semanticMatches;
  final SalaryAnalysisResult salaryAnalysis;
  final SeniorityAnalysisResult seniorityAnalysis;

  const KeywordExtractionResult({
    required this.extractedJdSkills,
    required this.matchedSkills,
    required this.missingSkills,
    required this.overlapPercentage,
    this.tfidfScores = const {},
    this.semanticMatches = const {},
    this.salaryAnalysis = const SalaryAnalysisResult(hasSalary: false),
    this.seniorityAnalysis = const SeniorityAnalysisResult(
      detectedJdSeniority: 'Unknown',
      estimatedResumeSeniority: 'Unknown',
      candidateYearsOfExperience: 0,
      alignmentStatus: 'Unknown',
    ),
  });

  factory KeywordExtractionResult.empty() {
    return KeywordExtractionResult(
      extractedJdSkills: const [],
      matchedSkills: const [],
      missingSkills: const [],
      overlapPercentage: 0.0,
      tfidfScores: const {},
      semanticMatches: const {},
      salaryAnalysis: SalaryAnalysisResult.empty(),
      seniorityAnalysis: SeniorityAnalysisResult.unknown(),
    );
  }

  Map<String, dynamic> toMap() => {
        'extractedJdSkills': extractedJdSkills,
        'matchedSkills': matchedSkills,
        'missingSkills': missingSkills,
        'overlapPercentage': overlapPercentage,
        'tfidfScores': tfidfScores,
        'semanticMatches': semanticMatches,
        'salaryAnalysis': salaryAnalysis.toMap(),
        'seniorityAnalysis': seniorityAnalysis.toMap(),
      };

  factory KeywordExtractionResult.fromMap(Map<String, dynamic> map) =>
      KeywordExtractionResult(
        extractedJdSkills: List<String>.from(map['extractedJdSkills'] ?? []),
        matchedSkills: List<String>.from(map['matchedSkills'] ?? []),
        missingSkills: List<String>.from(map['missingSkills'] ?? []),
        overlapPercentage:
            (map['overlapPercentage'] as num?)?.toDouble() ?? 0.0,
        tfidfScores: Map<String, double>.from(
          (map['tfidfScores'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ) ??
              {},
        ),
        semanticMatches: Map<String, String>.from(
          (map['semanticMatches'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ) ??
              {},
        ),
        salaryAnalysis: map['salaryAnalysis'] != null
            ? SalaryAnalysisResult.fromMap(map['salaryAnalysis'])
            : SalaryAnalysisResult.empty(),
        seniorityAnalysis: map['seniorityAnalysis'] != null
            ? SeniorityAnalysisResult.fromMap(map['seniorityAnalysis'])
            : SeniorityAnalysisResult.unknown(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordExtractionResult &&
          runtimeType == other.runtimeType &&
          listEquals(extractedJdSkills, other.extractedJdSkills) &&
          listEquals(matchedSkills, other.matchedSkills) &&
          listEquals(missingSkills, other.missingSkills) &&
          overlapPercentage == other.overlapPercentage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(extractedJdSkills),
        Object.hashAll(matchedSkills),
        Object.hashAll(missingSkills),
        overlapPercentage,
      );

  @override
  String toString() {
    return 'KeywordExtractionResult(extractedJdSkills: $extractedJdSkills, matchedSkills: $matchedSkills, missingSkills: $missingSkills, overlapPercentage: $overlapPercentage%)';
  }
}
