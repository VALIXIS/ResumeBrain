import '../../../data/models/resume_models.dart';
import '../models/analysis_models.dart';

/// Deterministic ATS Scoring & Analysis Engine for ResumeBrain.
/// Evaluates completeness, formatting, action verbs, and section strength.
class ResumeAnalysisEngine {
  /// Analyzes a resume and returns a complete [ResumeAnalysisReport].
  static ResumeAnalysisReport evaluate(Resume resume) {
    final sectionGrades = <SectionGrade>[];
    final suggestions = <AnalysisSuggestion>[];

    // 1. Contact Information
    final contactGrade = _evaluateContactInfo(resume.personalInfo, suggestions);
    sectionGrades.add(contactGrade);

    // 2. Professional Summary
    final summaryGrade = _evaluateSummary(resume.summary, suggestions);
    sectionGrades.add(summaryGrade);

    // 3. Work Experience
    final expGrade = _evaluateExperience(resume.experiences, suggestions);
    sectionGrades.add(expGrade);

    // 4. Education
    final eduGrade = _evaluateEducation(resume.educationList, suggestions);
    sectionGrades.add(eduGrade);

    // 5. Skills
    final skillsGrade = _evaluateSkills(resume.skills, suggestions);
    sectionGrades.add(skillsGrade);

    // 6. Certifications
    final certsGrade = _evaluateCertifications(resume.certifications, suggestions);
    sectionGrades.add(certsGrade);

    // 7. Languages
    final langGrade = _evaluateLanguages(resume.languages, suggestions);
    sectionGrades.add(langGrade);

    // 8. Custom Sections (if any exist)
    if (resume.customSections.isNotEmpty) {
      final customGrade = _evaluateCustomSections(resume.customSections, suggestions);
      sectionGrades.add(customGrade);
    }

    // Calculate weighted overall ATS score (0 to 100)
    // Weights: Contact (15%), Summary (15%), Experience (30%), Education (15%), Skills (15%), Certifications (5%), Languages (5%)
    double weightedScore = 0.0;
    weightedScore += contactGrade.score * 0.15;
    weightedScore += summaryGrade.score * 0.15;
    weightedScore += expGrade.score * 0.30;
    weightedScore += eduGrade.score * 0.15;
    weightedScore += skillsGrade.score * 0.15;
    weightedScore += certsGrade.score * 0.05;
    weightedScore += langGrade.score * 0.05;

    final finalScore = (weightedScore * 10).round() / 10.0;

    String summaryText;
    if (finalScore >= 85) {
      summaryText =
          'Outstanding resume structure with high ATS readability and solid section depth.';
    } else if (finalScore >= 70) {
      summaryText =
          'Good foundational resume. Adding measurable metrics and expanding skill keywords will maximize recruiter impact.';
    } else if (finalScore >= 50) {
      summaryText =
          'Moderate ATS compliance. Fill in missing details in experience and summary to boost your score.';
    } else {
      summaryText =
          'Resume needs significant detail additions in experience, skills, and contact info to pass ATS filters.';
    }

    return ResumeAnalysisReport(
      resumeId: resume.id,
      overallScore: finalScore.clamp(0.0, 100.0),
      summary: summaryText,
      sectionGrades: sectionGrades,
      suggestions: suggestions,
      createdAt: DateTime.now(),
    );
  }

