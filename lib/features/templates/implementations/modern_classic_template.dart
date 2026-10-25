import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../models/resume_template.dart';

class ModernClassicTemplate implements ResumeTemplate {
  @override
  String get id => 'modern_classic';

  @override
  String get name => 'Modern Classic';

  @override
  String get description => 'Clean, professional ATS-optimized layout with indigo accents, sleek skill badges, and clear visual hierarchy.';

  @override
  String get previewThumbnail => 'assets/templates/modern_classic.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);
    final palette = config?.colorPalette.executivePalette;
    final primaryColor = palette?.accent ?? PdfColor.fromHex('#1E3A8A'); // Executive Navy 900
    final nameColor = palette?.primary ?? PdfColor.fromHex('#0F172A'); // Slate 900
    final textColor = palette?.text ?? PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = palette?.mutedText ?? PdfColor.fromHex('#475569'); // Slate 600
    final badgeBg = palette?.badgeBackground ?? PdfColor.fromHex('#F1F5F9');
    final badgeBorder = palette?.badgeBorder ?? PdfColor.fromHex('#CBD5E1');
    final badgeText = palette?.badgeText ?? PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ?? const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        footer: (pw.Context context) {
          if (!(config?.showPageNumbers ?? true)) {
            return pw.SizedBox.shrink();
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
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
            ...resume.socialLinks.map((link) => '${link.platform}: ${link.url}'),
          ];

          return [
            // -----------------------------------------------------------------
            // HEADER SECTION
            // -----------------------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: primaryColor, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : 'Your Full Name',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: nameColor,
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
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                  if (contactItems.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      contactItems.join('   |   '),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // -----------------------------------------------------------------
            // PROFESSIONAL SUMMARY
            // -----------------------------------------------------------------
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionHeader('PROFESSIONAL SUMMARY', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(fontSize: 9.5, color: textColor, lineSpacing: 1.35),
              ),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // SKILLS SECTION (PILL BADGES)
            // -----------------------------------------------------------------
            if (resume.skills.isNotEmpty) ...[
              _buildSectionHeader('KEY SKILLS & EXPERTISE', primaryColor),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: resume.skills.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: pw.BoxDecoration(
                      color: badgeBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: badgeBorder, width: 0.75),
                    ),
                    child: pw.Text(
                      skill.name,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 10),
            ],

            // -----------------------------------------------------------------
            // WORK EXPERIENCE
            // -----------------------------------------------------------------
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionHeader('WORK EXPERIENCE', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                final dateRange = PdfExportConfig.formatDateRange(
                  startDate: exp.startDate,
                  endDate: exp.endDate,
                  isCurrent: exp.isCurrent,
                  format: config?.dateFormat ?? PdfDateFormat.monthYear,
                );

                final companyRow = [
                  exp.company,
                  if (exp.location.isNotEmpty) exp.location,
                ].where((s) => s.isNotEmpty).join('  |  ');

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
                              exp.position.isNotEmpty ? exp.position : 'Role / Position',
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: textColor),
                            ),
                          ),
                          if (dateRange.isNotEmpty)
                            pw.Text(
                              dateRange,
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: mutedTextColor),
                            ),
                        ],
                      ),
                      if (companyRow.isNotEmpty) ...[
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          companyRow,
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                      ],
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        ..._buildBulletPoints(exp.description, textColor, primaryColor),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // EDUCATION
            // -----------------------------------------------------------------
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionHeader('EDUCATION', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                final dateRange = PdfExportConfig.formatDateRange(
                  startDate: edu.startDate,
                  endDate: edu.endDate,
                  format: config?.dateFormat ?? PdfDateFormat.monthYear,
                );

                final degreeTitle = edu.degree.isNotEmpty
                    ? (edu.fieldOfStudy.isNotEmpty ? '${edu.degree} in ${edu.fieldOfStudy}' : edu.degree)
                    : (edu.fieldOfStudy.isNotEmpty ? edu.fieldOfStudy : 'Degree / Program');

                final institutionRow = [
                  edu.institution,
                  if (edu.location.isNotEmpty) edu.location,
                ].where((s) => s.isNotEmpty).join('  |  ');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              degreeTitle,
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: textColor),
                            ),
                            if (institutionRow.isNotEmpty) ...[
                              pw.SizedBox(height: 1.5),
                              pw.Text(
                                institutionRow,
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                              ),
                            ],
                            if (edu.gpa.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text('GPA: ${edu.gpa}', style: pw.TextStyle(fontSize: 9.5, color: mutedTextColor)),
                            ],
                          ],
                        ),
                      ),
                      if (dateRange.isNotEmpty)
                        pw.Text(
                          dateRange,
                          style: pw.TextStyle(fontSize: 9.5, color: mutedTextColor),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // PROJECTS
            // -----------------------------------------------------------------
            if (resume.projects.isNotEmpty) ...[
              _buildSectionHeader('KEY PROJECTS', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.projects.map((proj) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        proj.name.isNotEmpty
                            ? (proj.role.isNotEmpty ? '${proj.name} (${proj.role})' : proj.name)
                            : 'Project',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                      ),
                      if (proj.technologies.isNotEmpty) ...[
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          'Technologies: ${proj.technologies}',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                      ],
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        ..._buildBulletPoints(proj.description, textColor, primaryColor),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // -----------------------------------------------------------------
            // CERTIFICATIONS & LANGUAGES
            // -----------------------------------------------------------------
            if (resume.certifications.isNotEmpty || resume.languages.isNotEmpty) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (resume.certifications.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('CERTIFICATIONS', primaryColor),
                          pw.SizedBox(height: 4),
                          ...resume.certifications.map(
                            (c) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(
                                '${c.name}${c.issuingOrganization.isNotEmpty ? " (${c.issuingOrganization})" : ""}',
                                style: pw.TextStyle(fontSize: 9.5, color: textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (resume.certifications.isNotEmpty && resume.languages.isNotEmpty)
                    pw.SizedBox(width: 16),
                  if (resume.languages.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('LANGUAGES', primaryColor),
                          pw.SizedBox(height: 4),
                          ...resume.languages.map(
                            (l) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(
                                '${l.name}${l.proficiency.isNotEmpty ? " - ${l.proficiency}" : ""}',
                                style: pw.TextStyle(fontSize: 9.5, color: textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: color, width: 1.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildBulletPoints(String text, PdfColor textColor, PdfColor bulletColor) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length <= 1 && !text.contains('- ') && !text.contains('* ')) {
      return [
        pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9.5, color: textColor, lineSpacing: 1.3),
        ),
      ];
    }
    return lines.map((line) {
      final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 3.5,
              height: 3.5,
              margin: const pw.EdgeInsets.only(top: 4.5, right: 6),
              decoration: pw.BoxDecoration(
                color: bulletColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                cleanLine,
                style: pw.TextStyle(fontSize: 9.5, color: textColor, lineSpacing: 1.3),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
