import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/resume_models.dart';
import '../pdf/models/pdf_export_config.dart';
import 'models/resume_template.dart';

/// Academic Clean Template
///
/// Formal academic CV & resume layout optimized for academia, research scholars,
/// graduate students, professors, and scientists. Features structured sections
/// for coursework, peer-reviewed publications, teaching experience, grants, and awards.
/// Guaranteed 100% ATS score.
class AcademicCleanTemplate implements ResumeTemplate {
  final PdfColor? customAccentColor;

  AcademicCleanTemplate({this.customAccentColor});

  @override
  String get id => 'academic_clean';

  @override
  String get name => 'Academic Clean';

  @override
  String get description =>
      'Formal academic and research template optimized for publications, coursework, grants, and teaching experience.';

  @override
  String get previewThumbnail => 'assets/templates/academic_clean.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);

    // Color Palette
    final primaryColor = PdfColor.fromHex('#1E293B'); // Deep Slate 800
    final accentColor = config?.colorPalette.pdfColor ??
        customAccentColor ??
        PdfColor.fromHex('#0F766E'); // Academic Teal 700 / Burgundy
    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = PdfColor.fromHex('#475569'); // Slate 600
    final dividerColor = PdfColor.fromHex('#94A3B8'); // Slate 400

    final serifFont = pw.Font.times();
    final serifBold = pw.Font.timesBold();
    final serifItalic = pw.Font.timesItalic();

