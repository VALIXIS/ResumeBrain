import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
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
  Future<pw.Document> generatePdf(Resume resume, PdfPageFormat pageFormat) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#0F172A'); // Dark Navy
    final accentColor = PdfColor.fromHex('#2563EB'); // Royal Blue
    final textColor = PdfColor.fromHex('#334155');
    final mutedTextColor = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
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
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Text(
                    [
                      if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
                      if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
                      if (resume.personalInfo.location.isNotEmpty) resume.personalInfo.location,
                      if (resume.personalInfo.website.isNotEmpty) resume.personalInfo.website,
                    ].join('   |   '),
                    style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 12),

            // Summary
            if (resume.summary.summaryText.isNotEmpty) ...[
              _buildHeader('EXECUTIVE SUMMARY', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.summary.summaryText,
                style: pw.TextStyle(fontSize: 9.5, color: textColor),
              ),
              pw.SizedBox(height: 14),
            ],

            // Experience
            if (resume.experiences.isNotEmpty) ...[
              _buildHeader('EXPERIENCE & ACHIEVEMENTS', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.experiences.map((exp) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            exp.position,
                            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.Text(
                            '${exp.startDate} – ${exp.isCurrent ? 'Present' : exp.endDate}',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: mutedTextColor),
                          ),
                        ],
                      ),
                      pw.Text(
                        '${exp.company}${exp.location.isNotEmpty ? " • ${exp.location}" : ""}',
                        style: pw.TextStyle(fontSize: 9, color: accentColor),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          exp.description,
                          style: pw.TextStyle(fontSize: 9, color: textColor),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Education
            if (resume.educationList.isNotEmpty) ...[
              _buildHeader('EDUCATION', primaryColor),
              pw.SizedBox(height: 6),
              ...resume.educationList.map((edu) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${edu.degree} in ${edu.fieldOfStudy} (${edu.institution})',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textColor),
                      ),
                      pw.Text(
                        '${edu.startDate} – ${edu.endDate}',
                        style: pw.TextStyle(fontSize: 8.5, color: mutedTextColor),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
            ],

            // Core Competencies
            if (resume.skills.isNotEmpty) ...[
              _buildHeader('CORE COMPETENCIES', primaryColor),
              pw.SizedBox(height: 4),
              pw.Text(
                resume.skills.map((s) => s.name).join('   •   '),
                style: pw.TextStyle(fontSize: 9, color: textColor),
              ),
              pw.SizedBox(height: 14),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
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
        pw.SizedBox(height: 2),
      ],
    );
  }
}
