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
  String get description => 'Clean, professional ATS-optimized layout with indigo accents and clear section hierarchy.';

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
    final primaryColor = config?.colorPalette.pdfColor ?? PdfColor.fromHex('#4F46E5');
    final textColor = PdfColor.fromHex('#1E293B');
    final mutedTextColor = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ?? const pw.EdgeInsets.all(36),
        footer: (pw.Context context) {
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
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : 'Your Full Name',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      resume.personalInfo.jobTitle,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (resume.personalInfo.email.isNotEmpty)
                        pw.Text(resume.personalInfo.email, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      if (resume.personalInfo.phone.isNotEmpty)
                        pw.Text(resume.personalInfo.phone, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      if (resume.personalInfo.location.isNotEmpty)
                        pw.Text(resume.personalInfo.location, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      if (resume.personalInfo.website.isNotEmpty)
                        pw.Text(resume.personalInfo.website, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      ...resume.socialLinks.map(
                        (link) => pw.Text('${link.platform}: ${link.url}', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Professional Summary
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildSectionHeader('PROFESSIONAL SUMMARY', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(fontSize: 10, color: textColor),
              ),
              pw.SizedBox(height: 12),
            ],

            // Work Experience
            if (resume.experiences.isNotEmpty) ...[
              _buildSectionHeader('PROFESSIONAL EXPERIENCE', primaryColor),
              pw.SizedBox(height: 4),
              ...resume.experiences.map((exp) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            exp.position,
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textColor),
                          ),
                          pw.Text(
                            '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                            style: pw.TextStyle(fontSize: 9, color: mutedTextColor),
                          ),
                        ],
                      ),
                      pw.Text(
                        '${exp.company}${exp.location.isNotEmpty ? " • ${exp.location}" : ""}',
                        style: pw.TextStyle(fontSize: 9.5, color: primaryColor),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          exp.description,
                          style: pw.TextStyle(fontSize: 9.5, color: textColor),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // Education
            if (resume.educationList.isNotEmpty) ...[
              _buildSectionHeader('EDUCATION', primaryColor),
              pw.SizedBox(height: 4),
              ...resume.educationList.map((edu) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? " in ${edu.fieldOfStudy}" : ""}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                          ),
                          pw.Text(
                            '${edu.institution}${edu.location.isNotEmpty ? " • ${edu.location}" : ""}',
                            style: pw.TextStyle(fontSize: 9, color: mutedTextColor),
                          ),
                        ],
                      ),
                      pw.Text(
                        '${edu.startDate} - ${edu.endDate}',
                        style: pw.TextStyle(fontSize: 9, color: mutedTextColor),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // Skills
            if (resume.skills.isNotEmpty) ...[
              _buildSectionHeader('SKILLS', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.skills.map((s) => '${s.name} (${s.level})').join(' • '),
                style: pw.TextStyle(fontSize: 9.5, color: textColor),
              ),
              pw.SizedBox(height: 12),
            ],

            // Projects
            if (resume.projects.isNotEmpty) ...[
              _buildSectionHeader('PROJECTS', primaryColor),
              pw.SizedBox(height: 4),
              ...resume.projects.map((proj) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${proj.name}${proj.role.isNotEmpty ? " — ${proj.role}" : ""}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                      ),
                      if (proj.description.isNotEmpty)
                        pw.Text(proj.description, style: pw.TextStyle(fontSize: 9, color: textColor)),
                      if (proj.technologies.isNotEmpty)
                        pw.Text('Technologies: ${proj.technologies}', style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor)),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // Certifications & Languages
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
                            (c) => pw.Text('${c.name} - ${c.issuingOrganization}', style: pw.TextStyle(fontSize: 9, color: textColor)),
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
                            (l) => pw.Text('${l.name} (${l.proficiency})', style: pw.TextStyle(fontSize: 9, color: textColor)),
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1,
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
