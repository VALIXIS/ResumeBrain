import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../models/resume_template.dart';

class CreativeProfessionalTemplate implements ResumeTemplate {
  final PdfColor? customAccentColor;

  CreativeProfessionalTemplate({this.customAccentColor});

  @override
  String get id => 'creative_professional';

  @override
  String get name => 'Creative Professional';

  @override
  String get description =>
      'Stylish two-column layout with a visually distinctive sidebar for skills, contact info, and metadata.';

  @override
  String get previewThumbnail => 'assets/templates/creative_professional.png';

  @override
  bool get isAtsFriendly => false;

  @override
  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  }) async {
    final pdf = pw.Document(theme: config?.themeData);

    final palette = config?.colorPalette.executivePalette;
    final accentColor = palette?.accent ?? customAccentColor ?? PdfColor.fromHex('#115E59'); // Deep Teal Accent
    final primaryTextColor = palette?.primary ?? PdfColor.fromHex('#0F172A'); // Slate 900
    final bodyTextColor = palette?.text ?? PdfColor.fromHex('#1E293B'); // Slate 800
    final mutedTextColor = palette?.mutedText ?? PdfColor.fromHex('#475569'); // Slate 600
    final dividerColor = palette?.divider ?? PdfColor.fromHex('#CBD5E1'); // Slate 300

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: config?.marginOption.insets ??
            const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        footer: (pw.Context context) {
          if (!(config?.showPageNumbers ?? true)) {
            return pw.SizedBox.shrink();
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9.5, color: mutedTextColor),
            ),
          );
        },
        build: (pw.Context context) {
          final contactStyle = config?.contactIconStyle ?? PdfContactIconStyle.icon;

          return [
            pw.Partitions(
              children: [
                // -------------------------------------------------------------
                // LEFT SIDEBAR PARTITION (~32% width)
                // -------------------------------------------------------------
                pw.Partition(
                  width: 170,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(right: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Decorative Accent Bar
                        pw.Container(
                          height: 4,
                          width: 40,
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        // Contact Information Section
                        _buildSidebarSectionHeader('CONTACT', accentColor),
                        pw.SizedBox(height: 6),
                        if (resume.personalInfo.email.isNotEmpty)
                          _buildSidebarContactItem('Email', resume.personalInfo.email, bodyTextColor, mutedTextColor, style: contactStyle),
                        if (resume.personalInfo.phone.isNotEmpty)
                          _buildSidebarContactItem('Phone', resume.personalInfo.phone, bodyTextColor, mutedTextColor, style: contactStyle),
                        if (resume.personalInfo.location.isNotEmpty)
                          _buildSidebarContactItem('Location', resume.personalInfo.location, bodyTextColor, mutedTextColor, style: contactStyle),
                        if (resume.personalInfo.website.isNotEmpty)
                          _buildSidebarContactItem('Website', resume.personalInfo.website, bodyTextColor, mutedTextColor, style: contactStyle),
                        ...resume.socialLinks.map(
                          (link) => _buildSidebarContactItem(
                            link.platform,
                            link.url,
                            bodyTextColor,
                            mutedTextColor,
                            style: contactStyle,
                          ),
                        ),
                        pw.SizedBox(height: 14),

                        // Skills Section
                        if (resume.skills.isNotEmpty) ...[
                          _buildSidebarSectionHeader('SKILLS', accentColor),
                          pw.SizedBox(height: 6),
                          ...resume.skills.map((skill) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    skill.name,
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: bodyTextColor,
                                    ),
                                  ),
                                  if (skill.level.isNotEmpty)
                                    pw.Text(
                                      skill.level,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          pw.SizedBox(height: 14),
                        ],

                        // Languages Section
                        if (resume.languages.isNotEmpty) ...[
                          _buildSidebarSectionHeader('LANGUAGES', accentColor),
                          pw.SizedBox(height: 6),
                          ...resume.languages.map((lang) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      lang.name,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: bodyTextColor,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    lang.proficiency,
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          pw.SizedBox(height: 14),
                        ],

                        // Certifications Section (Sidebar compact view if present)
                        if (resume.certifications.isNotEmpty) ...[
                          _buildSidebarSectionHeader('CERTIFICATIONS', accentColor),
                          pw.SizedBox(height: 6),
                          ...resume.certifications.map((cert) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    cert.name,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: bodyTextColor,
                                    ),
                                  ),
                                  if (cert.issuingOrganization.isNotEmpty)
                                    pw.Text(
                                      cert.issuingOrganization,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                // -------------------------------------------------------------
                // MAIN CONTENT PARTITION (Remaining width)
                // -------------------------------------------------------------
                pw.Partition(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Name & Title Header
                        pw.Text(
                          resume.personalInfo.fullName.isNotEmpty
                              ? resume.personalInfo.fullName
                              : 'Your Full Name',
                          style: pw.TextStyle(
                            fontSize: 21,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (resume.personalInfo.jobTitle.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            resume.personalInfo.jobTitle,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 12),
                        pw.Container(
                          height: 1,
                          color: dividerColor,
                        ),
                        pw.SizedBox(height: 14),

                        // Professional Summary
                        if (resume.summary.summaryText.isNotEmpty) ...[
                          _buildMainSectionHeader('PROFILE SUMMARY', accentColor, primaryTextColor),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            resume.summary.summaryText,
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: bodyTextColor,
                              lineSpacing: 1.35,
                            ),
                          ),
                          pw.SizedBox(height: 16),
                        ],

                        // Experience Section
                        if (resume.experiences.isNotEmpty) ...[
                          _buildMainSectionHeader('PROFESSIONAL EXPERIENCE', accentColor, primaryTextColor),
                          pw.SizedBox(height: 8),
                          ...resume.experiences.map((exp) {
                            return pw.Wrap(
                              children: [
                                pw.ConstrainedBox(
                                  constraints: const pw.BoxConstraints(minWidth: double.infinity),
                                  child: pw.Container(
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
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            pw.Text(
                                              PdfExportConfig.formatDateRange(
                                                startDate: exp.startDate,
                                                endDate: exp.endDate,
                                                isCurrent: exp.isCurrent,
                                                format: config?.dateFormat ?? PdfDateFormat.monthYear,
                                              ),
                                              style: pw.TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: pw.FontWeight.bold,
                                                color: mutedTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          '${exp.company}${exp.location.isNotEmpty ? " | ${exp.location}" : ""}',
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                        if (exp.description.isNotEmpty) ...[
                                          pw.SizedBox(height: 4),
                                          pw.Text(
                                            exp.description,
                                            style: pw.TextStyle(
                                              fontSize: 9.5,
                                              color: bodyTextColor,
                                              lineSpacing: 1.35,
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
                          pw.SizedBox(height: 12),
                        ],

                        // Education Section
                        if (resume.educationList.isNotEmpty) ...[
                          _buildMainSectionHeader('EDUCATION', accentColor, primaryTextColor),
                          pw.SizedBox(height: 8),
                          ...resume.educationList.map((edu) {
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
                                          children: [
                                            pw.Expanded(
                                              child: pw.Text(
                                                '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? " in ${edu.fieldOfStudy}" : ""}',
                                                style: pw.TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            pw.Text(
                                              PdfExportConfig.formatDateRange(
                                                startDate: edu.startDate,
                                                endDate: edu.endDate,
                                                format: config?.dateFormat ?? PdfDateFormat.monthYear,
                                              ),
                                              style: pw.TextStyle(
                                                fontSize: 9.5,
                                                color: mutedTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          '${edu.institution}${edu.location.isNotEmpty ? " | ${edu.location}" : ""}',
                                          style: pw.TextStyle(
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
                          pw.SizedBox(height: 12),
                        ],

                        // Projects Section
                        if (resume.projects.isNotEmpty) ...[
                          _buildMainSectionHeader('PROJECTS', accentColor, primaryTextColor),
                          pw.SizedBox(height: 8),
                          ...resume.projects.map((proj) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          '${proj.name}${proj.role.isNotEmpty ? " - ${proj.role}" : ""}',
                                          style: pw.TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ),
                                      if (proj.link.isNotEmpty)
                                        pw.Text(
                                          proj.link,
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            color: accentColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (proj.description.isNotEmpty) ...[
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      proj.description,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        color: bodyTextColor,
                                        lineSpacing: 1.35,
                                      ),
                                    ),
                                  ],
                                  if (proj.technologies.isNotEmpty) ...[
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      'Tech: ${proj.technologies}',
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: mutedTextColor,
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
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSidebarSectionHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.2,
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

  pw.Widget _buildSidebarContactItem(
    String label,
    String value,
    PdfColor textColor,
    PdfColor mutedColor, {
    PdfContactIconStyle style = PdfContactIconStyle.icon,
  }) {
    if (style == PdfContactIconStyle.text) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: mutedColor,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    } else {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5, right: 6),
              child: PdfContactIcons.getIcon(label, color: mutedColor, size: 9),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  pw.Widget _buildMainSectionHeader(String title, PdfColor accentColor, PdfColor textColor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 3,
          height: 13,
          color: accentColor,
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
