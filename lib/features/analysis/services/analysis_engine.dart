import '../../../data/models/resume_models.dart';
import '../models/resume_analysis_report.dart';
import 'ats_engine.dart';

/// Contract/interface defining the operations for resume ATS analysis.
abstract class AnalysisEngine {
  /// Analyzes a [Resume] and generates a [ResumeAnalysisReport].
  Future<ResumeAnalysisReport> analyze(Resume resume);
}

/// A deterministic implementation of [AnalysisEngine] using [AtsEngine]
/// for offline, production-grade ATS score calculations.
class MockAnalysisEngine implements AnalysisEngine {
  final AtsEngine _atsEngine;

  MockAnalysisEngine({AtsEngine? atsEngine})
      : _atsEngine = atsEngine ?? AtsEngine();

  @override
  Future<ResumeAnalysisReport> analyze(Resume resume) async {
    // Simulate minor processing latency
    await Future.delayed(const Duration(milliseconds: 50));

    final atsReport = _atsEngine.analyze(resume);

    // 1. Contact Info Section (Max 20)
    int contactScore = 0;
    if (resume.personalInfo.email.trim().isNotEmpty) contactScore += 5;
    if (resume.personalInfo.phone.trim().isNotEmpty) contactScore += 5;
    if (resume.personalInfo.location.trim().isNotEmpty) contactScore += 5;
    if (resume.personalInfo.website.trim().isNotEmpty || resume.socialLinks.isNotEmpty) {
      contactScore += 5;
    }

    // 2. Summary Section (Max 10)
    int summaryScore = 0;
    final summaryText = resume.summary.summaryText.trim();
    if (summaryText.isNotEmpty) {
      summaryScore += 5;
      if (summaryText.length > 50) summaryScore += 5;
    }

    // 3. Work Experience Section (Max 25)
    int experienceScore = 0;
    if (resume.experiences.isNotEmpty) {
      experienceScore += 10;
      if (resume.experiences.length >= 2) experienceScore += 10;
      if (resume.experiences.any((e) => e.description.trim().length > 100)) {
        experienceScore += 5;
      }
    }

    // 4. Skills Section (Max 15)
    int skillsScore = 0;
    final skillCount = resume.skills.length;
    if (skillCount > 0) {
      if (skillCount >= 8) {
        skillsScore += 15;
      } else if (skillCount >= 4) {
        skillsScore += 10;
      } else {
        skillsScore += 5;
      }
    }

    // 5. Education Section (Max 15)
    int educationScore = 0;
    if (resume.educationList.isNotEmpty) educationScore += 15;

    // 6. Other/Additional Section (Max 15)
    int otherScore = 0;
    if (resume.projects.isNotEmpty) otherScore += 5;
    if (resume.certifications.isNotEmpty) otherScore += 5;
    if (resume.languages.isNotEmpty) otherScore += 5;

    final overallScore = contactScore +
        summaryScore +
        experienceScore +
        skillsScore +
        educationScore +
        otherScore;

    final categoryScores = <String, int>{
      // Four core ATS dimensions for Radar Chart & RSM-03
      AtsDimension.impactVerbs.key: atsReport.impactVerbsScore,
      AtsDimension.formatting.key: atsReport.formattingScore,
      AtsDimension.contactCompleteness.key: atsReport.contactCompletenessScore,
      AtsDimension.keywordDensity.key: atsReport.keywordDensityScore,

      // Section breakdown category scores
      'contactInfo': ((contactScore / 20) * 100).round(),
      'professionalSummary': ((summaryScore / 10) * 100).round(),
      'workExperience': ((experienceScore / 25) * 100).round(),
      'skills': ((skillsScore / 15) * 100).round(),
      'education': ((educationScore / 15) * 100).round(),
      'additional': ((otherScore / 15) * 100).round(),
    };

    final suggestions = atsReport.recommendations.map((r) => r.description).toList();

    return ResumeAnalysisReport(
      resumeId: resume.id,
      overallScore: overallScore.clamp(0, 100),
      categoryScores: categoryScores,
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }

  /// Direct access to full [AtsScoreReport] for ATS radar and recommendations.
  AtsScoreReport analyzeAts(Resume resume) {
    return _atsEngine.analyze(resume);
  }
}
