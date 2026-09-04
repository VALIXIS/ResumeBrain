import '../../../data/models/resume_models.dart';

class SeniorityAnalysisResult {
  final String detectedJdSeniority;
  final int? requiredYearsOfExperience;
  final String estimatedResumeSeniority;
  final int candidateYearsOfExperience;
  final String alignmentStatus;

  const SeniorityAnalysisResult({
    required this.detectedJdSeniority,
    this.requiredYearsOfExperience,
    required this.estimatedResumeSeniority,
    required this.candidateYearsOfExperience,
    required this.alignmentStatus,
  });

  factory SeniorityAnalysisResult.unknown() {
    return const SeniorityAnalysisResult(
      detectedJdSeniority: 'Unknown',
      requiredYearsOfExperience: null,
      estimatedResumeSeniority: 'Unknown',
      candidateYearsOfExperience: 0,
      alignmentStatus: 'Unknown',
    );
  }

  Map<String, dynamic> toMap() => {
        'detectedJdSeniority': detectedJdSeniority,
        'requiredYearsOfExperience': requiredYearsOfExperience,
        'estimatedResumeSeniority': estimatedResumeSeniority,
        'candidateYearsOfExperience': candidateYearsOfExperience,
        'alignmentStatus': alignmentStatus,
      };

  factory SeniorityAnalysisResult.fromMap(Map<String, dynamic> map) =>
      SeniorityAnalysisResult(
        detectedJdSeniority: map['detectedJdSeniority'] ?? 'Unknown',
        requiredYearsOfExperience: map['requiredYearsOfExperience'] as int?,
        estimatedResumeSeniority: map['estimatedResumeSeniority'] ?? 'Unknown',
        candidateYearsOfExperience: map['candidateYearsOfExperience'] ?? 0,
        alignmentStatus: map['alignmentStatus'] ?? 'Unknown',
      );
}

/// Service that analyzes target job seniority requirements and compares against candidate profile.
class SeniorityAnalyzerService {
  /// Detects target seniority level from [jobText] and compares with [resume].
  SeniorityAnalysisResult analyzeSeniority(String jobText, {Resume? resume}) {
    if (jobText.trim().isEmpty) {
      return SeniorityAnalysisResult.unknown();
    }

    final lower = jobText.toLowerCase();

    // 1. Detect required years of experience from text
    int? requiredYears;
    final expRegex = RegExp(r'(\d+)\s*(?:\+|\s*-\s*\d+)?\s*(?:years|yrs)\b', caseSensitive: false);
    final expMatch = expRegex.firstMatch(lower);
    if (expMatch != null) {
      requiredYears = int.tryParse(expMatch.group(1)!);
    }

    // 2. Detect seniority level keyword signals
    String jdSeniority = 'Mid Level'; // default fallback if unassigned
    if (lower.contains('intern') || lower.contains('internship')) {
      jdSeniority = 'Intern';
    } else if (lower.contains('director') || lower.contains('head of') || lower.contains('vp ')) {
      jdSeniority = 'Director / Executive';
    } else if (lower.contains('manager') || lower.contains('engineering manager')) {
      jdSeniority = 'Manager';
    } else if (lower.contains('principal') || lower.contains('staff architect') || lower.contains('distinguished')) {
      jdSeniority = 'Principal / Staff';
    } else if (lower.contains('lead') || lower.contains('tech lead') || lower.contains('team lead')) {
      jdSeniority = 'Lead';
    } else if (lower.contains('senior') || lower.contains('sr.') || lower.contains('sr ')) {
      jdSeniority = 'Senior';
    } else if (lower.contains('junior') || lower.contains('jr.') || lower.contains('jr ') || lower.contains('entry') || lower.contains('fresher')) {
      jdSeniority = 'Entry / Junior';
    } else if (requiredYears != null) {
      if (requiredYears <= 1) {
        jdSeniority = 'Entry / Junior';
      } else if (requiredYears <= 4) {
        jdSeniority = 'Mid Level';
      } else if (requiredYears <= 7) {
        jdSeniority = 'Senior';
      } else if (requiredYears <= 10) {
        jdSeniority = 'Lead';
      } else {
        jdSeniority = 'Principal / Executive';
      }
    } else if (!lower.contains('developer') && !lower.contains('engineer') && !lower.contains('specialist')) {
      jdSeniority = 'Unknown';
    }

    // 3. Estimate candidate seniority from resume
    int candidateYrs = 0;
    String resumeSeniority = 'Unknown';
    if (resume != null) {
      candidateYrs = _calculateCandidateYears(resume);
      if (candidateYrs == 0) {
        resumeSeniority = 'Entry Level';
      } else if (candidateYrs <= 2) {
        resumeSeniority = 'Junior Level';
      } else if (candidateYrs <= 5) {
        resumeSeniority = 'Mid Level';
      } else if (candidateYrs <= 8) {
        resumeSeniority = 'Senior Level';
      } else {
        resumeSeniority = 'Lead / Principal';
      }
    }

    // 4. Calculate alignment status
    String alignment = 'Unknown';
    if (resume != null && jdSeniority != 'Unknown') {
      final reqYrs = requiredYears ?? _estimatedYearsForSeniority(jdSeniority);
      if (candidateYrs >= reqYrs) {
        alignment = 'Well Aligned';
      } else if (candidateYrs < reqYrs - 2) {
        alignment = 'Under Qualified';
      } else {
        alignment = 'Moderately Aligned';
      }
    }

    return SeniorityAnalysisResult(
      detectedJdSeniority: jdSeniority,
      requiredYearsOfExperience: requiredYears,
      estimatedResumeSeniority: resumeSeniority,
      candidateYearsOfExperience: candidateYrs,
      alignmentStatus: alignment,
    );
  }

  int _calculateCandidateYears(Resume resume) {
    if (resume.experiences.isEmpty) return 0;
    int totalYears = 0;
    for (final exp in resume.experiences) {
      final startYear = _extractYear(exp.startDate);
      final endYear = exp.isCurrent ? DateTime.now().year : _extractYear(exp.endDate);

      if (startYear != null && endYear != null && endYear >= startYear) {
        totalYears += (endYear - startYear + 1);
      } else {
        totalYears += 1; // default 1 year per experience entry if unparsed
      }
    }
    return totalYears;
  }

  int? _extractYear(String dateStr) {
    final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(dateStr);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  int _estimatedYearsForSeniority(String seniority) {
    switch (seniority) {
      case 'Intern':
        return 0;
      case 'Entry / Junior':
        return 1;
      case 'Mid Level':
        return 3;
      case 'Senior':
        return 5;
      case 'Lead':
        return 8;
      case 'Principal / Staff':
        return 10;
      case 'Manager':
      case 'Director / Executive':
        return 10;
      default:
        return 2;
    }
  }
}
