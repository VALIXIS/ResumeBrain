import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../models/resume_template.dart';

/// Template 4: TechSpecialistTemplate
///
/// Production-ready resume template specifically tailored for software engineers,
/// developers, DevOps specialists, and technical professionals.
/// Features high-impact visual hierarchy for technical skills (compact badges),
/// technical projects (with dedicated tech stack tags), and clean multi-page flow.
class TechSpecialistTemplate implements ResumeTemplate {
  final PdfColor? customAccentColor;

  TechSpecialistTemplate({this.customAccentColor});

  @override
  String get id => 'tech_specialist';

  @override
  String get name => 'Tech Specialist';

  @override
  String get description =>
      'Tech-focused, recruiter-approved layout with compact skill badges, technology stack tags, and structured project display.';

  @override
  String get previewThumbnail => 'assets/templates/tech_specialist.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat,
  ) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final accentColor =
        customAccentColor ?? PdfColor.fromHex('#0284C7'); // Tech Sky 600
    final secondaryAccent = PdfColor.fromHex('#2563EB'); // Royal Blue 600
    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = PdfColor.fromHex('#64748B'); // Slate 500
    final dividerColor = PdfColor.fromHex('#E2E8F0'); // Slate 200

    // Skill badge colors
    final badgeBgColor = PdfColor.fromHex('#F1F5F9'); // Slate 100
    final badgeBorderColor = PdfColor.fromHex('#CBD5E1'); // Slate 300
    final badgeTextColor = PdfColor.fromHex('#0F172A'); // Slate 900

    // Tech stack tag colors
    final techStackBgColor = PdfColor.fromHex('#E0F2FE'); // Sky 100
    final techStackBorderColor = PdfColor.fromHex('#BAE6FD'); // Sky 300
    final techStackTextColor = PdfColor.fromHex('#0369A1'); // Sky 700

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // -----------------------------------------------------------------
            // HEADER SECTION
            // -----------------------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: accentColor, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              resume.personalInfo.fullName.isNotEmpty
                                  ? resume.personalInfo.fullName
                                  : 'Your Full Name',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                              pw.SizedBox(height: 3),
                              pw.Text(
                                resume.personalInfo.jobTitle.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // Contact Information & Links
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: pw.WrapCrossAlignment.center,
                    children: [
                      if (resume.personalInfo.email.isNotEmpty)
                        _buildContactBadge(
                          'Email',
                          resume.personalInfo.email,
                          mutedTextColor,
                          textColor,
                        ),
                      if (resume.personalInfo.phone.isNotEmpty)
                        _buildContactBadge(
                          'Phone',
                          resume.personalInfo.phone,
                          mutedTextColor,
                          textColor,
                        ),
                      if (resume.personalInfo.location.isNotEmpty)
                        _buildContactBadge(
                          'Location',
                          resume.personalInfo.location,
                          mutedTextColor,
                          textColor,
                        ),
                      if (resume.personalInfo.website.isNotEmpty)
                        _buildContactBadge(
                          'Portfolio',
                          resume.personalInfo.website,
                          mutedTextColor,
                          secondaryAccent,
                        ),
                      ...resume.socialLinks.map(
                        (link) => _buildContactBadge(
                          link.platform,
                          link.url,
                          mutedTextColor,
                          secondaryAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // -----------------------------------------------------------------
            // PROFESSIONAL SUMMARY SECTION
            // -----------------------------------------------------------------
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionHeader(
                'PROFESSIONAL SUMMARY',
                accentColor,
                primaryColor,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: textColor,
                  lineSpacing: 1.8,
                ),
              ),
              pw.SizedBox(height: 12),
            ],

            // -----------------------------------------------------------------
            // TECHNICAL SKILLS SECTION (PRIMARY FEATURE)
            // -----------------------------------------------------------------
            if (resume.skills.isNotEmpty) ...[
              _buildSectionHeader(
                'TECHNICAL SKILLS',
                accentColor,
                primaryColor,
              ),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: resume.skills.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(
                        color: badgeBorderColor,
                        width: 0.8,
                      ),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          skill.name,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                        if (skill.level.isNotEmpty &&
                            skill.level.toLowerCase() != 'intermediate' &&
                            skill.level.toLowerCase() != 'n/a') ...[
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '(${skill.level})',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // -----------------------------------------------------------------
            // PROFESSIONAL EXPERIENCE SECTION
            // -----------------------------------------------------------------
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionHeader(
                'PROFESSIONAL EXPERIENCE',
                accentColor,
                primaryColor,
              ),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              exp.position,
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${exp.startDate}${exp.startDate.isNotEmpty && (exp.endDate.isNotEmpty || exp.isCurrent) ? ' - ' : ''}${exp.isCurrent ? 'Present' : exp.endDate}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        '${exp.company}${exp.location.isNotEmpty ? " - ${exp.location}" : ""}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          exp.description,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: textColor,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // TECHNICAL PROJECTS SECTION (PRIMARY FEATURE)
            // -----------------------------------------------------------------
            if (resume.projects.isNotEmpty) ...[
              _buildSectionHeader(
                'TECHNICAL PROJECTS',
                accentColor,
                primaryColor,
              ),
              pw.SizedBox(height: 6),
              ...resume.projects.map((proj) {
                // Parse comma-separated tech stack into tags
                final techList = proj.technologies.isNotEmpty
                    ? proj.technologies
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList()
                    : <String>[];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 9),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                    border: pw.Border.all(color: dividerColor, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: proj.name,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (proj.role.isNotEmpty)
                                    pw.TextSpan(
                                      text: '  -  ${proj.role}',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.normal,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (proj.link.isNotEmpty)
                            pw.Text(
                              proj.link,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: secondaryAccent,
                              ),
                            ),
                        ],
                      ),
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          proj.description,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: textColor,
                            lineSpacing: 1.4,
                          ),
                        ),
                      ],
                      if (techList.isNotEmpty) ...[
                        pw.SizedBox(height: 5),
                        pw.Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: techList.map((tech) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: techStackBgColor,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(3),
                                ),
                                border: pw.Border.all(
                                  color: techStackBorderColor,
                                  width: 0.6,
                                ),
                              ),
                              child: pw.Text(
                                tech,
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: techStackTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // EDUCATION SECTION
            // -----------------------------------------------------------------
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionHeader('EDUCATION', accentColor, primaryColor),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? " in ${edu.fieldOfStudy}" : ""}',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            pw.Text(
                              '${edu.institution}${edu.location.isNotEmpty ? " - ${edu.location}" : ""}${edu.gpa.isNotEmpty ? " - GPA: ${edu.gpa}" : ""}',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        '${edu.startDate}${edu.startDate.isNotEmpty && edu.endDate.isNotEmpty ? " - " : ""}${edu.endDate}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // CERTIFICATIONS & LANGUAGES SECTION
            // -----------------------------------------------------------------
            if (resume.certifications.isNotEmpty ||
                resume.languages.isNotEmpty) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (resume.certifications.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'CERTIFICATIONS',
                            accentColor,
                            primaryColor,
                          ),
                          pw.SizedBox(height: 4),
                          ...resume.certifications.map(
                            (c) => pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    c.name,
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (c.issuingOrganization.isNotEmpty ||
                                      c.issueDate.isNotEmpty)
                                    pw.Text(
                                      '${c.issuingOrganization}${c.issueDate.isNotEmpty ? " (${c.issueDate})" : ""}',
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (resume.certifications.isNotEmpty &&
                      resume.languages.isNotEmpty)
                    pw.SizedBox(width: 16),
                  if (resume.languages.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'LANGUAGES',
                            accentColor,
                            primaryColor,
                          ),
                          pw.SizedBox(height: 4),
                          ...resume.languages.map(
                            (l) => pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    l.name,
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  pw.Text(
                                    l.proficiency,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // CUSTOM SECTIONS
            // -----------------------------------------------------------------
            if (resume.customSections.isNotEmpty) ...[
              ...resume.customSections.map((section) {
                if (section.title.isEmpty && section.items.isEmpty) {
                  return pw.SizedBox();
                }
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (section.title.isNotEmpty)
                      _buildSectionHeader(
                        section.title.toUpperCase(),
                        accentColor,
                        primaryColor,
                      ),
                    pw.SizedBox(height: 4),
                    ...section.items.map(
                      (item) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          '- $item',
                          style: pw.TextStyle(fontSize: 8.5, color: textColor),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionHeader(
    String title,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 12,
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: PdfColor.fromHex('#E2E8F0')),
      ],
    );
  }

  pw.Widget _buildContactBadge(
    String label,
    String value,
    PdfColor labelColor,
    PdfColor valueColor,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: labelColor,
          ),
        ),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: valueColor)),
      ],
    );
  }
}
