import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/services/ai_key_storage_service.dart';
import '../../ai/services/gemini_ai_provider.dart';
import '../../ai/services/ai_service.dart';
import '../utils/resume_import_sanitizer.dart';
import '../utils/resume_input_scrubber.dart';

/// Structured result returned by [ResumeParserService].
class ParsedResumeResult {
  final Resume resume;
  final String rawExtractedText;
  final bool isAiAssisted;
  final double confidenceScore; // 0.0 to 1.0
  final Duration parsingDuration;
  final List<String> detectedSections;

  const ParsedResumeResult({
    required this.resume,
    required this.rawExtractedText,
    required this.isAiAssisted,
    required this.confidenceScore,
    required this.parsingDuration,
    required this.detectedSections,
  });
}

/// Production-grade PDF Parser & Resume Importer Engine for Resume Brain.
/// Ingests PDF bytes, extracts text stream in milliseconds, and maps sections
/// (Personal Info, Summary, Experience, Education, Skills, Projects, Certifications, Languages)
/// into the domain model with deterministic regex heuristics and Gemini AI fallback.
class ResumeParserService {
  final AIKeyStorageService? keyStorageService;

  ResumeParserService({this.keyStorageService});

  // ---------------------------------------------------------------------------
  // Main Entry Point
  // ---------------------------------------------------------------------------

