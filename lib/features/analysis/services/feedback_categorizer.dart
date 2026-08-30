import '../models/category_feedback.dart';
import '../models/resume_analysis_report.dart';

/// Helper utility that categorizes analysis report scores and suggestions
/// into Formatting, Content Quality, and Keywords feedback categories.
class FeedbackCategorizer {
  /// Generates the 3 standard feedback categories from a [ResumeAnalysisReport].
  static List<CategoryFeedback> categorize(ResumeAnalysisReport report) {
    return [
      _buildFormattingFeedback(report),
      _buildContentQualityFeedback(report),
      _buildKeywordsFeedback(report),
    ];
  }

  static CategoryFeedback _buildFormattingFeedback(ResumeAnalysisReport report) {
    final contactScore = report.categoryScores['contactInfo'] ?? 0;
    final additionalScore = report.categoryScores['additional'] ?? 0;
    final educationScore = report.categoryScores['education'] ?? 0;

    final avgScore = ((contactScore + additionalScore + educationScore) / 3).round();

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if (contactScore >= 80) {
      strengths.add('Header contains complete essential identification details.');
    }
    if (educationScore >= 80) {
      strengths.add('Educational background is well-structured and clearly positioned.');
    }
    if (additionalScore >= 60) {
      strengths.add('Additional credential sections support overall profile depth.');
    }

    for (final suggestion in report.suggestions) {
      final lower = suggestion.toLowerCase();
      if (lower.contains('email') ||
          lower.contains('phone') ||
          lower.contains('location') ||
          lower.contains('link') ||
          lower.contains('linkedin') ||
          lower.contains('website') ||
          lower.contains('format') ||
          lower.contains('education') ||
          lower.contains('section') ||
          lower.contains('projects') ||
          lower.contains('certifications') ||
          lower.contains('languages')) {
        weaknesses.add(suggestion);
        recommendations.add(suggestion);
      }
    }

    return CategoryFeedback(
      title: 'Formatting',
      score: avgScore,
      status: _scoreToStatus(avgScore),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  static CategoryFeedback _buildContentQualityFeedback(ResumeAnalysisReport report) {
    final summaryScore = report.categoryScores['professionalSummary'] ?? 0;
    final experienceScore = report.categoryScores['workExperience'] ?? 0;

    final avgScore = ((summaryScore + experienceScore) / 2).round();

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if (summaryScore >= 80) {
      strengths.add('Professional summary provides a concise, impactful career overview.');
    }
    if (experienceScore >= 80) {
      strengths.add('Work experience entries detail specific responsibilities and achievements.');
    }

    for (final suggestion in report.suggestions) {
      final lower = suggestion.toLowerCase();
      if (lower.contains('summary') ||
          lower.contains('experience') ||
          lower.contains('description') ||
          lower.contains('verb') ||
          lower.contains('quantif') ||
          lower.contains('metric') ||
          lower.contains('career progression') ||
          lower.contains('character') ||
          lower.contains('detail')) {
        weaknesses.add(suggestion);
        recommendations.add(suggestion);
      }
    }

    return CategoryFeedback(
      title: 'Content Quality',
      score: avgScore,
      status: _scoreToStatus(avgScore),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  static CategoryFeedback _buildKeywordsFeedback(ResumeAnalysisReport report) {
    final skillsScore = report.categoryScores['skills'] ?? 0;

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if (skillsScore >= 80) {
      strengths.add('Rich keyword density with robust technical and domain skill coverage.');
    } else if (skillsScore >= 50) {
      strengths.add('Foundational skills indexed for primary role alignment.');
    }

    for (final suggestion in report.suggestions) {
      final lower = suggestion.toLowerCase();
      if (lower.contains('skill') ||
          lower.contains('keyword') ||
          lower.contains('matching') ||
          lower.contains('rank') ||
          lower.contains('ats keyword')) {
        weaknesses.add(suggestion);
        recommendations.add(suggestion);
      }
    }

    return CategoryFeedback(
      title: 'Keywords',
      score: skillsScore,
      status: _scoreToStatus(skillsScore),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  static String _scoreToStatus(int score) {
    if (score >= 80) return 'Strong';
    if (score >= 60) return 'Moderate';
    return 'Needs Work';
  }
}
