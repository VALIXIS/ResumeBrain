import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/resume_models.dart';
import '../pdf/models/pdf_export_config.dart';
import 'models/resume_template.dart';

/// Tech Modern Template
///
/// Feature-packed modern two-column layout tailored for engineers, developers,
/// data scientists, and technical architects. Features technical skill badge chips,
/// GitHub/portfolio icons/badges, and structured project highlights with 100% ATS parseability.
class TechModernTemplate implements ResumeTemplate {
  final PdfColor? customAccentColor;

  TechModernTemplate({this.customAccentColor});

  @override
  String get id => 'tech_modern';

  @override
  String get name => 'Tech Modern';

  @override
  String get description =>
      'Clean modern two-column layout featuring technical skill badge chips, GitHub/portfolio links, and structured project highlights.';

  @override
  String get previewThumbnail => 'assets/templates/tech_modern.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);

    // Color tokens
    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final accentColor = config?.colorPalette.pdfColor ??
        customAccentColor ??
        PdfColor.fromHex('#2563EB'); // Tech Blue 600
    final secondaryAccent = PdfColor.fromHex('#0284C7'); // Sky Blue 600
    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = PdfColor.fromHex('#64748B'); // Slate 500

    // Badge styling tokens
    final badgeBg = PdfColor.fromHex('#EFF6FF'); // Blue 50
    final badgeBorder = PdfColor.fromHex('#BFDBFE'); // Blue 200
    final badgeText = PdfColor.fromHex('#1D4ED8'); // Blue 700