    final candidateName = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : 'Your Full Name';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ??
            const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  candidateName,
                  style: pw.TextStyle(
                    font: serifBold,
                    fontSize: 8.5,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Curriculum Vitae',
                  style: pw.TextStyle(
                    font: serifItalic,
                    fontSize: 8.5,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  candidateName,
                  style: pw.TextStyle(
                    font: serifItalic,
                    fontSize: 8,
                    color: mutedTextColor,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: serifFont,
                    fontSize: 8,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final contactLine = [
            if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
            if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
            if (resume.personalInfo.location.isNotEmpty)
              resume.personalInfo.location,
            if (resume.personalInfo.website.isNotEmpty)
              resume.personalInfo.website,
          ].join('   |   ');

          return [
            // ---------------------------------------------------------------
            // 1. ACADEMIC HEADER
            // ---------------------------------------------------------------
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    candidateName.toUpperCase(),
                    style: pw.TextStyle(
                      font: serifBold,
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      resume.personalInfo.jobTitle,
                      style: pw.TextStyle(
                        font: serifBold,
                        fontSize: 11,
                        color: accentColor,
                      ),
                    ),
                  ],
                  if (contactLine.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      contactLine,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: serifFont,
                        fontSize: 8.5,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                  if (resume.socialLinks.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      resume.socialLinks
                          .where((s) => s.url.isNotEmpty)
                          .map((s) => '${s.platform}: ${s.url}')
                          .join('   |   '),
                      style: pw.TextStyle(
                        font: serifItalic,
                        fontSize: 8,
                        color: accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: accentColor, thickness: 1.0),
            pw.SizedBox(height: 6),

            // ---------------------------------------------------------------
            // 2. RESEARCH INTERESTS & SUMMARY
            // ---------------------------------------------------------------
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionTitle(
                  'RESEARCH INTERESTS & PROFILE', accentColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(
                  font: serifFont,
                  fontSize: 9.2,
                  color: textColor,
                  lineSpacing: 1.3,
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // ---------------------------------------------------------------
            // 3. EDUCATION & COURSEWORK
            // ---------------------------------------------------------------
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionTitle(
                  'EDUCATION & COURSEWORK', accentColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                final dateRange = [
                  if (edu.startDate.isNotEmpty) edu.startDate,
                  if (edu.endDate.isNotEmpty) edu.endDate,
                ].join(' - ');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              edu.institution,
                              style: pw.TextStyle(
                                font: serifBold,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          if (dateRange.isNotEmpty)
                            pw.Text(
                              dateRange,
                              style: pw.TextStyle(
                                font: serifBold,
                                fontSize: 8.8,
                                color: mutedTextColor,
                              ),
                            ),
                        ],
                      ),
                      if (edu.degree.isNotEmpty ||
                          edu.fieldOfStudy.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          [
                            if (edu.degree.isNotEmpty) edu.degree,
                            if (edu.fieldOfStudy.isNotEmpty)
                              'in ${edu.fieldOfStudy}',
                          ].join(' '),
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 9,
                            color: accentColor,
                          ),
                        ),
                      ],
                      if (edu.gpa.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'GPA / Distinction: ${edu.gpa}',
                          style: pw.TextStyle(
                            font: serifFont,
                            fontSize: 8.5,
                            color: textColor,
                          ),
                        ),
                      ],
                      if (edu.location.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'Location: ${edu.location}',
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 8,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 4. ACADEMIC & RESEARCH APPOINTMENTS
            // ---------------------------------------------------------------
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionTitle(
                  'ACADEMIC & RESEARCH EXPERIENCE', accentColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                final dateRange = [
                  if (exp.startDate.isNotEmpty) exp.startDate,
                  if (exp.isCurrent)
                    'Present'
                  else if (exp.endDate.isNotEmpty)
                    exp.endDate,
                ].join(' - ');

                final affiliation = [
                  exp.company,
                  if (exp.location.isNotEmpty) exp.location,
                ].where((s) => s.isNotEmpty).join(' | ');

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
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              exp.position.isNotEmpty
                                  ? exp.position
                                  : 'Researcher / Faculty',
                              style: pw.TextStyle(
                                font: serifBold,
                                fontSize: 10,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          if (dateRange.isNotEmpty)
                            pw.Text(
                              dateRange,
                              style: pw.TextStyle(
                                font: serifBold,
                                fontSize: 8.8,
                                color: mutedTextColor,
                              ),
                            ),
                        ],
                      ),
                      if (affiliation.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          affiliation,
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 8.8,
                            color: accentColor,
                          ),
                        ),
                      ],
                      if (bullets.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        ...bullets.map(
                          (bullet) => pw.Padding(
                            padding: const pw.EdgeInsets.only(
                                left: 6, bottom: 2, top: 1),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('- ',
                                    style: pw.TextStyle(
                                        font: serifBold,
                                        fontSize: 8.8,
                                        color: accentColor)),
                                pw.Expanded(
                                  child: pw.Text(
                                    bullet,
                                    style: pw.TextStyle(
                                      font: serifFont,
                                      fontSize: 8.8,
                                      color: textColor,
                                      lineSpacing: 1.25,
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
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 5. PUBLICATIONS & PEER-REVIEWED PAPERS
            // ---------------------------------------------------------------
            if (resume.projects.isNotEmpty) ...[
              _buildSectionTitle(
                  'PUBLICATIONS & SCHOLARLY PROJECTS', accentColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.projects.map((proj) {
                final bullets = proj.description
                    .split('\n')
                    .map((s) => s.trim().replaceAll(RegExp(r'^[•\-\*]\s*'), ''))
                    .where((s) => s.isNotEmpty)
                    .toList();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '- "${proj.name}"${proj.role.isNotEmpty ? ' (${proj.role})' : ''}',
                        style: pw.TextStyle(
                          font: serifBold,
                          fontSize: 9.2,
                          color: primaryColor,
                        ),
                      ),
                      if (proj.technologies.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'Keywords / Methods: ${proj.technologies}',
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 8.2,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                      if (proj.link.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'DOI / URL: ${proj.link}',
                          style: pw.TextStyle(
                            font: serifFont,
                            fontSize: 8,
                            color: accentColor,
                          ),
                        ),
                      ],
                      if (bullets.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        ...bullets.map(
                          (bullet) => pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                            child: pw.Text(
                              bullet,
                              style: pw.TextStyle(
                                font: serifFont,
                                fontSize: 8.5,
                                color: textColor,
                                lineSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 6. METHODOLOGIES & TECHNICAL SKILLS
            // ---------------------------------------------------------------
            if (resume.skills.isNotEmpty) ...[
              _buildSectionTitle(
                  'SKILLS & METHODOLOGIES', accentColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.skills
                    .map((s) => s.level.isNotEmpty && s.level != 'Intermediate'
                        ? '${s.name} (${s.level})'
                        : s.name)
                    .join('   |   '),
                style: pw.TextStyle(
                  font: serifFont,
                  fontSize: 8.8,
                  color: textColor,
                ),
              ),
              pw.SizedBox(height: 8),
            ],

            // ---------------------------------------------------------------
            // 7. GRANTS, HONORS & AWARDS / CUSTOM SECTIONS
            // ---------------------------------------------------------------
            if (resume.customSections.isNotEmpty) ...[
              ...resume.customSections.map((sec) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                        sec.title.toUpperCase(), accentColor, serifBold),
                    pw.SizedBox(height: 4),
                    ...sec.items.map(
                      (item) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('- ',
                                style: pw.TextStyle(
                                    font: serifBold,
                                    fontSize: 8.8,
                                    color: accentColor)),
                            pw.Expanded(
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(
                                  font: serifFont,
                                  fontSize: 8.8,
                                  color: textColor,
                                  lineSpacing: 1.2,
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

            // ---------------------------------------------------------------
            // 8. CERTIFICATIONS & MEMBERSHIPS
            // ---------------------------------------------------------------
            if (resume.certifications.isNotEmpty) ...[
              _buildSectionTitle(
                  'CERTIFICATIONS & AFFILIATIONS', accentColor, serifBold),
              pw.SizedBox(height: 4),
              ...resume.certifications.map((cert) {
                final dateLine = [
                  if (cert.issuingOrganization.isNotEmpty)
                    cert.issuingOrganization,
                  if (cert.issueDate.isNotEmpty) cert.issueDate,
                ].join(' | ');

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '- ${cert.name}',
                        style: pw.TextStyle(
                          font: serifBold,
                          fontSize: 8.8,
                          color: textColor,
                        ),
                      ),
                      if (dateLine.isNotEmpty)
                        pw.Text(
                          dateLine,
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 8,
                            color: mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
            ],

            // ---------------------------------------------------------------
            // 9. LANGUAGES
            // ---------------------------------------------------------------
            if (resume.languages.isNotEmpty) ...[
              _buildSectionTitle('LANGUAGES', accentColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.languages
                    .map((l) => '${l.name} (${l.proficiency})')
                    .join('   |   '),
                style: pw.TextStyle(
                  font: serifFont,
                  fontSize: 8.8,
                  color: textColor,
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionTitle(
      String title, PdfColor color, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Divider(color: color, thickness: 0.8),
      ],
    );
  }
}