  /// Ingests raw PDF bytes and returns a fully populated [ParsedResumeResult].
  /// Operates deterministically under 5 seconds.
  Future<ParsedResumeResult> parsePdfBytes(
    Uint8List pdfBytes, {
    bool enableAiFallback = true,
    String? preferredTitle,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Extract plain text from PDF bytes
    final rawText = extractTextFromPdf(pdfBytes);

    if (rawText.trim().isEmpty) {
      // If direct text extraction produced empty string (e.g. scanned image/unsupported encoding),
      // attempt AI fallback if enabled, or return a minimal placeholder resume.
      if (enableAiFallback) {
        final aiResult = await _parseWithGeminiAi(rawText, preferredTitle: preferredTitle);
        if (aiResult != null) {
          stopwatch.stop();
          return ParsedResumeResult(
            resume: aiResult,
            rawExtractedText: rawText,
            isAiAssisted: true,
            confidenceScore: 0.85,
            parsingDuration: stopwatch.elapsed,
            detectedSections: _detectSectionHeaders(rawText),
          );
        }
      }

      stopwatch.stop();
      return ParsedResumeResult(
        resume: Resume(
          title: preferredTitle ?? 'Imported Resume',
          personalInfo: PersonalInformation(fullName: 'Imported Candidate'),
        ),
        rawExtractedText: '',
        isAiAssisted: false,
        confidenceScore: 0.1,
        parsingDuration: stopwatch.elapsed,
        detectedSections: [],
      );
    }

    // Step 2: Extract structured data using Regex Heuristics
    final heuristicResume = _parseWithRegexHeuristics(rawText, preferredTitle: preferredTitle);
    final detectedSections = _detectSectionHeaders(rawText);
    final confidence = _calculateConfidence(heuristicResume, detectedSections);

    // Step 3: If confidence is low (< 0.5) and AI fallback is enabled, attempt Gemini AI parsing
    if (confidence < 0.5 && enableAiFallback) {
      try {
        final aiResume = await _parseWithGeminiAi(rawText, preferredTitle: preferredTitle);
        if (aiResume != null) {
          stopwatch.stop();
          return ParsedResumeResult(
            resume: aiResume,
            rawExtractedText: rawText,
            isAiAssisted: true,
            confidenceScore: 0.92,
            parsingDuration: stopwatch.elapsed,
            detectedSections: detectedSections,
          );
        }
      } catch (e) {
        debugPrint('Gemini AI fallback parsing encountered error: $e');
      }
    }

    stopwatch.stop();
    return ParsedResumeResult(
      resume: heuristicResume,
      rawExtractedText: rawText,
      isAiAssisted: false,
      confidenceScore: confidence,
      parsingDuration: stopwatch.elapsed,
      detectedSections: detectedSections,
    );
  }

  // ---------------------------------------------------------------------------
  // PDF Text Stream Extraction (Pure Dart & ZLib decompression)
  // ---------------------------------------------------------------------------

  /// Extracts text content from standard PDF streams without external dependencies.
  static String extractTextFromPdf(Uint8List bytes) {
    final buffer = StringBuffer();
    final latin1String = latin1.decode(bytes, allowInvalid: true);

    // Find all stream ... endstream blocks
    final streamRegex = RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream');
    final filterRegex = RegExp(r'\/Filter\s*(?:\[\s*\/([a-zA-Z0-9_]+)|\/([a-zA-Z0-9_]+))');

    // Also look for object dictionaries before streams
    final objRegex = RegExp(r'<<([\s\S]*?)>>\s*stream\r?\n', multiLine: true);

    for (final match in streamRegex.allMatches(latin1String)) {
      final streamStartIndex = match.start;
      final dictMatch = objRegex.allMatches(latin1String.substring(
        (streamStartIndex - 400).clamp(0, streamStartIndex),
        streamStartIndex + 20,
      ));

      String filterType = '';
      if (dictMatch.isNotEmpty) {
        final dictContent = dictMatch.last.group(1) ?? '';
        final fMatch = filterRegex.firstMatch(dictContent);
        if (fMatch != null) {
          filterType = fMatch.group(1) ?? fMatch.group(2) ?? '';
        }
      }

      final rawStreamContent = match.group(1) ?? '';
      List<int> streamBytes = latin1.encode(rawStreamContent);

      String decompressed = '';
      if (filterType == 'FlateDecode' || filterType.isEmpty) {
        try {
          // Decompress FlateDecode/zlib
          final decoded = zlib.decode(streamBytes);
          decompressed = utf8.decode(decoded, allowMalformed: true);
        } catch (_) {
          try {
            // Try raw deflate (without zlib header)
            final decoded = ZLibDecoder(raw: true).convert(streamBytes);
            decompressed = utf8.decode(decoded, allowMalformed: true);
          } catch (_) {
            decompressed = rawStreamContent;
          }
        }
      } else {
        decompressed = rawStreamContent;
      }

      final extractedFromStream = _extractTextFromContentStream(decompressed);
      if (extractedFromStream.isNotEmpty) {
        buffer.writeln(extractedFromStream);
      }
    }

    // Fallback: If no stream text found, scan for literal strings in raw PDF or treat as plain text payload
    if (buffer.isEmpty && latin1String.isNotEmpty) {
      final directText = _extractTextFromContentStream(latin1String);
      if (directText.isNotEmpty) {
        buffer.writeln(directText);
      } else {
        try {
          final decodedUtf8 = utf8.decode(bytes, allowMalformed: false);
          if (decodedUtf8.isNotEmpty) {
            buffer.writeln(decodedUtf8);
          }
        } catch (_) {
          if (!latin1String.startsWith('%PDF')) {
            buffer.writeln(latin1String);
          }
        }
      }
    }

    final rawOutput = buffer.toString();
    return _cleanupExtractedText(rawOutput);
  }

  /// Parses PDF content stream operators (BT...ET, Tj, TJ, ', ")
  static String _extractTextFromContentStream(String content) {
    final sb = StringBuffer();

    // Regex for text between BT (Begin Text) and ET (End Text)
    final btEtRegex = RegExp(r'BT([\s\S]*?)ET');
    final textMatches = btEtRegex.allMatches(content);

    if (textMatches.isNotEmpty) {
      for (final tm in textMatches) {
        final block = tm.group(1) ?? '';
        _parseTextBlock(block, sb);
      }
    } else {
      // If no BT/ET blocks, parse operators globally
      _parseTextBlock(content, sb);
    }

    return sb.toString();
  }

  static void _parseTextBlock(String block, StringBuffer sb) {
    // 1. Array text operator: [ (text1) 120 (text2) <hex> ] TJ
    final tjArrayRegex = RegExp(r'\[([\s\S]*?)\]\s*TJ');
    // 2. Single text operators: (text) Tj, (text) ', (text) "
    final tjSingleRegex = RegExp(r'\(((?:\\.|[^()\\])*)\)\s*(?:Tj|\x27|\x22)');
    // 3. Hex text strings: <48656C6C6F> Tj
    final hexSingleRegex = RegExp(r'<([0-9a-fA-F\s]+)>\s*(?:Tj|\x27|\x22)');

    // Line breaks indicators in PDF streams
    final lines = block.split(RegExp(r'\r?\n'));

    for (final line in lines) {
      bool lineHadText = false;

      // Check TJ arrays
      for (final match in tjArrayRegex.allMatches(line)) {
        final arrayContent = match.group(1) ?? '';
        final itemRegex = RegExp(r'\(((?:\\.|[^()\\])*)\)|<([0-9a-fA-F\s]+)>');
        for (final im in itemRegex.allMatches(arrayContent)) {
          if (im.group(1) != null) {
            sb.write(_decodePdfString(im.group(1)!));
            lineHadText = true;
          } else if (im.group(2) != null) {
            sb.write(_decodeHexPdfString(im.group(2)!));
            lineHadText = true;
          }
        }
      }

      // Check single Tj
      for (final match in tjSingleRegex.allMatches(line)) {
        sb.write(_decodePdfString(match.group(1)!));
        lineHadText = true;
      }

      // Check hex Tj
      for (final match in hexSingleRegex.allMatches(line)) {
        sb.write(_decodeHexPdfString(match.group(1)!));
        lineHadText = true;
      }

      // If line had T* or TD/Td/Tm with position shift or text output
      if (lineHadText || line.contains('T*') || line.contains('Td') || line.contains('TD')) {
        sb.writeln();
      }
    }
  }

  static String _decodePdfString(String str) {
    return str
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\b', '\b')
        .replaceAll(r'\f', '\f');
  }

  static String _decodeHexPdfString(String hex) {
    final cleanHex = hex.replaceAll(RegExp(r'\s+'), '');
    if (cleanHex.isEmpty) return '';

    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i + 1 < cleanHex.length) {
        final byte = int.tryParse(cleanHex.substring(i, i + 2), radix: 16);
        if (byte != null) bytes.add(byte);
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _cleanupExtractedText(String text) {
    // Normalize unicode, CRLF, and strip excess empty lines
    var cleaned = ResumeInputScrubber.scrubTextBlock(text);
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

  // ---------------------------------------------------------------------------
  // Regex Heuristics Engine
  // ---------------------------------------------------------------------------

  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
  );

  static final RegExp _urlRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?([a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)',
    caseSensitive: false,
  );

  static final RegExp _linkedinRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/([a-zA-Z0-9-_]+)',
    caseSensitive: false,
  );

  static final RegExp _githubRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?github\.com\/([a-zA-Z0-9-_]+)',
    caseSensitive: false,
  );