    final linkBadgeBg = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final linkBadgeBorder = PdfColor.fromHex('#CBD5E1'); // Slate 300

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ??
            const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  resume.personalInfo.fullName.isNotEmpty
                      ? '${resume.personalInfo.fullName} - Tech Resume'
                      : 'Tech Resume',
                  style: pw.TextStyle(fontSize: 8, color: mutedTextColor),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: mutedTextColor),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ---------------------------------------------------------------
            // 1. MODERN TECH HEADER BANNER
            // ---------------------------------------------------------------
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
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                resume.personalInfo.jobTitle.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // Contact Badges & Social Links (GitHub, Portfolio, LinkedIn)
                  pw.Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    crossAxisAlignment: pw.WrapCrossAlignment.center,
                    children: [
                      if (resume.personalInfo.email.isNotEmpty)
                        _buildContactChip('Email', resume.personalInfo.email,
                            linkBadgeBg, linkBadgeBorder, textColor),
                      if (resume.personalInfo.phone.isNotEmpty)
                        _buildContactChip('Phone', resume.personalInfo.phone,
                            linkBadgeBg, linkBadgeBorder, textColor),
                      if (resume.personalInfo.location.isNotEmpty)
                        _buildContactChip('Location',
                            resume.personalInfo.location, linkBadgeBg, linkBadgeBorder, textColor),
                      if (resume.personalInfo.website.isNotEmpty)
                        _buildContactChip('Portfolio',
                            resume.personalInfo.website, badgeBg, badgeBorder, badgeText),
                      ...resume.socialLinks
                          .where((s) => s.url.isNotEmpty)
                          .map((s) {
                        final prefix = s.platform.toLowerCase().contains('git')
                            ? 'GitHub'
                            : (s.platform.toLowerCase().contains('link')
                                ? 'LinkedIn'
                                : s.platform);
                        return _buildContactChip(prefix, s.url, badgeBg,
                            badgeBorder, badgeText);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ---------------------------------------------------------------
            // 2. TWO-COLUMN LAYOUT BODY
            // ---------------------------------------------------------------
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // -- LEFT / MAIN COLUMN (64% width) -------------------------
                pw.Expanded(
                  flex: 64,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Summary / Tech Bio
                      if (resume.summary.summaryText.isNotEmpty) ...[
                        _buildSectionHeading('PROFILE SUMMARY', accentColor),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          resume.summary.summaryText,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: textColor,
                            lineSpacing: 1.3,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                      ],

                      // Experience
                      if (resume.experiences.isNotEmpty) ...[
                        _buildSectionHeading(
                            'WORK EXPERIENCE', accentColor),
                        pw.SizedBox(height: 6),
                        ...resume.experiences.map((exp) {
                          final dateRange = [
                            if (exp.startDate.isNotEmpty) exp.startDate,
                            if (exp.isCurrent)
                              'Present'
                            else if (exp.endDate.isNotEmpty)
                              exp.endDate,
                          ].join(' - ');

                          final bullets = exp.description
                              .split('\n')
                              .map((s) => s.trim().replaceAll(RegExp(r'^[•\-\*]\s*'), ''))
                              .where((s) => s.isNotEmpty)
                              .toList();

                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Expanded(
                                      child: pw.Text(
                                        exp.position.isNotEmpty
                                            ? exp.position
                                            : 'Software Engineer',
                                        style: pw.TextStyle(
                                          fontSize: 9.8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    if (dateRange.isNotEmpty)
                                      pw.Text(
                                        dateRange,
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
                                  [
                                    exp.company,
                                    if (exp.location.isNotEmpty) exp.location,
                                  ].where((s) => s.isNotEmpty).join(' | '),
                                  style: pw.TextStyle(
                                    fontSize: 8.8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: secondaryAccent,
                                  ),
                                ),
                                if (bullets.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  ...bullets.map(
                                    (b) => pw.Padding(
                                      padding: const pw.EdgeInsets.only(
                                          left: 4, bottom: 2),
                                      child: pw.Row(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text('> ',
                                              style: pw.TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: accentColor)),
                                          pw.Expanded(
                                            child: pw.Text(
                                              b,
                                              style: pw.TextStyle(
                                                fontSize: 8.5,
                                                color: textColor,
                                                lineSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 6),
                      ],

                      // Projects
                      if (resume.projects.isNotEmpty) ...[
                        _buildSectionHeading(
                            'TECHNICAL PROJECTS', accentColor),
                        pw.SizedBox(height: 6),
                        ...resume.projects.map((proj) {
                          final techTags = proj.technologies
                              .split(RegExp(r'[,;*|]'))
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();

                          final bullets = proj.description
                              .split('\n')
                              .map((s) => s.trim().replaceAll(RegExp(r'^[•\-\*]\s*'), ''))
                              .where((s) => s.isNotEmpty)
                              .toList();

                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 7),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      proj.name,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    if (proj.link.isNotEmpty)
                                      pw.Text(
                                        proj.link,
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          color: secondaryAccent,
                                          decoration: pw.TextDecoration.underline,
                                        ),
                                      ),
                                  ],
                                ),
                                if (techTags.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  pw.Wrap(
                                    spacing: 4,
                                    runSpacing: 3,
                                    children: techTags.map((tech) {
                                      return pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1.5),
                                        decoration: pw.BoxDecoration(
                                          color: badgeBg,
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                          border: pw.Border.all(
                                              color: badgeBorder, width: 0.5),
                                        ),
                                        child: pw.Text(
                                          tech,
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: badgeText,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (bullets.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  ...bullets.map(
                                    (b) => pw.Padding(
                                      padding: const pw.EdgeInsets.only(
                                          left: 4, bottom: 1.5),
                                      child: pw.Row(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text('> ',
                                              style: pw.TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: accentColor)),
                                          pw.Expanded(
                                            child: pw.Text(
                                              b,
                                              style: pw.TextStyle(
                                                fontSize: 8.2,
                                                color: textColor,
                                                lineSpacing: 1.15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(width: 14),

                // -- RIGHT / SIDEBAR COLUMN (36% width) --------------------
                pw.Expanded(
                  flex: 36,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Technical Skills Badge Chips
                      if (resume.skills.isNotEmpty) ...[
                        _buildSectionHeading(
                            'SKILLS & STACK', accentColor),
                        pw.SizedBox(height: 6),
                        pw.Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: resume.skills.map((skill) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: badgeBg,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(
                                    color: badgeBorder, width: 0.6),
                              ),
                              child: pw.Text(
                                skill.name,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: badgeText,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        pw.SizedBox(height: 10),
                      ],

                      // Education
                      if (resume.educationList.isNotEmpty) ...[
                        _buildSectionHeading('EDUCATION', accentColor),
                        pw.SizedBox(height: 6),
                        ...resume.educationList.map((edu) {
                          final dateRange = [
                            if (edu.startDate.isNotEmpty) edu.startDate,
                            if (edu.endDate.isNotEmpty) edu.endDate,
                          ].join(' - ');

                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  edu.institution,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                if (edu.degree.isNotEmpty ||
                                    edu.fieldOfStudy.isNotEmpty) ...[
                                  pw.Text(
                                    [
                                      if (edu.degree.isNotEmpty) edu.degree,
                                      if (edu.fieldOfStudy.isNotEmpty)
                                        edu.fieldOfStudy,
                                    ].join(' in '),
                                    style: pw.TextStyle(
                                      fontSize: 8.2,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                                if (dateRange.isNotEmpty ||
                                    edu.gpa.isNotEmpty) ...[
                                  pw.Text(
                                    [
                                      if (dateRange.isNotEmpty) dateRange,
                                      if (edu.gpa.isNotEmpty)
                                        'GPA: ${edu.gpa}',
                                    ].join(' | '),
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 8),
                      ],

                      // Certifications
                      if (resume.certifications.isNotEmpty) ...[
                        _buildSectionHeading(
                            'CERTIFICATIONS', accentColor),
                        pw.SizedBox(height: 5),
                        ...resume.certifications.map((cert) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  cert.name,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                if (cert.issuingOrganization.isNotEmpty ||
                                    cert.issueDate.isNotEmpty)
                                  pw.Text(
                                    [
                                      if (cert.issuingOrganization.isNotEmpty)
                                        cert.issuingOrganization,
                                      if (cert.issueDate.isNotEmpty)
                                        cert.issueDate,
                                    ].join(' | '),
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 8),
                      ],

                      // Languages
                      if (resume.languages.isNotEmpty) ...[
                        _buildSectionHeading('LANGUAGES', accentColor),
                        pw.SizedBox(height: 4),
                        ...resume.languages.map((lang) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  lang.name,
                                  style: pw.TextStyle(
                                    fontSize: 8.2,
                                    fontWeight: pw.FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                pw.Text(
                                  lang.proficiency,
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 8),
                      ],

                      // Custom Sections (Honors, Awards, Community)
                      if (resume.customSections.isNotEmpty) ...[
                        ...resume.customSections.map((sec) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeading(
                                  sec.title.toUpperCase(), accentColor),
                              pw.SizedBox(height: 4),
                              ...sec.items.map(
                                (item) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 2),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('> ',
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                              color: accentColor)),
                                      pw.Expanded(
                                        child: pw.Text(
                                          item,
                                          style: pw.TextStyle(
                                            fontSize: 7.8,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 6),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionHeading(String title, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: accent,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 1.2,
          color: accent,
        ),
      ],
    );
  }

  pw.Widget _buildContactChip(
    String label,
    String value,
    PdfColor bg,
    PdfColor border,
    PdfColor textCol,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: border, width: 0.5),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: textCol,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7.5,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
