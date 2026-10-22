import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import 'ai_key_storage_service.dart';

enum CoverLetterTone {
  professional,
  confident,
  creative,
}

extension CoverLetterToneExtension on CoverLetterTone {
  String get displayName {
    switch (this) {
      case CoverLetterTone.professional:
        return 'Professional';
      case CoverLetterTone.confident:
        return 'Confident';
      case CoverLetterTone.creative:
        return 'Creative';
    }
  }

  String get subtitle {
    switch (this) {
      case CoverLetterTone.professional:
        return 'Formal, balanced & executive-ready';
      case CoverLetterTone.confident:
        return 'Bold, high-impact & metric-driven';
      case CoverLetterTone.creative:
        return 'Engaging, modern & storytelling-focused';
    }
  }

  String get promptGuidance {
    switch (this) {
      case CoverLetterTone.professional:
        return 'Tone: Formal, authoritative, polished, and respectful. Focus on proven industry experience, standard executive terminology, and systematic problem-solving competence.';
      case CoverLetterTone.confident:
        return 'Tone: Assertive, dynamic, high-energy, and achievement-first. Lead directly with high-impact quantifiable outcomes (Google XYZ formula), measurable KPIs, and bold value-add from day one.';
      case CoverLetterTone.creative:
        return 'Tone: Engaging, personable, authentic, and narrative-driven. Open with a unique perspective, show passionate alignment with the company mission, and highlight innovative engineering or strategic initiatives.';
    }
  }
}

/// Production-ready AI Cover Letter and LinkedIn Outreach Service powered by Google Gemini 1.5 Flash.
class AICoverLetterService {
  final AIKeyStorageService keyStorage;
  final String defaultGeminiKey;
  final http.Client client;