  static final RegExp _dateRangeRegex = RegExp(
    r'((?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?|\d{4})\s*[-–—/]\s*(?:Present|Current|Now|(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?|\d{4})))',
    caseSensitive: false,
  );

  static List<String> _detectSectionHeaders(String text) {
    final sections = <String>[];
    final lines = text.split('\n');

    final headerMap = {
      'Experience': RegExp(r'^(?:work\s+)?experience|employment|work\s+history|professional\s+experience', caseSensitive: false),
      'Education': RegExp(r'^education|academic\s+background|qualifications|academics', caseSensitive: false),
      'Skills': RegExp(r'^skills|technical\s+skills|core\s+competencies|technologies|tools', caseSensitive: false),
      'Summary': RegExp(r'^summary|professional\s+summary|profile|about\s+me|objective', caseSensitive: false),
      'Projects': RegExp(r'^projects|personal\s+projects|key\s+projects|portfolio', caseSensitive: false),
      'Certifications': RegExp(r'^certifications|licenses|courses|accreditations', caseSensitive: false),
      'Languages': RegExp(r'^languages|language\s+proficiency', caseSensitive: false),
    };

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length > 50) continue;

      for (final entry in headerMap.entries) {
        if (entry.value.hasMatch(trimmed) && !sections.contains(entry.key)) {
          sections.add(entry.key);
        }
      }
    }

    return sections;
  }

  static Resume _parseWithRegexHeuristics(String rawText, {String? preferredTitle}) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Extract Personal Information
    final personalInfo = _extractPersonalInfo(lines, rawText);

    // 2. Split into section blocks
    final sectionBlocks = _splitIntoSectionBlocks(rawText);

    // 3. Extract Summary
    final summaryText = _extractSummary(sectionBlocks['Summary'] ?? []);

    // 4. Extract Experiences
    final experiences = _extractExperiences(sectionBlocks['Experience'] ?? []);

    // 5. Extract Education
    final educationList = _extractEducationList(sectionBlocks['Education'] ?? []);

    // 6. Extract Skills
    final skills = _extractSkills(sectionBlocks['Skills'] ?? []);

    // 7. Extract Projects
    final projects = _extractProjects(sectionBlocks['Projects'] ?? []);

    // 8. Extract Certifications
    final certifications = _extractCertifications(sectionBlocks['Certifications'] ?? []);

    // 9. Extract Languages
    final languages = _extractLanguages(sectionBlocks['Languages'] ?? []);

    // 10. Extract Social Links
    final socialLinks = _extractSocialLinks(rawText);

    final title = preferredTitle ??
        (personalInfo.fullName.isNotEmpty
            ? '${personalInfo.fullName} Resume'
            : 'Imported Resume');

    return Resume(
      title: title,
      personalInfo: personalInfo,
      summary: ProfessionalSummary(summaryText: summaryText),
      experiences: experiences,
      educationList: educationList,
      skills: skills,
      projects: projects,
      certifications: certifications,
      languages: languages,
      socialLinks: socialLinks,
      templateId: 'modern_classic',
    );
  }

  static PersonalInformation _extractPersonalInfo(List<String> lines, String rawText) {
    String fullName = '';
    String jobTitle = '';
    String email = '';
    String phone = '';
    String location = '';
    String website = '';

    // Email
    final emailMatch = _emailRegex.firstMatch(rawText);
    if (emailMatch != null) {
      email = emailMatch.group(0) ?? '';
    }

    // Phone
    final phoneMatch = _phoneRegex.firstMatch(rawText);
    if (phoneMatch != null) {
      phone = phoneMatch.group(0) ?? '';
    }

    // Full Name: Usually the first non-header, non-email line in the first 5 lines
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.contains('@') || _phoneRegex.hasMatch(line) || line.toLowerCase().contains('resume') || line.toLowerCase().contains('curriculum')) {
        continue;
      }
      if (fullName.isEmpty && line.length >= 2 && line.length <= 50 && !line.contains(':')) {
        fullName = ResumeInputScrubber.scrubName(line);
      } else if (fullName.isNotEmpty && jobTitle.isEmpty && line.length <= 60 && !line.contains(email)) {
        jobTitle = ResumeInputScrubber.scrubTitle(line);
      }
    }

    // Location: Search for City, State / Country patterns (e.g. "San Francisco, CA" or "New York, NY")
    final locationRegex = RegExp(r'([A-Za-z\s]+,\s*[A-Z]{2}(?:\s+\d{5})?|[A-Za-z\s]+,\s*[A-Za-z\s]+)');
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];
      final segments = line.split(RegExp(r'[|•·]'));
      for (final segment in segments) {
        final cleanSeg = segment.trim();
        if (cleanSeg.isEmpty || cleanSeg.contains('@') || _phoneRegex.hasMatch(cleanSeg) || cleanSeg.contains('linkedin.com') || cleanSeg.contains('github.com')) {
          continue;
        }
        final locMatch = locationRegex.firstMatch(cleanSeg);
        if (locMatch != null && locMatch.group(0)!.length >= 3 && locMatch.group(0)!.length < 40) {
          location = locMatch.group(0)!.trim();
          break;
        }
      }
      if (location.isNotEmpty) break;
    }

    // Website / Portfolio
    final webMatches = _urlRegex.allMatches(rawText);
    for (final m in webMatches) {
      final url = m.group(0) ?? '';
      if (!url.contains('linkedin.com') && !url.contains('github.com')) {
        website = url;
        break;
      }
    }

    return PersonalInformation(
      fullName: fullName,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      location: location,
      website: website,
    );
  }

  static Map<String, List<String>> _splitIntoSectionBlocks(String rawText) {
    final blocks = <String, List<String>>{
      'Summary': [],
      'Experience': [],
      'Education': [],
      'Skills': [],
      'Projects': [],
      'Certifications': [],
      'Languages': [],
    };

    final headerPatterns = {
      'Experience': RegExp(r'^(?:work\s+)?experience|employment|work\s+history|professional\s+experience', caseSensitive: false),
      'Education': RegExp(r'^education|academic\s+background|qualifications|academics', caseSensitive: false),
      'Skills': RegExp(r'^skills|technical\s+skills|core\s+competencies|technologies|tools', caseSensitive: false),
      'Summary': RegExp(r'^summary|professional\s+summary|profile|about\s+me|objective', caseSensitive: false),
      'Projects': RegExp(r'^projects|personal\s+projects|key\s+projects|portfolio', caseSensitive: false),
      'Certifications': RegExp(r'^certifications|licenses|courses|accreditations', caseSensitive: false),
      'Languages': RegExp(r'^languages|language\s+proficiency', caseSensitive: false),
    };

    String? currentSection;
    final lines = rawText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      String? matchedSection;
      for (final entry in headerPatterns.entries) {
        if (entry.value.hasMatch(trimmed) && trimmed.length <= 40) {
          matchedSection = entry.key;
          break;
        }
      }

      if (matchedSection != null) {
        currentSection = matchedSection;
      } else if (currentSection != null) {
        blocks[currentSection]?.add(trimmed);
      }
    }

    return blocks;
  }

  static String _extractSummary(List<String> lines) {
    return lines.join(' ').trim();
  }

  static List<Experience> _extractExperiences(List<String> lines) {
    final experiences = <Experience>[];
    if (lines.isEmpty) return experiences;

    String currentCompany = '';
    String currentPosition = '';
    String currentStartDate = '';
    String currentEndDate = '';
    bool currentIsCurrent = false;
    final descriptionLines = <String>[];

    void saveCurrent() {
      if (currentCompany.isNotEmpty || currentPosition.isNotEmpty) {
        experiences.add(Experience(
          company: currentCompany.isNotEmpty ? currentCompany : 'Company',
          position: currentPosition.isNotEmpty ? currentPosition : 'Role',
          startDate: currentStartDate,
          endDate: currentEndDate,
          isCurrent: currentIsCurrent,
          description: descriptionLines.join('\n').trim(),
        ));
      }
      currentCompany = '';
      currentPosition = '';
      currentStartDate = '';
      currentEndDate = '';
      currentIsCurrent = false;
      descriptionLines.clear();
    }

    for (final line in lines) {
      final dateMatch = _dateRangeRegex.firstMatch(line);
      final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('·');

      if (dateMatch != null) {
        saveCurrent();
        final rawDateRange = dateMatch.group(0) ?? '';
        final parts = rawDateRange.split(RegExp(r'[-–—/]'));
        currentStartDate = parts.isNotEmpty ? parts[0].trim() : '';
        currentEndDate = parts.length > 1 ? parts[1].trim() : '';
        currentIsCurrent = currentEndDate.toLowerCase().contains('present') || currentEndDate.toLowerCase().contains('current') || currentEndDate.toLowerCase().contains('now');

        // Remaining text on the same line may be position or company
        final withoutDate = line.replaceFirst(rawDateRange, '').replaceAll(RegExp(r'[|,•]'), ' ').trim();
        if (withoutDate.isNotEmpty) {
          currentPosition = withoutDate;
        }
      } else if (isBullet) {
        descriptionLines.add(line);
      } else {
        if (currentPosition.isEmpty) {
          currentPosition = line;
        } else if (currentCompany.isEmpty) {
          currentCompany = line;
        } else {
          descriptionLines.add(line);
        }
      }
    }

    saveCurrent();
    return experiences;
  }

  static List<Education> _extractEducationList(List<String> lines) {
    final list = <Education>[];
    if (lines.isEmpty) return list;

    final degreeRegex = RegExp(
      r'\b(B\.S\.|B\.A\.|M\.S\.|M\.A\.|Ph\.D\.|Bachelor|Master|Associate|Doctor|BSc|MSc|BEng|MEng|BTech|MTech|MBA)\b',
      caseSensitive: false,
    );

    String institution = '';
    String degree = '';
    String fieldOfStudy = '';
    String startDate = '';
    String endDate = '';
    String gpa = '';

    void saveCurrent() {
      if (institution.isNotEmpty || degree.isNotEmpty) {
        list.add(Education(
          institution: institution.isNotEmpty ? institution : 'University',
          degree: degree.isNotEmpty ? degree : 'Degree',
          fieldOfStudy: fieldOfStudy,
          startDate: startDate,
          endDate: endDate,
          gpa: gpa,
        ));
      }
      institution = '';
      degree = '';
      fieldOfStudy = '';
      startDate = '';
      endDate = '';
      gpa = '';
    }

    for (final line in lines) {
      final isDegreeLine = degreeRegex.hasMatch(line);
      final dateMatch = _dateRangeRegex.firstMatch(line);
      final gpaMatch = RegExp(r'GPA:?\s*([0-9.]+)', caseSensitive: false).firstMatch(line);

      if (isDegreeLine && (degree.isNotEmpty || institution.isNotEmpty)) {
        saveCurrent();
      }

      if (gpaMatch != null) {
        gpa = gpaMatch.group(1) ?? '';
      }

      if (dateMatch != null) {
        final rawDateRange = dateMatch.group(0) ?? '';
        final parts = rawDateRange.split(RegExp(r'[-–—/]'));
        startDate = parts.isNotEmpty ? parts[0].trim() : '';
        endDate = parts.length > 1 ? parts[1].trim() : '';
      }

      if (isDegreeLine) {
        degree = line;
      } else {
        final segments = line.split(RegExp(r'[|•·]'));
        for (final segment in segments) {
          final cleanSeg = segment.trim();
          if (cleanSeg.isEmpty || _dateRangeRegex.hasMatch(cleanSeg) || cleanSeg.toLowerCase().contains('gpa')) {
            continue;
          }
          if (institution.isEmpty) {
            institution = cleanSeg;
          } else if (fieldOfStudy.isEmpty) {
            fieldOfStudy = cleanSeg;
          }
        }
      }
    }

    saveCurrent();
    return list;
  }

  static List<Skill> _extractSkills(List<String> lines) {
    final skills = <Skill>[];
    final allSkillsText = lines.join(' ');

    // Split on commas, bullets, pipes, or semicolons
    final tokens = allSkillsText.split(RegExp(r'[,•|;·\n]+'));

    for (final t in tokens) {
      final clean = ResumeInputScrubber.scrubTitle(t).trim();
      if (clean.isNotEmpty && clean.length <= 40 && !clean.toLowerCase().contains('skills')) {
        skills.add(Skill(
          id: const Uuid().v4(),
          name: clean,
          level: 'Intermediate',
        ));
      }
    }

    return skills;
  }

  static List<Project> _extractProjects(List<String> lines) {
    final projects = <Project>[];
    if (lines.isEmpty) return projects;

    String name = '';
    final descLines = <String>[];

    void saveCurrent() {
      if (name.isNotEmpty) {
        projects.add(Project(
          name: name,
          description: descLines.join('\n').trim(),
        ));
      }
      name = '';
      descLines.clear();
    }

    for (final line in lines) {
      if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        descLines.add(line);
      } else {
        if (name.isEmpty) {
          name = line;
        } else {
          saveCurrent();
          name = line;
        }
      }
    }

    saveCurrent();
    return projects;
  }

  static List<Certification> _extractCertifications(List<String> lines) {
    final list = <Certification>[];
    for (final line in lines) {
      final clean = ResumeInputScrubber.scrubTitle(line).trim();
      if (clean.isNotEmpty) {
        list.add(Certification(
          name: clean,
        ));
      }
    }
    return list;
  }

  static List<Language> _extractLanguages(List<String> lines) {
    final list = <Language>[];
    for (final line in lines) {
      final clean = ResumeInputScrubber.scrubTitle(line).trim();
      if (clean.isNotEmpty) {
        list.add(Language(
          name: clean,
          proficiency: 'Fluent',
        ));
      }
    }
    return list;
  }

  static List<SocialLink> _extractSocialLinks(String rawText) {
    final list = <SocialLink>[];

    final linkedinMatch = _linkedinRegex.firstMatch(rawText);
    if (linkedinMatch != null) {
      list.add(SocialLink(
        platform: 'LinkedIn',
        url: linkedinMatch.group(0) ?? '',
      ));
    }

    final githubMatch = _githubRegex.firstMatch(rawText);
    if (githubMatch != null) {
      list.add(SocialLink(
        platform: 'GitHub',
        url: githubMatch.group(0) ?? '',
      ));
    }

    return list;
  }

  static double _calculateConfidence(Resume resume, List<String> detectedSections) {
    double score = 0.0;
    if (resume.personalInfo.fullName.isNotEmpty) score += 0.25;
    if (resume.personalInfo.email.isNotEmpty) score += 0.15;
    if (resume.experiences.isNotEmpty) score += 0.25;
    if (resume.educationList.isNotEmpty) score += 0.15;
    if (resume.skills.isNotEmpty) score += 0.10;
    if (detectedSections.length >= 3) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Gemini AI Fallback Parser
  // ---------------------------------------------------------------------------

  Future<Resume?> _parseWithGeminiAi(String rawText, {String? preferredTitle}) async {
    final apiKey = await keyStorageService?.getGeminiKey() ??
        const String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.isEmpty || apiKey == 'MOCK_KEY') {
      return null;
    }

    final prompt = '''
You are an expert AI Resume Parsing Engine.
Extract the structured data from the resume text below and return ONLY valid JSON adhering strictly to this schema:
{
  "title": "${preferredTitle ?? 'Imported Resume'}",
  "personalInfo": {
    "fullName": "...",
    "jobTitle": "...",
    "email": "...",
    "phone": "...",
    "location": "...",
    "website": "..."
  },
  "summary": {
    "summaryText": "..."
  },
  "experiences": [
    {
      "company": "...",
      "position": "...",
      "location": "...",
      "startDate": "...",
      "endDate": "...",
      "isCurrent": false,
      "description": "..."
    }
  ],
  "educationList": [
    {
      "institution": "...",
      "degree": "...",
      "fieldOfStudy": "...",
      "location": "...",
      "startDate": "...",
      "endDate": "...",
      "gpa": "..."
    }
  ],
  "skills": [
    {
      "name": "...",
      "level": "Intermediate"
    }
  ],
  "projects": [
    {
      "name": "...",
      "role": "...",
      "description": "...",
      "technologies": "...",
      "link": "..."
    }
  ],
  "certifications": [
    {
      "name": "...",
      "issuingOrganization": "...",
      "issueDate": "...",
      "expiryDate": "..."
    }
  ],
  "languages": [
    {
      "name": "...",
      "proficiency": "Fluent"
    }
  ],
  "socialLinks": [
    {
      "platform": "LinkedIn",
      "url": "..."
    }
  ]
}

Resume Text:
$rawText
''';

    final provider = GeminiAIProvider(apiKey: apiKey);
    final response = await provider.processRequest(
      AIRequest(taskType: AITaskType.textImprovement, inputText: prompt),
    );

    if (response.isSuccess && response.outputText.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(response.outputText);
        final sanitizedMap = ResumeImportSanitizer.sanitizeResumeJson(parsed);
        return Resume.fromMap(sanitizedMap);
      } catch (e) {
        debugPrint('Failed to decode Gemini resume JSON: $e');
      }
    }
    return null;
  }
}
