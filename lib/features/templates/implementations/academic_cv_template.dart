import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../models/resume_template.dart';

class AcademicCvTemplate implements ResumeTemplate {
  @override
  String get id => 'academic_cv';

  @override
  String get name => 'Academic CV';

  @override
  String get description =>
      'Formal academic and research CV layout with clear section hierarchy, publication listing, and dynamic pagination.';

  @override
  String get previewThumbnail => 'assets/templates/academic_cv.png';

  @override
  bool get isAtsFriendly => true;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);

    final primaryColor = PdfColor.fromHex('#1B2A4A'); // Deep Navy Blue
    final accentColor = config?.colorPalette.pdfColor ?? PdfColor.fromHex('#800020'); // Burgundy Accent
    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = PdfColor.fromHex('#64748B'); // Slate 500
    final dividerColor = PdfColor.fromHex('#CBD5E1'); // Slate 300

    final candidateName = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : 'Your Full Name';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ?? const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: dividerColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  candidateName,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Curriculum Vitae',
                  style: pw.TextStyle(
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
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: dividerColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  candidateName,
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
            // Candidate Header (Page 1 Top)
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    candidateName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      resume.personalInfo.jobTitle,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (resume.personalInfo.email.isNotEmpty)
                        pw.Text(
                          resume.personalInfo.email,
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      if (resume.personalInfo.phone.isNotEmpty)
                        pw.Text(
                          resume.personalInfo.phone,
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      if (resume.personalInfo.location.isNotEmpty)
                        pw.Text(
                          resume.personalInfo.location,
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      if (resume.personalInfo.website.isNotEmpty)
                        pw.Text(
                          resume.personalInfo.website,
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      ...resume.socialLinks.map(
                        (link) => pw.Text(
                          '${link.platform}: ${link.url}',
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(height: 1, color: primaryColor),
            pw.SizedBox(height: 12),

            // Profile / Summary
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionHeader('ACADEMIC PROFILE', accentColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(fontSize: 9.5, color: textColor, lineSpacing: 2),
              ),
              pw.SizedBox(height: 12),
            ],

            // Education (Prioritized in Academic CVs)
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionHeader('EDUCATION', accentColor),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? " in ${edu.fieldOfStudy}" : ""}',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                            ),
                            pw.Text(
                              '${edu.institution}${edu.location.isNotEmpty ? " | ${edu.location}" : ""}',
                              style: pw.TextStyle(fontSize: 9, color: primaryColor),
                            ),
                            if (edu.gpa.isNotEmpty)
                              pw.Text(
                                'GPA: ${edu.gpa}',
                                style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
                              ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        '${edu.startDate}${edu.endDate.isNotEmpty ? " - ${edu.endDate}" : ""}',
                        style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Academic & Professional Experience
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionHeader('ACADEMIC & PROFESSIONAL APPOINTMENTS', accentColor),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  exp.position,
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: textColor),
                                ),
                                pw.Text(
                                  '${exp.company}${exp.location.isNotEmpty ? " | ${exp.location}" : ""}',
                                  style: pw.TextStyle(fontSize: 9, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Text(
                            '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: mutedTextColor),
                          ),
                        ],
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          exp.description,
                          style: pw.TextStyle(fontSize: 9, color: textColor, lineSpacing: 1.5),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Research Projects & Initiatives
            if (resume.projects.isNotEmpty) ...[
              _buildSectionHeader('RESEARCH PROJECTS & INITIATIVES', accentColor),
              pw.SizedBox(height: 6),
              ...resume.projects.map((proj) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${proj.name}${proj.role.isNotEmpty ? " - ${proj.role}" : ""}',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                            ),
                          ),
                          if (proj.link.isNotEmpty) ...[
                            pw.SizedBox(width: 8),
                            pw.Text(
                              proj.link,
                              style: pw.TextStyle(fontSize: 8, color: accentColor),
                            ),
                          ],
                        ],
                      ),
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          proj.description,
                          style: pw.TextStyle(fontSize: 8.5, color: textColor),
                        ),
                      ],
                      if (proj.technologies.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Methodology/Tools: ${proj.technologies}',
                          style: pw.TextStyle(fontSize: 8, color: mutedTextColor),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Custom Sections (Publications, Teaching, Awards, Conferences, References, etc.)
            ...resume.customSections.map((section) {
              if (section.title.trim().isEmpty || section.items.isEmpty) return pw.SizedBox();
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(section.title.toUpperCase(), accentColor),
                    pw.SizedBox(height: 4),
                    ...section.items.map((item) {
                      if (item.trim().isEmpty) return pw.SizedBox();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('- ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accentColor)),
                            pw.Expanded(
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(fontSize: 9, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            // Skills & Areas of Expertise
            if (resume.skills.isNotEmpty) ...[
              _buildSectionHeader('SKILLS & AREAS OF EXPERTISE', accentColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.skills.map((s) => '${s.name}${s.level.isNotEmpty ? " (${s.level})" : ""}').join('  |  '),
                style: pw.TextStyle(fontSize: 9, color: textColor),
              ),
              pw.SizedBox(height: 10),
            ],

            // Certifications & Honors
            if (resume.certifications.isNotEmpty) ...[
              _buildSectionHeader('CERTIFICATIONS & HONORS', accentColor),
              pw.SizedBox(height: 4),
              ...resume.certifications.map((cert) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${cert.name}${cert.issuingOrganization.isNotEmpty ? " - ${cert.issuingOrganization}" : ""}',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textColor),
                        ),
                      ),
                      if (cert.issueDate.isNotEmpty)
                        pw.Text(
                          cert.issueDate,
                          style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Languages
            if (resume.languages.isNotEmpty) ...[
              _buildSectionHeader('LANGUAGES', accentColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.languages.map((l) => '${l.name} (${l.proficiency})').join('  |  '),
                style: pw.TextStyle(fontSize: 9, color: textColor),
              ),
              pw.SizedBox(height: 10),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 1,
          color: color,
        ),
      ],
    );
  }
}
