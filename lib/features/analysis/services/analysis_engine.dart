import '../../../data/models/resume_models.dart';
import '../models/resume_analysis_report.dart';

/// Contract/interface defining the operations for resume ATS analysis.
abstract class AnalysisEngine {
  /// Analyzes a [Resume] and generates a [ResumeAnalysisReport].
  Future<ResumeAnalysisReport> analyze(Resume resume);
}

/// A deterministic mock implementation of [AnalysisEngine] for testing
/// and offline ATS score calculations.
class MockAnalysisEngine implements AnalysisEngine {
  @override
  Future<ResumeAnalysisReport> analyze(Resume resume) async {
    // Simulate minor processing latency (similar to parsing/local checks)
    await Future.delayed(const Duration(milliseconds: 100));

    final suggestions = <String>[];
    
    // 1. Contact Info Section (Max 20)
    int contactScore = 0;
    if (resume.personalInfo.email.trim().isNotEmpty) {
      contactScore += 5;
    } else {
      suggestions.add('Add your email address so recruiters can contact you.');
    }

    if (resume.personalInfo.phone.trim().isNotEmpty) {
      contactScore += 5;
    } else {
      suggestions.add('Include a phone number for direct contact.');
    }

    if (resume.personalInfo.location.trim().isNotEmpty) {
      contactScore += 5;
    } else {
      suggestions.add('Include your location (city and state/country) to show local/relocation availability.');
    }

    final hasWebsite = resume.personalInfo.website.trim().isNotEmpty;
    final hasSocials = resume.socialLinks.isNotEmpty;
    if (hasWebsite || hasSocials) {
      contactScore += 5;
    } else {
      suggestions.add('Consider adding links to your LinkedIn profile, GitHub, or personal website.');
    }

    // 2. Professional Summary Section (Max 10)
    int summaryScore = 0;
    final summaryText = resume.summary.summaryText.trim();
    if (summaryText.isNotEmpty) {
      summaryScore += 5;
      if (summaryText.length > 50) {
        summaryScore += 5;
      } else {
        suggestions.add('Expand your professional summary to at least 50 characters to better describe your background.');
      }
    } else {
      suggestions.add('Create a professional summary to quickly highlight your value proposition.');
    }

    // 3. Work Experience Section (Max 25)
    int experienceScore = 0;
    if (resume.experiences.isNotEmpty) {
      experienceScore += 10;
      if (resume.experiences.length >= 2) {
        experienceScore += 10;
      } else {
        suggestions.add('Add more of your professional history to demonstrate career progression.');
      }

      final hasDetailedDesc = resume.experiences.any((e) => e.description.trim().length > 100);
      if (hasDetailedDesc) {
        experienceScore += 5;
      } else {
        suggestions.add('Add more detail to your work experience descriptions (aim for >100 characters in descriptions, using action verbs and quantifying achievements).');
      }
    } else {
      suggestions.add('Add your work experiences to detail your career history.');
    }

    // 4. Skills Section (Max 15)
    int skillsScore = 0;
    final skillCount = resume.skills.length;
    if (skillCount > 0) {
      if (skillCount >= 8) {
        skillsScore += 15;
      } else if (skillCount >= 4) {
        skillsScore += 10;
        suggestions.add('Add more relevant skills to ensure you cover primary keywords for your target role.');
      } else {
        skillsScore += 5;
        suggestions.add('Expand your skills section (aim for 8+ skills) to rank better in ATS keyword matching.');
      }
    } else {
      suggestions.add('Include a list of key skills relevant to your target jobs.');
    }

    // 5. Education Section (Max 15)
    int educationScore = 0;
    if (resume.educationList.isNotEmpty) {
      educationScore += 15;
    } else {
      suggestions.add('Add your educational background to the resume.');
    }

    // 6. Other/Additional Sections: Projects, Certifications, Languages (Max 15)
    int otherScore = 0;
    if (resume.projects.isNotEmpty) {
      otherScore += 5;
    } else {
      suggestions.add('Include projects to demonstrate hands-on experience and application of your skills.');
    }

    if (resume.certifications.isNotEmpty) {
      otherScore += 5;
    } else {
      suggestions.add('List any relevant professional certifications to strengthen your credentials.');
    }

    if (resume.languages.isNotEmpty) {
      otherScore += 5;
    } else {
      suggestions.add('Add languages you speak, indicating your proficiency level.');
    }

    final overallScore = contactScore +
        summaryScore +
        experienceScore +
        skillsScore +
        educationScore +
        otherScore;

    // Construct normalized category scores (0-100)
    final categoryScores = {
      'contactInfo': ((contactScore / 20) * 100).round(),
      'professionalSummary': ((summaryScore / 10) * 100).round(),
      'workExperience': ((experienceScore / 25) * 100).round(),
      'skills': ((skillsScore / 15) * 100).round(),
      'education': ((educationScore / 15) * 100).round(),
      'additional': ((otherScore / 15) * 100).round(),
    };

    return ResumeAnalysisReport(
      resumeId: resume.id,
      overallScore: overallScore,
      categoryScores: categoryScores,
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }
}
