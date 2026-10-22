import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../models/resume_template.dart';

/// Executive Minimal Template
///
/// Refined classic serif typography, elegant horizontal dividing rules,
/// and normalized margins tailored for senior leaders, executives, and directors.
/// Guaranteed 100% ATS score with structured semantic vector text.
class ExecutiveMinimalTemplate implements ResumeTemplate {
  final PdfColor? customAccentColor;

  ExecutiveMinimalTemplate({this.customAccentColor});

  @override
  String get id => 'executive_minimal';

  @override
  String get name => 'Executive Minimal';

  @override
  String get description =>
      'Refined classic serif typography, elegant horizontal dividing rules, and high-density margins tailored for senior leaders and executives.';

  @override
  String get previewThumbnail => 'assets/templates/executive_minimal.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);

    // Predefined Executive Color Palette
    final palette = config?.colorPalette.executivePalette;
    final primaryColor = palette?.primary ?? PdfColor.fromHex('#0F172A'); // Rich Charcoal / Slate 900
    final accentColor = palette?.accent ??
        customAccentColor ??
        PdfColor.fromHex('#1E3A8A'); // Deep Executive Navy / Blue 900
    final textColor = palette?.text ?? PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = palette?.mutedText ?? PdfColor.fromHex('#475569'); // Slate 600
    final dividerColor = palette?.divider ?? PdfColor.fromHex('#94A3B8'); // Slate 400

