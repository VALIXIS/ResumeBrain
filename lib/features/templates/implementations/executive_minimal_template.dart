import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../models/resume_template.dart';

class ExecutiveMinimalTemplate implements ResumeTemplate {
  @override
  String get id => 'executive_minimal';

  @override
  String get name => 'Executive Minimal';

  @override
  String get description => 'Sleek, minimalist design tailored for senior leaders and executives with emphasis on achievements.';

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
    final primaryColor = PdfColor.fromHex('#0F172A'); // Dark Navy
    final accentColor = config?.colorPalette.pdfColor ?? PdfColor.fromHex('#2563EB'); // Royal Blue
    final textColor = PdfColor.fromHex('#334155');
    final mutedTextColor = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ?? const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
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
          final contactList = [
            if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
            if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
            if (resume.personalInfo.location.isNotEmpty) resume.personalInfo.location,
            if (resume.personalInfo.website.isNotEmpty) resume.personalInfo.website,
          ];

          return [
            // Center Header
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    (resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : 'Your Full Name').toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      resume.personalInfo.jobTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                  if (contactList.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      contactList.join('   |   '),
                      style: pw.TextStyle(fontSize: 9, color: mutedTextColor),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 10),

            // Summary
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildHeader('EXECUTIVE SUMMARY', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(fontSize: 9.5, color: textColor, lineSpacing: 1.35),
              ),
              pw.SizedBox(height: 12),
            ],

            // Experience
            if (resume.experiences.isNotEmpty) ...[
              _buildHeader('EXPERIENCE & ACHIEVEMENTS', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                final dateRange = [
                  if (exp.startDate.isNotEmpty) exp.startDate,
                  if (exp.isCurrent) 'Present' else if (exp.endDate.isNotEmpty) exp.endDate,
                ].join(' - ');

                final companyText = [
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
                              exp.position.isNotEmpty ? exp.position : 'Position',
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          if (dateRange.isNotEmpty)
                            pw.Text(
                              dateRange,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: mutedTextColor),
                            ),
                        ],
                      ),
                      if (companyText.isNotEmpty) ...[
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          companyText,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accentColor),
                        ),
                      ],
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        ..._buildBulletPoints(exp.description, textColor, accentColor),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // Education
            if (resume.educationList.isNotEmpty) ...[
              _buildHeader('EDUCATION', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                final dateRange = [
                  if (edu.startDate.isNotEmpty) edu.startDate,
                  if (edu.endDate.isNotEmpty) edu.endDate,
                ].join(' - ');

                final title = edu.degree.isNotEmpty
                    ? (edu.fieldOfStudy.isNotEmpty ? '${edu.degree} in ${edu.fieldOfStudy}' : edu.degree)
                    : (edu.institution.isNotEmpty ? edu.institution : 'Degree');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '$title (${edu.institution})',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textColor),
                        ),
                      ),
                      if (dateRange.isNotEmpty)
                        pw.Text(
                          dateRange,
                          style: pw.TextStyle(fontSize: 9, color: mutedTextColor),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // Core Competencies
            if (resume.skills.isNotEmpty) ...[
              _buildHeader('CORE COMPETENCIES', primaryColor),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: resume.skills.map((s) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                    ),
                    child: pw.Text(
                      s.name,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
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
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
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