  AICoverLetterService({
    required this.keyStorage,
    this.defaultGeminiKey = '',
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<String?> _resolveGeminiApiKey() async {
    try {
      final storedKey = await keyStorage.getGeminiKey();
      if (storedKey != null && storedKey.trim().isNotEmpty && storedKey != 'MOCK_KEY') {
        return storedKey.trim();
      }
    } catch (e) {
      debugPrint('Error reading key storage: $e');
    }

    if (defaultGeminiKey.isNotEmpty && defaultGeminiKey != 'MOCK_KEY') {
      return defaultGeminiKey;
    }
    return null;
  }

  /// Streams generated cover letter markdown chunks from Gemini 1.5 Flash
  Stream<String> generateCoverLetterStream({
    required Resume resume,
    required String jobDescription,
    required CoverLetterTone tone,
    String? companyName,
    String? jobTitle,
  }) async* {
    final apiKey = await _resolveGeminiApiKey();

    if (apiKey == null) {
      // Offline fallback stream with natural reading cadence
      final offlineResult = _generateOfflineCoverLetter(
        resume: resume,
        jobDescription: jobDescription,
        tone: tone,
        companyName: companyName,
        jobTitle: jobTitle,
      );

      final words = offlineResult.split(' ');
      for (int i = 0; i < words.length; i += 3) {
        final end = (i + 3 < words.length) ? i + 3 : words.length;
        final chunk = '${words.sublist(i, end).join(' ')} ';
        yield chunk;
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?alt=sse&key=$apiKey',
    );

    final prompt = _buildCoverLetterPrompt(
      resume: resume,
      jobDescription: jobDescription,
      tone: tone,
      companyName: companyName,
      jobTitle: jobTitle,
    );

    try {
      final request = http.Request('POST', endpoint);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': tone == CoverLetterTone.creative ? 0.8 : (tone == CoverLetterTone.confident ? 0.6 : 0.4),
          'maxOutputTokens': 2048,
        }
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        final lines = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final data = jsonDecode(jsonStr);
              final text = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'] ??
                  data['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text != null && (text as String).isNotEmpty) {
                yield text;
              }
            } catch (_) {
              // Ignore partial JSON chunk framing
            }
          }
        }
      } else {
        // Fallback to offline generation on API status failure
        final offlineResult = _generateOfflineCoverLetter(
          resume: resume,
          jobDescription: jobDescription,
          tone: tone,
          companyName: companyName,
          jobTitle: jobTitle,
        );
        yield offlineResult;
      }
    } catch (e) {
      // Fallback to offline on network exception
      final offlineResult = _generateOfflineCoverLetter(
        resume: resume,
        jobDescription: jobDescription,
        tone: tone,
        companyName: companyName,
        jobTitle: jobTitle,
      );
      yield offlineResult;
    }
  }

  /// Single-shot cover letter generation
  Future<String> generateCoverLetter({
    required Resume resume,
    required String jobDescription,
    required CoverLetterTone tone,
    String? companyName,
    String? jobTitle,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in generateCoverLetterStream(
      resume: resume,
      jobDescription: jobDescription,
      tone: tone,
      companyName: companyName,
      jobTitle: jobTitle,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  /// Streams tailored LinkedIn recruiter outreach note (strict <= 300 characters)
  Stream<String> generateLinkedInOutreachStream({
    required Resume resume,
    required String jobDescription,
    String? recruiterName,
    String? companyName,
    String? jobTitle,
  }) async* {
    final apiKey = await _resolveGeminiApiKey();

    if (apiKey == null) {
      final offlineNote = _generateOfflineLinkedInNote(
        resume: resume,
        jobDescription: jobDescription,
        recruiterName: recruiterName,
        companyName: companyName,
        jobTitle: jobTitle,
      );

      final words = offlineNote.split(' ');
      for (final word in words) {
        yield '$word ';
        await Future.delayed(const Duration(milliseconds: 25));
      }
      return;
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildLinkedInPrompt(
      resume: resume,
      jobDescription: jobDescription,
      recruiterName: recruiterName,
      companyName: companyName,
      jobTitle: jobTitle,
    );

    try {
      final response = await client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        text = text.replaceAll('"', '').trim();
        if (text.length > 300) {
          text = '${text.substring(0, 297)}...';
        }
        yield text;
      } else {
        yield _generateOfflineLinkedInNote(
          resume: resume,
          jobDescription: jobDescription,
          recruiterName: recruiterName,
          companyName: companyName,
          jobTitle: jobTitle,
        );
      }
    } catch (e) {
      yield _generateOfflineLinkedInNote(
        resume: resume,
        jobDescription: jobDescription,
        recruiterName: recruiterName,
        companyName: companyName,
        jobTitle: jobTitle,
      );
    }
  }

  /// Single-shot LinkedIn outreach note generation
  Future<String> generateLinkedInOutreach({
    required Resume resume,
    required String jobDescription,
    String? recruiterName,
    String? companyName,
    String? jobTitle,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in generateLinkedInOutreachStream(
      resume: resume,
      jobDescription: jobDescription,
      recruiterName: recruiterName,
      companyName: companyName,
      jobTitle: jobTitle,
    )) {
      buffer.write(chunk);
    }
    String result = buffer.toString().trim();
    if (result.length > 300) {
      result = '${result.substring(0, 297)}...';
    }
    return result;
  }

  /// Builds prompt for Gemini AI Cover Letter Generation
  String _buildCoverLetterPrompt({
    required Resume resume,
    required String jobDescription,
    required CoverLetterTone tone,
    String? companyName,
    String? jobTitle,
  }) {
    final candidateName = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : 'Candidate';
    final targetRole = (jobTitle != null && jobTitle.isNotEmpty)
        ? jobTitle
        : (resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : 'the target position');
    final targetCompany = (companyName != null && companyName.isNotEmpty) ? companyName : 'your organization';

    final resumeJson = jsonEncode(resume.toMap());

    return '''
You are an elite Executive Career Coach and Talent Acquisition Strategist.
Your objective is to craft a world-class, customized Cover Letter in clean Markdown format for $candidateName applying for $targetRole at $targetCompany.

${tone.promptGuidance}

=== CANDIDATE RESUME JSON DATA ===
$resumeJson

=== TARGET JOB DESCRIPTION ===
$jobDescription

=== STRICT COVER LETTER STRUCTURAL REQUIREMENTS ===
1. Professional Header: Include Candidate Name, Contact Details (Email, Phone, Location, LinkedIn/Website if available), Date, and Target Company info.
2. Salutation: "Dear Hiring Team at $targetCompany," or "Dear Hiring Manager,".
3. Engaging Hook: State the exact role applied for ($targetRole) and immediately establish a distinctive value proposition.
4. Body Paragraph 1 (Core Alignment & Achievements): Connect candidate's past work experience and quantified achievements directly to the key requirements of the Job Description. Use concrete metrics and power verbs.
5. Body Paragraph 2 (Skills & Technical Synergy): Highlight specific technical tools, methodologies, domain expertise, or leadership initiatives from the candidate's resume that solve the company's pain points.
6. Closing Paragraph: Reaffirm enthusiastic interest, state immediate availability for discussion, and provide a polite Call-to-Action.
7. Sign-off: "Sincerely," followed by $candidateName.
8. Output pure markdown with bold headers and clean paragraph spacing. Do NOT wrap output in triple backtick code blocks.
''';
  }

  /// Builds prompt for LinkedIn Connection/InMail Note (Strictly <= 300 chars)
  String _buildLinkedInPrompt({
    required Resume resume,
    required String jobDescription,
    String? recruiterName,
    String? companyName,
    String? jobTitle,
  }) {
    final candidateName = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : 'Candidate';
    final recruiter = (recruiterName != null && recruiterName.isNotEmpty) ? recruiterName : 'Hiring Leader';
    final targetRole = (jobTitle != null && jobTitle.isNotEmpty)
        ? jobTitle
        : (resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : 'Open Role');
    final company = (companyName != null && companyName.isNotEmpty) ? companyName : 'your team';

    final topSkills = resume.skills.take(4).map((s) => s.name).join(', ');
    final recentExp = resume.experiences.isNotEmpty ? resume.experiences.first.position : targetRole;

    return '''
Write an ultra-concise, high-impact LinkedIn outreach note from $candidateName to $recruiter at $company regarding the $targetRole position.

Candidate background: $recentExp. Core strengths: $topSkills.
Job highlights: $jobDescription.

CRITICAL HARD CONSTRAINT:
- Maximum 300 characters TOTAL (including spaces and punctuation).
- Must fit LinkedIn's 300-character connection request limit.
- Polite, personalized hook + 1 key achievement/skill alignment + clear call-to-action to connect.
- Output ONLY the note text, without quotes or explanations.
''';
  }

  /// Offline Fallback Generator for Cover Letter
  String _generateOfflineCoverLetter({
    required Resume resume,
    required String jobDescription,
    required CoverLetterTone tone,
    String? companyName,
    String? jobTitle,
  }) {
    final name = resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : 'Jane Doe';
    final email = resume.personalInfo.email.isNotEmpty ? resume.personalInfo.email : 'contact@valixis.ai';
    final phone = resume.personalInfo.phone.isNotEmpty ? resume.personalInfo.phone : '+1 (555) 019-2834';
    final location = resume.personalInfo.location.isNotEmpty ? resume.personalInfo.location : 'San Francisco, CA';
    final role = (jobTitle != null && jobTitle.isNotEmpty)
        ? jobTitle
        : (resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : 'Software Engineer');
    final company = (companyName != null && companyName.isNotEmpty) ? companyName : 'InnovateTech Corp';

    final expList = resume.experiences;
    final topExp = expList.isNotEmpty ? expList.first : null;
    final expTitle = topExp?.position ?? role;
    final expCompany = topExp?.company ?? 'Industry Leaders';
    final expDesc = (topExp != null && topExp.description.isNotEmpty)
        ? topExp.description
        : 'spearheading scalable systems, optimizing application performance, and delivering high-reliability production software.';

    final skillsList = resume.skills.map((s) => s.name).take(5).toList();
    final skillsString = skillsList.isNotEmpty
        ? skillsList.join(', ')
        : 'Full-Stack Architecture, Cloud Infrastructure, Agile Engineering, and System Design';

    final dateStr = 'October 1, 2026';

    if (tone == CoverLetterTone.confident) {
      return '''
# $name
**$role**  
$location • $phone • $email  

$dateStr  

**Hiring Team**  
$company  

**Subject: Application for $role — Delivering High-Impact Engineering Solutions**

Dear Hiring Team at $company,

I am writing to express my high-conviction interest in the **$role** position at **$company**. With a proven record of driving measurable business impact and engineering resilient systems, I am eager to bring my technical velocity and problem-solving drive to your high-performing team.

At **$expCompany**, serving as **$expTitle**, I spearheaded critical initiatives: $expDesc. My approach centers on quantitative outcomes—accelerating delivery cycles, optimizing infrastructure costs, and architecting robust user-facing workflows that scale seamlessly.

Your mission aligns directly with my expertise across **$skillsString**. I thrive in fast-paced environments where ownership, rapid iteration, and technical rigor are valued. I am confident that my background will allow me to contribute from day one to $company's strategic objectives.

I welcome the opportunity to discuss how my skill set and proactive mindset will drive tangible results for $company. Thank you for your time and consideration.

Sincerely,  
**$name**
''';
    } else if (tone == CoverLetterTone.creative) {
      return '''
# $name
**$role**  
$location • $phone • $email  

$dateStr  

**Talent & Engineering Leadership**  
$company  

**Subject: Inspiring Innovation as $role at $company**

Dear Hiring Manager,

Great software is built at the intersection of curiosity, engineering craft, and human-centric design. When I came across the **$role** opening at **$company**, I was immediately energized by your team's ambitious vision and product culture.

Throughout my journey as **$expTitle** at **$expCompany**, I have focused on solving ambiguous challenges through thoughtful architecture and continuous iteration: $expDesc. Whether navigating complex edge cases or collaborating cross-functionally, I strive to turn complex requirements into elegant, dependable digital experiences.

With deep hands-on expertise in **$skillsString**, I love building systems that not only perform under load but also empower end-users. I admire how $company is shaping the industry landscape, and I would love the chance to co-create the next chapter of your product journey.

I would be thrilled to connect and share more about how my background and creative energy can support $company's goals. Thank you for your consideration!

Warm regards,  
**$name**
''';
    } else {
      // Professional Default
      return '''
# $name
**$role**  
$location • $phone • $email  

$dateStr  

**Hiring Manager**  
$company  

**Subject: Application for $role Position**

Dear Hiring Manager,

I am writing to formally submit my application for the **$role** opportunity at **$company**. Having closely followed your organization's impressive growth and market leadership, I am enthusiastic about the opportunity to contribute my technical background, domain knowledge, and dedication to excellence.

In my recent capacity as **$expTitle** at **$expCompany**, I successfully managed key deliverables: $expDesc. This experience solidified my ability to collaborate across multidisciplinary stakeholders, maintain rigorous code quality, and consistently deliver strategic outcomes aligned with organizational goals.

My technical toolkit includes **$skillsString**, combined with a solid foundation in modern engineering best practices. I am confident that my analytical skills, commitment to continuous learning, and collaborative leadership will make me a valuable addition to your team at $company.

Thank you for reviewing my application. I would welcome the opportunity to discuss my qualifications in an interview at your earliest convenience.

Sincerely,  
**$name**
''';
    }
  }

  /// Offline Fallback Generator for LinkedIn Recruiter Note (<= 300 chars)
  String _generateOfflineLinkedInNote({
    required Resume resume,
    required String jobDescription,
    String? recruiterName,
    String? companyName,
    String? jobTitle,
  }) {
    final recruiter = (recruiterName != null && recruiterName.isNotEmpty) ? recruiterName : 'there';
    final role = (jobTitle != null && jobTitle.isNotEmpty)
        ? jobTitle
        : (resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : 'the open role');
    final company = (companyName != null && companyName.isNotEmpty) ? companyName : 'your team';
    final skill = resume.skills.isNotEmpty ? resume.skills.first.name : 'software engineering';

    final note = 'Hi $recruiter, saw $company is hiring for $role! With strong expertise in $skill & scalable systems, I’d love to connect and see if my background is a great fit for your team.';

    if (note.length <= 300) return note;
    return '${note.substring(0, 297)}...';
  }

  /// Compiles the generated Cover Letter into a clean, professional A4 PDF
  Future<Uint8List> generateCoverLetterPdf({
    required Resume resume,
    required String coverLetterText,
    String? companyName,
    String? jobTitle,
    CoverLetterTone tone = CoverLetterTone.professional,
  }) async {
    final pdf = pw.Document();

    final candidateName = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : 'Your Name';
    final role = (jobTitle != null && jobTitle.isNotEmpty)
        ? jobTitle
        : (resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : 'Professional');
    final email = resume.personalInfo.email;
    final phone = resume.personalInfo.phone;
    final location = resume.personalInfo.location;

    final primaryColor = tone == CoverLetterTone.confident
        ? PdfColor.fromHex('#1E3A8A') // Deep Blue
        : (tone == CoverLetterTone.creative ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#1E293B')); // Emerald or Slate
    final textDark = PdfColor.fromHex('#0F172A');
    final textMuted = PdfColor.fromHex('#475569');

    // Parse plain text lines from markdown
    final cleanedParagraphs = coverLetterText
        .split('\n\n')
        .map((p) => p.replaceAll(RegExp(r'[#*`_]'), '').trim())
        .where((p) => p.isNotEmpty)
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        candidateName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        role,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (email.isNotEmpty)
                        pw.Text(email, style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      if (phone.isNotEmpty)
                        pw.Text(phone, style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      if (location.isNotEmpty)
                        pw.Text(location, style: pw.TextStyle(fontSize: 9, color: textMuted)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 20),

              // Body Content
              ...cleanedParagraphs.map((para) {
                final isSubject = para.toLowerCase().startsWith('subject:') ||
                    para.toLowerCase().startsWith('re:');
                final isSalutation = para.toLowerCase().startsWith('dear ');
                final isSignoff = para.toLowerCase().startsWith('sincerely') ||
                    para.toLowerCase().startsWith('warm regards') ||
                    para.toLowerCase().startsWith('best regards');

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    para,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      lineSpacing: 3.5,
                      color: textDark,
                      fontWeight: isSubject || isSalutation || isSignoff
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Exports and shares the cover letter PDF
  Future<void> exportCoverLetterPdf({
    required Resume resume,
    required String coverLetterText,
    String? companyName,
    String? jobTitle,
    CoverLetterTone tone = CoverLetterTone.professional,
  }) async {
    final pdfBytes = await generateCoverLetterPdf(
      resume: resume,
      coverLetterText: coverLetterText,
      companyName: companyName,
      jobTitle: jobTitle,
      tone: tone,
    );

    final safeName = resume.personalInfo.fullName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final filename = 'Cover_Letter_${safeName.isNotEmpty ? safeName : "ResumeBrain"}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}

final aiCoverLetterServiceProvider = Provider<AICoverLetterService>((ref) {
  final keyStorage = ref.watch(aiKeyStorageServiceProvider);
  const geminiKey = String.fromEnvironment('GEMINI_API_KEY');

  return AICoverLetterService(
    keyStorage: keyStorage,
    defaultGeminiKey: geminiKey,
  );
});