    final serifFont = pw.Font.times();
    final serifBold = pw.Font.timesBold();
    final serifItalic = pw.Font.timesItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ??
            const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
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
                  resume.personalInfo.fullName.isNotEmpty
                      ? resume.personalInfo.fullName
                      : 'Executive Resume',
                  style: pw.TextStyle(
                    font: serifItalic,
                    fontSize: 8.5,
                    color: mutedTextColor,
                  ),
                ),
                if (config?.showPageNumbers ?? true)
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: serifFont,
                      fontSize: 8.5,
                      color: mutedTextColor,
                    ),
                  )
                else
                  pw.SizedBox.shrink(),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final isTextContact = config?.contactIconStyle == PdfContactIconStyle.text;
          final contactItems = [
            if (resume.personalInfo.email.isNotEmpty)
              isTextContact ? 'Email: ${resume.personalInfo.email}' : resume.personalInfo.email,
            if (resume.personalInfo.phone.isNotEmpty)
              isTextContact ? 'Phone: ${resume.personalInfo.phone}' : resume.personalInfo.phone,
            if (resume.personalInfo.location.isNotEmpty)
              isTextContact ? 'Location: ${resume.personalInfo.location}' : resume.personalInfo.location,
            if (resume.personalInfo.website.isNotEmpty)
              isTextContact ? 'Website: ${resume.personalInfo.website}' : resume.personalInfo.website,
            ...resume.socialLinks
                .where((s) => s.url.isNotEmpty)
                .map((s) => '${s.platform}: ${s.url}'),
          ];

          return [
            // ---------------------------------------------------------------
            // 1. EXECUTIVE HEADER (High Density, Centered Serif)
            // ---------------------------------------------------------------
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    (resume.personalInfo.fullName.isNotEmpty
                            ? resume.personalInfo.fullName
                            : 'YOUR FULL NAME')
                        .toUpperCase(),
                    style: pw.TextStyle(
                      font: serifBold,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.8,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      resume.personalInfo.jobTitle.toUpperCase(),
                      style: pw.TextStyle(
                        font: serifBold,
                        fontSize: 10.5,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                  if (contactItems.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      contactItems.join('   |   '),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: serifFont,
                        fontSize: 9.5,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: primaryColor, thickness: 1.2),
            pw.SizedBox(height: 6),

            // ---------------------------------------------------------------
            // 2. EXECUTIVE SUMMARY
            // ---------------------------------------------------------------
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionHeader('EXECUTIVE SUMMARY', primaryColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(
                  font: serifFont,
                  fontSize: 9.5,
                  color: textColor,
                  lineSpacing: 1.35,
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // ---------------------------------------------------------------
            // 3. CORE LEADERSHIP & EXECUTIVE COMPETENCIES
            // ---------------------------------------------------------------
            if (resume.skills.isNotEmpty) ...[
              _buildSectionHeader(
                  'EXECUTIVE COMPETENCIES', primaryColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 12,
                runSpacing: 4,
                children: resume.skills.map((skill) {
                  return pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 3.5,
                        height: 3.5,
                        margin: const pw.EdgeInsets.only(right: 4),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Text(
                        skill.name,
                        style: pw.TextStyle(
                          font: serifBold,
                          fontSize: 9.5,
                          color: textColor,
                        ),
                      ),
                      if (skill.level.isNotEmpty &&
                          skill.level != 'Intermediate') ...[
                        pw.Text(
                          ' (${skill.level})',
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 9.5,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 10),
            ],

            // ---------------------------------------------------------------
            // 4. PROFESSIONAL EXPERIENCE & ACHIEVEMENTS
            // ---------------------------------------------------------------
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionHeader(
                  'PROFESSIONAL EXPERIENCE', primaryColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                final dateRange = PdfExportConfig.formatDateRange(
                  startDate: exp.startDate,
                  endDate: exp.endDate,
                  isCurrent: exp.isCurrent,
                  format: config?.dateFormat ?? PdfDateFormat.monthYear,
                );

                final companyLine = [
                  exp.company,
                  if (exp.location.isNotEmpty) exp.location,
                ].where((s) => s.isNotEmpty).join(', ');

                final bullets = exp.description
                    .split('\n')
                    .map((s) => s.trim().replaceAll(RegExp(r'^[•\-\*]\s*'), ''))
                    .where((s) => s.isNotEmpty)
                    .toList();

                return pw.Wrap(
                  children: [
                    pw.ConstrainedBox(
                      constraints: const pw.BoxConstraints(minWidth: double.infinity),
                      child: pw.Container(
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
                                        : 'Executive Role',
                                    style: pw.TextStyle(
                                      font: serifBold,
                                      fontSize: 10.5,
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
                                      fontSize: 9.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (companyLine.isNotEmpty) ...[
                              pw.SizedBox(height: 1.5),
                              pw.Text(
                                companyLine,
                                style: pw.TextStyle(
                                  font: serifItalic,
                                  fontSize: 9.5,
                                  color: accentColor,
                                ),
                              ),
                            ],
                            if (bullets.isNotEmpty) ...[
                              pw.SizedBox(height: 3),
                              ...bullets.map(
                                (bullet) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 6, bottom: 2, top: 1),
                                  child: pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        '- ',
                                        style: pw.TextStyle(
                                          font: serifBold,
                                          fontSize: 9.5,
                                          color: accentColor,
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          bullet,
                                          style: pw.TextStyle(
                                            font: serifFont,
                                            fontSize: 9.5,
                                            color: textColor,
                                            lineSpacing: 1.35,
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
                      ),
                    ),
                  ],
                );
              }),
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 5. KEY INITIATIVES & PROJECTS
            // ---------------------------------------------------------------
            if (resume.projects.isNotEmpty) ...[
              _buildSectionHeader(
                  'EXECUTIVE PROJECTS & STRATEGIC INITIATIVES',
                  primaryColor,
                  serifBold),
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            proj.name,
                            style: pw.TextStyle(
                              font: serifBold,
                              fontSize: 10,
                              color: primaryColor,
                            ),
                          ),
                          if (proj.role.isNotEmpty)
                            pw.Text(
                              proj.role,
                              style: pw.TextStyle(
                                font: serifItalic,
                                fontSize: 9.5,
                                color: accentColor,
                              ),
                            ),
                        ],
                      ),
                      if (bullets.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        ...bullets.map(
                          (bullet) => pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('- ',
                                    style: pw.TextStyle(
                                        font: serifBold,
                                        fontSize: 9.5,
                                        color: accentColor)),
                                pw.Expanded(
                                  child: pw.Text(
                                    bullet,
                                    style: pw.TextStyle(
                                      font: serifFont,
                                      fontSize: 9.5,
                                      color: textColor,
                                      lineSpacing: 1.35,
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
            // 6. EDUCATION & CREDENTIALS
            // ---------------------------------------------------------------
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionHeader('EDUCATION', primaryColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                final dateRange = PdfExportConfig.formatDateRange(
                  startDate: edu.startDate,
                  endDate: edu.endDate,
                  format: config?.dateFormat ?? PdfDateFormat.monthYear,
                );

                final degreeDetails = [
                  if (edu.degree.isNotEmpty) edu.degree,
                  if (edu.fieldOfStudy.isNotEmpty) 'in ${edu.fieldOfStudy}',
                ].join(' ');

                return pw.Wrap(
                  children: [
                    pw.ConstrainedBox(
                      constraints: const pw.BoxConstraints(minWidth: double.infinity),
                      child: pw.Container(
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
                                    edu.institution,
                                    style: pw.TextStyle(
                                      font: serifBold,
                                      fontSize: 10.5,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (degreeDetails.isNotEmpty) ...[
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      degreeDetails,
                                      style: pw.TextStyle(
                                        font: serifFont,
                                        fontSize: 9.5,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                  if (edu.gpa.isNotEmpty) ...[
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      'Honors / GPA: ${edu.gpa}',
                                      style: pw.TextStyle(
                                        font: serifItalic,
                                        fontSize: 9.5,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (dateRange.isNotEmpty)
                              pw.Text(
                                dateRange,
                                style: pw.TextStyle(
                                  font: serifBold,
                                  fontSize: 9.5,
                                  color: mutedTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 7. CERTIFICATIONS & BOARD GOVERNANCE
            // ---------------------------------------------------------------
            if (resume.certifications.isNotEmpty) ...[
              _buildSectionHeader(
                  'CERTIFICATIONS & GOVERNANCE', primaryColor, serifBold),
              pw.SizedBox(height: 6),
              ...resume.certifications.map((cert) {
                final dateLine = [
                  if (cert.issuingOrganization.isNotEmpty)
                    cert.issuingOrganization,
                  if (cert.issueDate.isNotEmpty) cert.issueDate,
                ].join(' | ');

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        cert.name,
                        style: pw.TextStyle(
                          font: serifBold,
                          fontSize: 9.5,
                          color: primaryColor,
                        ),
                      ),
                      if (dateLine.isNotEmpty)
                        pw.Text(
                          dateLine,
                          style: pw.TextStyle(
                            font: serifItalic,
                            fontSize: 9.5,
                            color: mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 4),
            ],

            // ---------------------------------------------------------------
            // 8. LANGUAGES
            // ---------------------------------------------------------------
            if (resume.languages.isNotEmpty) ...[
              _buildSectionHeader('LANGUAGES', primaryColor, serifBold),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.languages
                    .map((l) => '${l.name} (${l.proficiency})')
                    .join('   |   '),
                style: pw.TextStyle(
                  font: serifFont,
                  fontSize: 9.5,
                  color: textColor,
                ),
              ),
              pw.SizedBox(height: 6),
            ],

            // ---------------------------------------------------------------
            // 9. CUSTOM SECTIONS (Honors, Publications, Advisory)
            // ---------------------------------------------------------------
            if (resume.customSections.isNotEmpty) ...[
              ...resume.customSections.map((sec) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(sec.title.toUpperCase(), primaryColor, serifBold),
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
                                    fontSize: 9.5,
                                    color: accentColor)),
                            pw.Expanded(
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(
                                  font: serifFont,
                                  fontSize: 9.5,
                                  color: textColor,
                                  lineSpacing: 1.35,
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
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionHeader(
      String title, PdfColor color, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Divider(color: color, thickness: 0.75),
      ],
    );
  }
}
