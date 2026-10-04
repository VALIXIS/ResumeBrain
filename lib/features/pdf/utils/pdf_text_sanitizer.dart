import '../../../data/models/resume_models.dart';

/// Comprehensive text sanitizer and bullet formatter for PDF compilation.
///
/// Strips unsupported Unicode emojis and control codes that cause missing-glyph
/// box-with-cross (☒ / .notdef) artifacts in standard Type-1 PDF fonts (Helvetica, Times).
/// Normalizes typographer quotes, dashes, spaces, and leading bullet point characters.
class PdfTextSanitizer {
  PdfTextSanitizer._();

  // Pattern matching Unicode emojis, surrogate symbols, pictographs, and dingbats
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F000}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  // Pattern matching zero-width and invisible control characters
  static final RegExp _invisibleCharsRegex = RegExp(
    r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F\u200B-\u200D\uFEFF]',
  );

  // Pattern matching bullet characters at line starts: •, ·, ▪, ●, ◦, ■, ‣, ⁃, -, *
  static final RegExp leadingBulletRegex = RegExp(
    r'^[\s\u2022\u00B7\u25AA\u25CF\u25E6\u2043\u2219\u25A0\u2023\-\*•·▪●◦■‣⁃]+',
  );

  // Pattern matching inline stray bullet characters
  static final RegExp _strayBulletRegex = RegExp(
    r'[\u2022\u00B7\u25AA\u25CF\u25E6\u2043\u2219\u25A0\u2023•·▪●◦■‣⁃]',
  );

  /// Sanitizes a string for clean rendering in PDF Type-1 fonts.
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    String text = input;

    // 1. Remove emojis and invisible characters
    text = text.replaceAll(_emojiRegex, '');
    text = text.replaceAll(_invisibleCharsRegex, '');

    // 2. Normalize smart/curly quotes to ASCII quotes
    text = text
        .replaceAll(RegExp(r'[\u201C\u201D\u201E\u201F\u00AB\u00BB]'), '"')
        .replaceAll(RegExp(r'[\u2018\u2019\u201A\u201B\u02BB\u02BC]'), "'");

    // 3. Normalize dashes (en-dash, em-dash, figure dash, minus) to ASCII hyphen
    text = text.replaceAll(RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]'), '-');

    // 4. Normalize non-breaking and special spaces to standard ASCII space
    text = text.replaceAll(RegExp(r'[\u00A0\u2000-\u200A\u202F\u205F\u3000]'), ' ');

    // 5. Replace any remaining stray bullet characters with a clean separator or dash
    text = text.replaceAll(_strayBulletRegex, '-');

    return text.trim();
  }

  /// Cleans a bullet point line by stripping any leading bullet markers and trimming.
  static String cleanBulletLine(String line) {
    final withoutLeadingBullet = line.replaceFirst(leadingBulletRegex, '').trim();
    return sanitize(withoutLeadingBullet);
  }

  /// Determines whether a text block represents a list of bullet points.
  static bool isBulletList(String text) {
    if (text.isEmpty) return false;
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length > 1) return true;
    return text.contains(leadingBulletRegex);
  }

  /// Splits multi-line or bullet-formatted text into clean individual bullet lines.
  static List<String> extractBulletLines(String text) {
    if (text.isEmpty) return const [];
    return text
        .split('\n')
        .map((l) => cleanBulletLine(l))
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Sanitizes all text fields across a [Resume] model to prevent any PDF font glyph errors.
  static Resume sanitizeResume(Resume resume) {
    return resume.copyWith(
      title: sanitize(resume.title),
      personalInfo: PersonalInformation(
        fullName: sanitize(resume.personalInfo.fullName),
        jobTitle: sanitize(resume.personalInfo.jobTitle),
        email: sanitize(resume.personalInfo.email),
        phone: sanitize(resume.personalInfo.phone),
        location: sanitize(resume.personalInfo.location),
        website: sanitize(resume.personalInfo.website),
      ),
      summary: ProfessionalSummary(
        summaryText: sanitize(resume.summary.summaryText),
      ),
      experiences: resume.experiences.map((exp) {
        return Experience(
          id: exp.id,
          company: sanitize(exp.company),
          position: sanitize(exp.position),
          location: sanitize(exp.location),
          startDate: sanitize(exp.startDate),
          endDate: sanitize(exp.endDate),
          isCurrent: exp.isCurrent,
          description: sanitize(exp.description),
        );
      }).toList(),
      educationList: resume.educationList.map((edu) {
        return Education(
          id: edu.id,
          institution: sanitize(edu.institution),
          degree: sanitize(edu.degree),
          fieldOfStudy: sanitize(edu.fieldOfStudy),
          location: sanitize(edu.location),
          startDate: sanitize(edu.startDate),
          endDate: sanitize(edu.endDate),
          gpa: sanitize(edu.gpa),
        );
      }).toList(),
      projects: resume.projects.map((proj) {
        return Project(
          id: proj.id,
          name: sanitize(proj.name),
          role: sanitize(proj.role),
          technologies: sanitize(proj.technologies),
          link: sanitize(proj.link),
          description: sanitize(proj.description),
        );
      }).toList(),
      skills: resume.skills.map((skill) {
        return Skill(
          id: skill.id,
          name: sanitize(skill.name),
          level: sanitize(skill.level),
        );
      }).toList(),
      certifications: resume.certifications.map((cert) {
        return Certification(
          id: cert.id,
          name: sanitize(cert.name),
          issuingOrganization: sanitize(cert.issuingOrganization),
          issueDate: sanitize(cert.issueDate),
          expiryDate: sanitize(cert.expiryDate),
          credentialId: sanitize(cert.credentialId),
          credentialUrl: sanitize(cert.credentialUrl),
        );
      }).toList(),
      languages: resume.languages.map((lang) {
        return Language(
          id: lang.id,
          name: sanitize(lang.name),
          proficiency: sanitize(lang.proficiency),
        );
      }).toList(),
      customSections: resume.customSections.map((sec) {
        return CustomSection(
          id: sec.id,
          title: sanitize(sec.title),
          items: sec.items.map((item) => sanitize(item)).toList(),
        );
      }).toList(),
    );
  }
}
