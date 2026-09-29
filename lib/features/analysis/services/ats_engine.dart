import 'package:flutter/foundation.dart';
import '../../../data/models/resume_models.dart';

/// Represents the four core ATS evaluation dimensions.
enum AtsDimension {
  impactVerbs,
  formatting,
  contactCompleteness,
  keywordDensity;

  String get displayName {
    switch (this) {
      case AtsDimension.impactVerbs:
        return 'Impact Verbs';
      case AtsDimension.formatting:
        return 'Formatting';
      case AtsDimension.contactCompleteness:
        return 'Contact Completeness';
      case AtsDimension.keywordDensity:
        return 'Keyword Density';
    }
  }

  String get key {
    switch (this) {
      case AtsDimension.impactVerbs:
        return 'impactVerbs';
      case AtsDimension.formatting:
        return 'formatting';
      case AtsDimension.contactCompleteness:
        return 'contactCompleteness';
      case AtsDimension.keywordDensity:
        return 'keywordDensity';
    }
  }
}

/// Priority / severity level of an ATS recommendation.
enum AtsPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case AtsPriority.high:
        return 'Critical Fix';
      case AtsPriority.medium:
        return 'Recommended';
      case AtsPriority.low:
        return 'Enhancement';
    }
  }
}

/// Immutable model representing an actionable ATS recommendation.
@immutable
class AtsRecommendation {
  final String id;
  final String title;
  final String description;
  final AtsDimension dimension;
  final AtsPriority priority;
  final bool isAiFixable;
  final String? contextInfo;

  const AtsRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.dimension,
    required this.priority,
    this.isAiFixable = true,
    this.contextInfo,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'dimension': dimension.key,
        'priority': priority.name,
        'isAiFixable': isAiFixable,
        'contextInfo': contextInfo,
      };

  factory AtsRecommendation.fromMap(Map<String, dynamic> map) {
    final dimStr = map['dimension'] as String? ?? 'formatting';
    final dimension = AtsDimension.values.firstWhere(
      (d) => d.key == dimStr || d.name == dimStr,
      orElse: () => AtsDimension.formatting,
    );

    final prioStr = map['priority'] as String? ?? 'medium';
    final priority = AtsPriority.values.firstWhere(
      (p) => p.name == prioStr,
      orElse: () => AtsPriority.medium,
    );

    return AtsRecommendation(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dimension: dimension,
      priority: priority,
      isAiFixable: map['isAiFixable'] as bool? ?? true,
      contextInfo: map['contextInfo'] as String?,
    );
  }
}

/// Result model containing overall ATS score, 4-dimension breakdowns, and recommendations.
@immutable
class AtsScoreReport {
  final int overallScore;
  final int impactVerbsScore;
  final int formattingScore;
  final int contactCompletenessScore;
  final int keywordDensityScore;
  final List<AtsRecommendation> recommendations;

  const AtsScoreReport({
    required this.overallScore,
    required this.impactVerbsScore,
    required this.formattingScore,
    required this.contactCompletenessScore,
    required this.keywordDensityScore,
    required this.recommendations,
  })  : assert(overallScore >= 0 && overallScore <= 100),
        assert(impactVerbsScore >= 0 && impactVerbsScore <= 100),
        assert(formattingScore >= 0 && formattingScore <= 100),
        assert(contactCompletenessScore >= 0 && contactCompletenessScore <= 100),
        assert(keywordDensityScore >= 0 && keywordDensityScore <= 100);

  Map<String, int> get categoryScores => {
        AtsDimension.impactVerbs.key: impactVerbsScore,
        AtsDimension.formatting.key: formattingScore,
        AtsDimension.contactCompleteness.key: contactCompletenessScore,
        AtsDimension.keywordDensity.key: keywordDensityScore,
      };

  Map<String, dynamic> toMap() => {
        'overallScore': overallScore,
        'impactVerbsScore': impactVerbsScore,
        'formattingScore': formattingScore,
        'contactCompletenessScore': contactCompletenessScore,
        'keywordDensityScore': keywordDensityScore,
        'recommendations': recommendations.map((r) => r.toMap()).toList(),
      };