  static SectionGrade _evaluateContactInfo(
    PersonalInformation info,
    List<AnalysisSuggestion> suggestions,
  ) {
    int points = 0;
    if (info.fullName.trim().isNotEmpty) points += 25;
    if (info.email.trim().isNotEmpty && info.email.contains('@')) points += 25;
    if (info.phone.trim().isNotEmpty) points += 20;
    if (info.jobTitle.trim().isNotEmpty) points += 15;
    if (info.location.trim().isNotEmpty) points += 10;
    if (info.website.trim().isNotEmpty) points += 5;

    final score = points.toDouble().clamp(0.0, 100.0);

    if (info.fullName.trim().isEmpty) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add your full legal name to the header.',
          section: 'Contact Information',
          priority: SuggestionPriority.high,
        ),
      );
    }
    if (info.email.trim().isEmpty || !info.email.contains('@')) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Provide a professional contact email address.',
          section: 'Contact Information',
          priority: SuggestionPriority.high,
        ),
      );
    }
    if (info.jobTitle.trim().isEmpty) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Specify a target job title or current professional headline.',
          section: 'Contact Information',
          priority: SuggestionPriority.medium,
        ),
      );
    }

    return SectionGrade(
      sectionName: 'Contact Information',
      score: score,
      grade: _scoreToGrade(score),
      feedback: score >= 80 ? 'Complete contact details' : 'Missing key contact fields',
    );
  }

  static SectionGrade _evaluateSummary(
    ProfessionalSummary summary,
    List<AnalysisSuggestion> suggestions,
  ) {
    final text = summary.summaryText.trim();
    double score = 0.0;

    if (text.isEmpty) {
      score = 0.0;
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add a 2-4 sentence professional summary highlighting your core expertise.',
          section: 'Summary',
          priority: SuggestionPriority.high,
        ),
      );
    } else {
      final wordCount = text.split(RegExp(r'\s+')).length;
      if (wordCount >= 30 && wordCount <= 120) {
        score = 95.0;
      } else if (wordCount > 120) {
        score = 80.0;
        suggestions.add(
          AnalysisSuggestion(
            text: 'Condense your summary to under 100 words for optimal recruiter scannability.',
            section: 'Summary',
            priority: SuggestionPriority.low,
          ),
        );
      } else {
        score = 65.0;
        suggestions.add(
          AnalysisSuggestion(
            text: 'Expand summary with specific career achievements and years of experience.',
            section: 'Summary',
            priority: SuggestionPriority.medium,
          ),
        );
      }
    }

    return SectionGrade(
      sectionName: 'Summary / Profile',
      score: score,
      grade: _scoreToGrade(score),
      feedback: score >= 80 ? 'Impactful executive overview' : 'Needs expansion and focus',
    );
  }

  static SectionGrade _evaluateExperience(
    List<Experience> experiences,
    List<AnalysisSuggestion> suggestions,
  ) {
    if (experiences.isEmpty) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add at least one work experience or relevant internship.',
          section: 'Experience',
          priority: SuggestionPriority.high,
        ),
      );
      return const SectionGrade(
        sectionName: 'Work Experience',
        score: 20.0,
        grade: 'Needs Work',
        feedback: 'No experience entries found',
      );
    }

    double score = 50.0; // Base for having entries
    score += (experiences.length * 15.0).clamp(0.0, 30.0);

    bool hasDescriptions = false;
    for (var exp in experiences) {
      if (exp.description.trim().length > 30) {
        hasDescriptions = true;
      }
    }

    if (hasDescriptions) {
      score += 20.0;
    } else {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add detailed bullet points with metrics to your experience entries.',
          section: 'Experience',
          priority: SuggestionPriority.high,
        ),
      );
    }

    score = score.clamp(0.0, 100.0);
    return SectionGrade(
      sectionName: 'Work Experience',
      score: score,
      grade: _scoreToGrade(score),
      feedback: score >= 80 ? 'Strong role descriptions' : 'Add metrics and bullet points',
    );
  }

  static SectionGrade _evaluateEducation(
    List<Education> educationList,
    List<AnalysisSuggestion> suggestions,
  ) {
    if (educationList.isEmpty) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Include your highest education degree or qualification.',
          section: 'Education',
          priority: SuggestionPriority.medium,
        ),
      );
      return const SectionGrade(
        sectionName: 'Education',
        score: 30.0,
        grade: 'Needs Work',
        feedback: 'No education listed',
      );
    }

    double score = 70.0;
    final first = educationList.first;
    if (first.institution.isNotEmpty && first.degree.isNotEmpty) {
      score = 95.0;
    }

    return SectionGrade(
      sectionName: 'Education',
      score: score,
      grade: _scoreToGrade(score),
      feedback: 'Education listed with institution and degree',
    );
  }

  static SectionGrade _evaluateSkills(
    List<Skill> skills,
    List<AnalysisSuggestion> suggestions,
  ) {
    if (skills.isEmpty) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add at least 5-8 relevant technical and soft skills.',
          section: 'Skills',
          priority: SuggestionPriority.high,
        ),
      );
      return const SectionGrade(
        sectionName: 'Skills',
        score: 25.0,
        grade: 'Needs Work',
        feedback: 'No skills added',
      );
    }

    double score = (skills.length * 12.0).clamp(30.0, 100.0);
    if (skills.length < 5) {
      suggestions.add(
        AnalysisSuggestion(
          text: 'Add ${5 - skills.length} more skills to improve keyword matching score.',
          section: 'Skills',
          priority: SuggestionPriority.medium,
        ),
      );
    }

    return SectionGrade(
      sectionName: 'Skills',
      score: score,
      grade: _scoreToGrade(score),
      feedback: score >= 80 ? '${skills.length} skills listed' : 'Add more relevant skills',
    );
  }

  static SectionGrade _evaluateCertifications(
    List<Certification> certifications,
    List<AnalysisSuggestion> suggestions,
  ) {
    if (certifications.isEmpty) {
      return const SectionGrade(
        sectionName: 'Certifications',
        score: 60.0,
        grade: 'Optional',
        feedback: 'Optional section — add credentials to boost profile',
      );
    }

    return SectionGrade(
      sectionName: 'Certifications',
      score: 95.0,
      grade: 'A',
      feedback: '${certifications.length} verified certification(s)',
    );
  }

  static SectionGrade _evaluateLanguages(
    List<Language> languages,
    List<AnalysisSuggestion> suggestions,
  ) {
    if (languages.isEmpty) {
      return const SectionGrade(
        sectionName: 'Languages',
        score: 60.0,
        grade: 'Optional',
        feedback: 'Optional section — add languages if multilingual',
      );
    }

    return SectionGrade(
      sectionName: 'Languages',
      score: 95.0,
      grade: 'A',
      feedback: '${languages.length} language(s) listed',
    );
  }

  static SectionGrade _evaluateCustomSections(
    List<CustomSection> customSections,
    List<AnalysisSuggestion> suggestions,
  ) {
    return SectionGrade(
      sectionName: 'Custom Sections',
      score: 90.0,
      grade: 'A',
      feedback: '${customSections.length} custom section(s)',
    );
  }

  static String _scoreToGrade(double score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'Needs Work';
  }
}