  factory AtsScoreReport.fromMap(Map<String, dynamic> map) {
    return AtsScoreReport(
      overallScore: (map['overallScore'] as num? ?? 0).toInt().clamp(0, 100),
      impactVerbsScore: (map['impactVerbsScore'] as num? ?? 0).toInt().clamp(0, 100),
      formattingScore: (map['formattingScore'] as num? ?? 0).toInt().clamp(0, 100),
      contactCompletenessScore: (map['contactCompletenessScore'] as num? ?? 0).toInt().clamp(0, 100),
      keywordDensityScore: (map['keywordDensityScore'] as num? ?? 0).toInt().clamp(0, 100),
      recommendations: (map['recommendations'] as List? ?? [])
          .map((e) => AtsRecommendation.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Production-quality, deterministic, rule-based ATS Scoring Engine.
class AtsEngine {
  /// Strong action verbs commonly recommended for ATS resume optimization.
  static const Set<String> kStrongActionVerbs = {
    'developed',
    'built',
    'designed',
    'implemented',
    'engineered',
    'optimized',
    'automated',
    'led',
    'created',
    'delivered',
    'improved',
    'reduced',
    'increased',
    'integrated',
    'architected',
    'deployed',
    'managed',
    'analyzed',
    'configured',
    'migrated',
    'tested',
    'spearheaded',
    'established',
    'scaled',
    'formulated',
    'mentored',
    'negotiated',
    'accelerated',
    'transformed',
    'orchestrated',
    'solved',
    'executed',
    'launched',
    'upgraded',
    'expanded',
    'overhauled',
    'streamlined',
    'standardized',
    'drove',
    'pioneered',
    'enhanced',
    'authored',
    'generated',
    'resolved',
    'monitored',
    'programmed',
  };

  /// Weak or passive phrase openings to flag in bullet points.
  static const List<String> kWeakPassiveStarters = [
    'responsible for',
    'worked on',
    'helped with',
    'assisted in',
    'tasked with',
    'handled',
    'participated in',
    'did',
    'was in charge of',
    'helped to',
    'assisted with',
    'contributed to',
  ];

  /// Standard English stop words to exclude when analyzing keyword density.
  static const Set<String> kStopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of',
    'with', 'by', 'from', 'up', 'about', 'into', 'over', 'after', 'is', 'are',
    'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
    'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must',
    'shall', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his',
    'her', 'its', 'our', 'their', 'this', 'these', 'those', 'as', 'than',
    'such', 'that', 'which', 'who', 'whom', 'where', 'when', 'why', 'how', 'all',
    'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'no', 'nor',
    'not', 'only', 'own', 'same', 'so', 'too', 'very', 'just', 'moreover',
  };

  /// Analyzes a [Resume] and returns an immutable [AtsScoreReport].
  AtsScoreReport analyze(Resume resume) {
    final recommendations = <AtsRecommendation>[];

    // 1. Evaluate Impact Verbs
    final impactResult = _evaluateImpactVerbs(resume, recommendations);

    // 2. Evaluate Formatting
    final formattingResult = _evaluateFormatting(resume, recommendations);

    // 3. Evaluate Contact Completeness
    final contactResult = _evaluateContactCompleteness(resume, recommendations);

    // 4. Evaluate Keyword Density
    final keywordResult = _evaluateKeywordDensity(resume, recommendations);

    // 5. Calculate transparent equal-weighted overall score (25% each)
    final double rawOverall = (impactResult * 0.25) +
        (formattingResult * 0.25) +
        (contactResult * 0.25) +
        (keywordResult * 0.25);

    final int overallScore = rawOverall.round().clamp(0, 100);

    return AtsScoreReport(
      overallScore: overallScore,
      impactVerbsScore: impactResult,
      formattingScore: formattingResult,
      contactCompletenessScore: contactResult,
      keywordDensityScore: keywordResult,
      recommendations: recommendations,
    );
  }

  /// Evaluates impact/action verbs in bullet points (0-100).
  int _evaluateImpactVerbs(Resume resume, List<AtsRecommendation> recs) {
    final bullets = <String>[];

    for (final exp in resume.experiences) {
      if (exp.description.trim().isNotEmpty) {
        final lines = exp.description.split('\n');
        for (final line in lines) {
          final trimmed = line.replaceAll(RegExp(r'^[\s\-\*\•\d\.\)]+'), '').trim();
          if (trimmed.isNotEmpty) {
            bullets.add(trimmed);
          }
        }
      }
    }

    for (final proj in resume.projects) {
      if (proj.description.trim().isNotEmpty) {
        final lines = proj.description.split('\n');
        for (final line in lines) {
          final trimmed = line.replaceAll(RegExp(r'^[\s\-\*\•\d\.\)]+'), '').trim();
          if (trimmed.isNotEmpty) {
            bullets.add(trimmed);
          }
        }
      }
    }

    if (bullets.isEmpty) {
      if (resume.experiences.isEmpty && resume.projects.isEmpty) {
        recs.add(const AtsRecommendation(
          id: 'imp_no_exp',
          title: 'Add Work Experience Bullets',
          description: 'Add work experiences or projects with bullet points starting with strong action verbs like "Architected" or "Optimized".',
          dimension: AtsDimension.impactVerbs,
          priority: AtsPriority.high,
          isAiFixable: true,
          contextInfo: '0 bullet points found',
        ));
        return 0;
      } else {
        recs.add(const AtsRecommendation(
          id: 'imp_empty_bullets',
          title: 'Add Bullet Descriptions',
          description: 'Your work experiences currently lack bullet descriptions. Add bullet points highlighting key accomplishments.',
          dimension: AtsDimension.impactVerbs,
          priority: AtsPriority.high,
          isAiFixable: true,
          contextInfo: 'Blank experience descriptions',
        ));
        return 20;
      }
    }

    int strongCount = 0;
    int weakCount = 0;
    int quantifiedCount = 0;
    final numberRegExp = RegExp(r'\b(\d+%?|\$\d+|\d+\+|\d+k|\d+m|\d+x)\b', caseSensitive: false);

    for (final bullet in bullets) {
      final lower = bullet.toLowerCase();
      final words = lower.split(RegExp(r'\s+'));
      final firstWord = words.isNotEmpty ? words.first.replaceAll(RegExp(r'[^a-z]'), '') : '';

      if (kStrongActionVerbs.contains(firstWord)) {
        strongCount++;
      }

      for (final weak in kWeakPassiveStarters) {
        if (lower.startsWith(weak)) {
          weakCount++;
          break;
        }
      }

      if (numberRegExp.hasMatch(bullet)) {
        quantifiedCount++;
      }
    }

    final double strongRatio = strongCount / bullets.length;
    final double quantifiedRatio = quantifiedCount / bullets.length;
    final double weakRatio = weakCount / bullets.length;

    double score = (strongRatio * 70) + (quantifiedRatio * 30) - (weakRatio * 25);
    score = score.clamp(0.0, 100.0);
    final int finalScore = score.round();

    if (weakCount > 0) {
      recs.add(AtsRecommendation(
        id: 'imp_weak_starters',
        title: 'Replace Weak Bullet Openings',
        description: 'Replace passive phrases like "worked on" or "responsible for" with decisive action verbs.',
        dimension: AtsDimension.impactVerbs,
        priority: AtsPriority.high,
        isAiFixable: true,
        contextInfo: '$weakCount passive bullet(s) detected',
      ));
    }

    if (strongRatio < 0.6 && bullets.isNotEmpty) {
      recs.add(AtsRecommendation(
        id: 'imp_strong_verbs',
        title: 'Use More Action/Impact Verbs',
        description: 'Ensure each bullet point opens with a strong verb (e.g., Developed, Engineered, Optimized, Led).',
        dimension: AtsDimension.impactVerbs,
        priority: AtsPriority.medium,
        isAiFixable: true,
        contextInfo: '${(strongRatio * 100).round()}% bullets start with action verbs',
      ));
    }

    if (quantifiedRatio < 0.3 && bullets.isNotEmpty) {
      recs.add(const AtsRecommendation(
        id: 'imp_quantify',
        title: 'Quantify Accomplishments with Data',
        description: 'Include measurable metrics (percentages, numbers, dollars saved) to prove your impact to recruiters.',
        dimension: AtsDimension.impactVerbs,
        priority: AtsPriority.medium,
        isAiFixable: true,
        contextInfo: 'Few metrics found in bullet points',
      ));
    }

    return finalScore;
  }

  /// Evaluates formatting and structural organization (0-100).
  int _evaluateFormatting(Resume resume, List<AtsRecommendation> recs) {
    int score = 0;

    // Contact info present (20 pts)
    final hasContact = resume.personalInfo.fullName.isNotEmpty &&
        (resume.personalInfo.email.isNotEmpty || resume.personalInfo.phone.isNotEmpty);
    if (hasContact) {
      score += 20;
    } else {
      recs.add(const AtsRecommendation(
        id: 'fmt_contact',
        title: 'Complete Contact Details',
        description: 'Ensure your full name and at least email or phone number are filled in.',
        dimension: AtsDimension.formatting,
        priority: AtsPriority.high,
        isAiFixable: false,
      ));
    }

    // Professional summary section (20 pts)
    final summaryText = resume.summary.summaryText.trim();
    if (summaryText.isNotEmpty) {
      if (summaryText.length >= 30 && summaryText.length <= 600) {
        score += 20;
      } else if (summaryText.length < 30) {
        score += 10;
        recs.add(const AtsRecommendation(
          id: 'fmt_summary_short',
          title: 'Expand Professional Summary',
          description: 'Your summary is very brief. Expand it to 2-4 sentences highlighting your expertise.',
          dimension: AtsDimension.formatting,
          priority: AtsPriority.medium,
          isAiFixable: true,
          contextInfo: 'Summary under 30 characters',
        ));
      } else {
        score += 10;
        recs.add(const AtsRecommendation(
          id: 'fmt_summary_long',
          title: 'Shorten Professional Summary',
          description: 'Keep your summary concise (under 600 characters) for optimal ATS readability.',
          dimension: AtsDimension.formatting,
          priority: AtsPriority.low,
          isAiFixable: true,
          contextInfo: 'Summary exceeds 600 characters',
        ));
      }
    } else {
      recs.add(const AtsRecommendation(
        id: 'fmt_no_summary',
        title: 'Add Professional Summary',
        description: 'Include a concise summary at the top of your resume to state your core value proposition.',
        dimension: AtsDimension.formatting,
        priority: AtsPriority.medium,
        isAiFixable: true,
      ));
    }

    // Work Experience section (25 pts)
    if (resume.experiences.isNotEmpty) {
      bool validExperiences = true;
      for (final exp in resume.experiences) {
        if (exp.company.trim().isEmpty || exp.position.trim().isEmpty) {
          validExperiences = false;
          break;
        }
      }
      if (validExperiences) {
        score += 25;
      } else {
        score += 15;
        recs.add(const AtsRecommendation(
          id: 'fmt_exp_details',
          title: 'Complete Experience Titles & Companies',
          description: 'Ensure every work experience entry includes both position title and company name.',
          dimension: AtsDimension.formatting,
          priority: AtsPriority.high,
          isAiFixable: false,
        ));
      }
    } else {
      recs.add(const AtsRecommendation(
        id: 'fmt_no_exp',
        title: 'Add Work Experience Section',
        description: 'ATS parsers look for standard work experience entries with dates and job titles.',
        dimension: AtsDimension.formatting,
        priority: AtsPriority.high,
        isAiFixable: false,
      ));
    }

    // Education section (20 pts)
    if (resume.educationList.isNotEmpty) {
      bool validEdu = true;
      for (final edu in resume.educationList) {
        if (edu.institution.trim().isEmpty || edu.degree.trim().isEmpty) {
          validEdu = false;
          break;
        }
      }
      if (validEdu) {
        score += 20;
      } else {
        score += 10;
        recs.add(const AtsRecommendation(
          id: 'fmt_edu_details',
          title: 'Complete Education Fields',
          description: 'Specify school name and degree title for all education entries.',
          dimension: AtsDimension.formatting,
          priority: AtsPriority.medium,
          isAiFixable: false,
        ));
      }
    } else {
      recs.add(const AtsRecommendation(
        id: 'fmt_no_edu',
        title: 'Add Education Section',
        description: 'Add your degree or education credentials to satisfy mandatory ATS filters.',
        dimension: AtsDimension.formatting,
        priority: AtsPriority.medium,
        isAiFixable: false,
      ));
    }

    // Skills section (15 pts)
    if (resume.skills.isNotEmpty) {
      score += 15;
    } else {
      recs.add(const AtsRecommendation(
        id: 'fmt_no_skills',
        title: 'Add Skills Section',
        description: 'A dedicated skills section is essential for structural formatting in ATS engines.',
        dimension: AtsDimension.formatting,
        priority: AtsPriority.high,
        isAiFixable: true,
      ));
    }

    return score.clamp(0, 100);
  }

  /// Evaluates contact information completeness (0-100).
  int _evaluateContactCompleteness(Resume resume, List<AtsRecommendation> recs) {
    final info = resume.personalInfo;
    final hasEmail = info.email.trim().isNotEmpty && info.email.contains('@');
    final hasPhone = info.phone.trim().isNotEmpty;

    // If no email and no phone, resume cannot be contacted (0 score)
    if (!hasEmail && !hasPhone) {
      recs.add(const AtsRecommendation(
        id: 'cnt_no_contact',
        title: 'Add Email or Phone Number',
        description: 'Your resume lacks direct contact info (email and phone). ATS systems will automatically reject contact-less profiles.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.high,
        isAiFixable: false,
      ));
      return 0;
    }

    int score = 0;

    // Full name (25 pts)
    if (info.fullName.trim().isNotEmpty) {
      score += 25;
    } else {
      recs.add(const AtsRecommendation(
        id: 'cnt_name',
        title: 'Add Candidate Full Name',
        description: 'Full candidate name is required for recruiter identification.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.high,
        isAiFixable: false,
      ));
    }

    // Email (25 pts)
    if (hasEmail) {
      score += 25;
    } else {
      recs.add(const AtsRecommendation(
        id: 'cnt_email_missing',
        title: 'Add Contact Email',
        description: 'Email is the primary channel ATS systems use for interview scheduling.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.high,
        isAiFixable: false,
      ));
    }

    // Phone (20 pts)
    if (hasPhone) {
      score += 20;
    } else {
      recs.add(const AtsRecommendation(
        id: 'cnt_phone_missing',
        title: 'Add Phone Number',
        description: 'Include a direct phone number so recruiters can conduct phone screenings.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.medium,
        isAiFixable: false,
      ));
    }

    // Location (15 pts)
    if (info.location.trim().isNotEmpty) {
      score += 15;
    } else {
      recs.add(const AtsRecommendation(
        id: 'cnt_location_missing',
        title: 'Add Location (City, State/Country)',
        description: 'Location helps ATS systems match local or remote candidate requirements.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.medium,
        isAiFixable: false,
      ));
    }

    // Online Presence / Portfolio / LinkedIn / GitHub (15 pts)
    final hasWebsite = info.website.trim().isNotEmpty;
    final hasSocials = resume.socialLinks.any((s) => s.url.trim().isNotEmpty);
    if (hasWebsite || hasSocials) {
      score += 15;
    } else {
      recs.add(const AtsRecommendation(
        id: 'cnt_social_missing',
        title: 'Add LinkedIn or Portfolio URL',
        description: 'Include a link to your LinkedIn profile, GitHub, or online portfolio to increase candidate credibility.',
        dimension: AtsDimension.contactCompleteness,
        priority: AtsPriority.low,
        isAiFixable: false,
      ));
    }

    return score.clamp(0, 100);
  }

  /// Evaluates technical and professional keyword density (0-100).
  int _evaluateKeywordDensity(Resume resume, List<AtsRecommendation> recs) {
    int score = 0;

    // 1. Skill count score (Max 40 pts)
    final skillCount = resume.skills.where((s) => s.name.trim().isNotEmpty).length;
    if (skillCount >= 8) {
      score += 40;
    } else if (skillCount >= 5) {
      score += 30;
      recs.add(AtsRecommendation(
        id: 'kw_skills_count',
        title: 'Expand Skills List',
        description: 'You currently have $skillCount skills. Adding 8 or more skills improves keyword matching for target roles.',
        dimension: AtsDimension.keywordDensity,
        priority: AtsPriority.medium,
        isAiFixable: true,
        contextInfo: '$skillCount skills listed',
      ));
    } else if (skillCount >= 1) {
      score += 15;
      recs.add(AtsRecommendation(
        id: 'kw_skills_few',
        title: 'Add Core Technical & Industry Skills',
        description: 'Include a broader range of technical tools, frameworks, and domain skills.',
        dimension: AtsDimension.keywordDensity,
        priority: AtsPriority.high,
        isAiFixable: true,
        contextInfo: '$skillCount skills listed',
      ));
    } else {
      recs.add(const AtsRecommendation(
        id: 'kw_no_skills',
        title: 'Add Job Relevant Keywords',
        description: 'Listing key technical skills is critical for passing ATS keyword filters.',
        dimension: AtsDimension.keywordDensity,
        priority: AtsPriority.high,
        isAiFixable: true,
      ));
    }

    // 2. Text keyword richness across experience, projects, & summary (Max 40 pts)
    final textBuffer = StringBuffer();
    textBuffer.write(' ${resume.summary.summaryText}');
    for (final exp in resume.experiences) {
      textBuffer.write(' ${exp.position} ${exp.description}');
    }
    for (final proj in resume.projects) {
      textBuffer.write(' ${proj.name} ${proj.role} ${proj.description} ${proj.technologies}');
    }

    final rawTokens = textBuffer.toString().toLowerCase().split(RegExp(r'[^a-z0-9\+\#\.]+'));
    final meaningfulTokens = <String>{};
    for (final token in rawTokens) {
      final clean = token.trim();
      if (clean.length >= 3 && !kStopWords.contains(clean)) {
        meaningfulTokens.add(clean);
      }
    }

    final uniqueKeywordCount = meaningfulTokens.length;
    if (uniqueKeywordCount >= 35) {
      score += 40;
    } else if (uniqueKeywordCount >= 20) {
      score += 25;
    } else if (uniqueKeywordCount >= 8) {
      score += 15;
      recs.add(const AtsRecommendation(
        id: 'kw_richness_low',
        title: 'Enrich Descriptions with Industry Terms',
        description: 'Incorporate relevant industry terms, tools, and methodologies in experience descriptions.',
        dimension: AtsDimension.keywordDensity,
        priority: AtsPriority.medium,
        isAiFixable: true,
      ));
    } else if (uniqueKeywordCount > 0) {
      score += 5;
    }

    // 3. Projects, Certifications & Languages bonus (Max 20 pts)
    int additionalScore = 0;
    if (resume.projects.isNotEmpty) additionalScore += 10;
    if (resume.certifications.isNotEmpty) additionalScore += 5;
    if (resume.languages.isNotEmpty) additionalScore += 5;
    score += additionalScore;

    if (resume.projects.isEmpty) {
      recs.add(const AtsRecommendation(
        id: 'kw_projects_missing',
        title: 'Add Projects to Boost Keyword Match',
        description: 'Adding projects with technologies used boosts keyword relevance for technical roles.',
        dimension: AtsDimension.keywordDensity,
        priority: AtsPriority.low,
        isAiFixable: false,
      ));
    }

    return score.clamp(0, 100);
  }
}
