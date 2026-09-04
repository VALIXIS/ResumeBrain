import 'package:uuid/uuid.dart';
import '../../../data/models/resume_schema_migrator.dart';
import 'resume_input_scrubber.dart';

/// Exception thrown when resume JSON import fails structural validation or sanitization.
class ResumeImportException implements Exception {
  final String message;
  const ResumeImportException(this.message);

  @override
  String toString() => 'ResumeImportException: $message';
}

/// Provides strict validation, structure checking, sanitization, and normalization
/// for imported resume JSON payloads before they are converted into Resume models.
class ResumeImportSanitizer {
  ResumeImportSanitizer._();

  static const int kMaxStringLength = 10000;
  static const int kMaxTitleLength = 200;
  static const int kMaxShortStringLength = 150;
  static const int kMaxListLength = 100;

  static final RegExp _scriptTagRegex = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
    caseSensitive: false,
    multiLine: true,
  );

  /// Validates and strictly sanitizes imported JSON map before model instantiation.
  /// Throws [ResumeImportException] if the JSON root is invalid or unparseable.
  static Map<String, dynamic> sanitizeResumeJson(dynamic rawJson) {
    if (rawJson == null) {
      throw const ResumeImportException('Imported resume JSON cannot be null.');
    }
    if (rawJson is! Map) {
      throw const ResumeImportException('Imported JSON root must be an object/Map.');
    }

    final rawMap = Map<String, dynamic>.from(rawJson);
    if (rawMap.isEmpty) {
      throw const ResumeImportException('Imported resume JSON cannot be empty.');
    }

    // Step 1: Migrate legacy schema versions if needed
    final migratedMap = ResumeSchemaMigrator.migrateJsonMap(rawMap);

    // Step 2: Sanitize top-level metadata
    final id = _sanitizeId(migratedMap['id']);
    final title = _sanitizeString(
      migratedMap['title'],
      maxLength: kMaxTitleLength,
      defaultVal: 'Imported Resume',
    );
    final templateId = _sanitizeTemplateId(migratedMap['templateId']);
    final createdAt = _sanitizeIsoDate(migratedMap['createdAt']);
    final updatedAt = _sanitizeIsoDate(migratedMap['updatedAt']);

    // Step 3: Sanitize nested objects
    final personalInfo = _sanitizePersonalInfo(migratedMap['personalInfo']);
    final summary = _sanitizeSummary(migratedMap['summary']);
    final experiences = _sanitizeExperiences(migratedMap['experiences']);
    final educationList = _sanitizeEducationList(migratedMap['educationList']);
    final projects = _sanitizeProjects(migratedMap['projects']);
    final skills = _sanitizeSkills(migratedMap['skills']);
    final certifications = _sanitizeCertifications(migratedMap['certifications']);
    final languages = _sanitizeLanguages(migratedMap['languages']);
    final customSections = _sanitizeCustomSections(migratedMap['customSections']);
    final socialLinks = _sanitizeSocialLinks(migratedMap['socialLinks']);

    return {
      'schemaVersion': ResumeSchemaMigrator.kCurrentSchemaVersion,
      'id': id,
      'title': title,
      'templateId': templateId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'personalInfo': personalInfo,
      'summary': summary,
      'experiences': experiences,
      'educationList': educationList,
      'projects': projects,
      'skills': skills,
      'certifications': certifications,
      'languages': languages,
      'customSections': customSections,
      'socialLinks': socialLinks,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper Sanitizers
  // ---------------------------------------------------------------------------

  static String _sanitizeString(
    dynamic input, {
    int maxLength = kMaxShortStringLength,
    String defaultVal = '',
  }) {
    if (input == null) return defaultVal;
    String str = input.toString();

    // Remove script tags to prevent any code execution or markup injection
    str = str.replaceAll(_scriptTagRegex, '');

    // Strip control characters and zero-width artifacts while keeping legitimate text/unicode
    str = ResumeInputScrubber.scrubTextBlock(str);

    // Truncate to maximum allowed length
    if (str.length > maxLength) {
      str = str.substring(0, maxLength);
    }

    return str.trim();
  }

  static String _sanitizeId(dynamic rawId) {
    if (rawId == null) return const Uuid().v4();
    final str = rawId.toString().trim();
    if (str.isEmpty || str.length > 100) return const Uuid().v4();
    return ResumeInputScrubber.scrubControlCharacters(str);
  }

  static String _sanitizeIsoDate(dynamic rawDate) {
    if (rawDate == null) return DateTime.now().toIso8601String();
    final str = rawDate.toString().trim();
    final parsed = DateTime.tryParse(str);
    return (parsed ?? DateTime.now()).toIso8601String();
  }

  static String _sanitizeTemplateId(dynamic rawTemplateId) {
    const validTemplates = [
      'modern_classic',
      'executive_minimal',
      'creative_professional',
      'tech_specialist',
      'academic_cv',
    ];
    if (rawTemplateId == null) return 'modern_classic';
    final str = rawTemplateId.toString().trim().toLowerCase();
    return validTemplates.contains(str) ? str : 'modern_classic';
  }

  static Map<String, dynamic> _sanitizePersonalInfo(dynamic rawInfo) {
    if (rawInfo == null || rawInfo is! Map) return {};
    final map = Map<String, dynamic>.from(rawInfo);
    return {
      'fullName': _sanitizeString(map['fullName'], maxLength: kMaxShortStringLength),
      'jobTitle': _sanitizeString(map['jobTitle'], maxLength: kMaxShortStringLength),
      'email': ResumeInputScrubber.scrubEmail(_sanitizeString(map['email'], maxLength: 100)),
      'phone': ResumeInputScrubber.scrubPhone(_sanitizeString(map['phone'], maxLength: 50)),
      'location': _sanitizeString(map['location'], maxLength: kMaxShortStringLength),
      'website': ResumeInputScrubber.scrubUrl(_sanitizeString(map['website'], maxLength: 200)),
    };
  }

  static Map<String, dynamic> _sanitizeSummary(dynamic rawSummary) {
    if (rawSummary == null || rawSummary is! Map) return {'summaryText': ''};
    final map = Map<String, dynamic>.from(rawSummary);
    return {
      'summaryText': _sanitizeString(map['summaryText'], maxLength: kMaxStringLength),
    };
  }

  static List<Map<String, dynamic>> _sanitizeExperiences(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        result.add({
          'id': _sanitizeId(m['id']),
          'company': _sanitizeString(m['company'], maxLength: kMaxShortStringLength),
          'position': _sanitizeString(m['position'], maxLength: kMaxShortStringLength),
          'location': _sanitizeString(m['location'], maxLength: kMaxShortStringLength),
          'startDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['startDate'], maxLength: 50)),
          'endDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['endDate'], maxLength: 50)),
          'isCurrent': m['isCurrent'] is bool ? m['isCurrent'] : false,
          'description': _sanitizeString(m['description'], maxLength: kMaxStringLength),
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeEducationList(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        result.add({
          'id': _sanitizeId(m['id']),
          'institution': _sanitizeString(m['institution'], maxLength: kMaxShortStringLength),
          'degree': _sanitizeString(m['degree'], maxLength: kMaxShortStringLength),
          'fieldOfStudy': _sanitizeString(m['fieldOfStudy'], maxLength: kMaxShortStringLength),
          'location': _sanitizeString(m['location'], maxLength: kMaxShortStringLength),
          'startDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['startDate'], maxLength: 50)),
          'endDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['endDate'], maxLength: 50)),
          'gpa': ResumeInputScrubber.scrubGpa(_sanitizeString(m['gpa'], maxLength: 30)),
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeProjects(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        result.add({
          'id': _sanitizeId(m['id']),
          'name': _sanitizeString(m['name'], maxLength: kMaxShortStringLength),
          'role': _sanitizeString(m['role'], maxLength: kMaxShortStringLength),
          'description': _sanitizeString(m['description'], maxLength: kMaxStringLength),
          'technologies': _sanitizeString(m['technologies'], maxLength: 300),
          'link': ResumeInputScrubber.scrubUrl(_sanitizeString(m['link'], maxLength: 200)),
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeSkills(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    const validLevels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        String level = _sanitizeString(m['level'], maxLength: 30, defaultVal: 'Intermediate');
        if (!validLevels.contains(level)) {
          level = 'Intermediate';
        }

        result.add({
          'id': _sanitizeId(m['id']),
          'name': _sanitizeString(m['name'], maxLength: 80),
          'level': level,
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeCertifications(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        result.add({
          'id': _sanitizeId(m['id']),
          'name': _sanitizeString(m['name'], maxLength: kMaxShortStringLength),
          'issuingOrganization': _sanitizeString(m['issuingOrganization'], maxLength: kMaxShortStringLength),
          'issueDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['issueDate'], maxLength: 50)),
          'expiryDate': ResumeInputScrubber.scrubDate(_sanitizeString(m['expiryDate'], maxLength: 50)),
          'credentialId': _sanitizeString(m['credentialId'], maxLength: 100),
          'credentialUrl': ResumeInputScrubber.scrubUrl(_sanitizeString(m['credentialUrl'], maxLength: 200)),
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeLanguages(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    const validProficiencies = ['Native', 'Fluent', 'Conversational', 'Beginner'];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        String proficiency = _sanitizeString(m['proficiency'], maxLength: 30, defaultVal: 'Fluent');
        if (!validProficiencies.contains(proficiency)) {
          proficiency = 'Fluent';
        }

        result.add({
          'id': _sanitizeId(m['id']),
          'name': _sanitizeString(m['name'], maxLength: 60),
          'proficiency': proficiency,
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeCustomSections(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final rawItems = m['items'];
        final sanitizedItems = <String>[];
        if (rawItems is List) {
          for (final it in rawItems.take(50)) {
            sanitizedItems.add(_sanitizeString(it, maxLength: kMaxStringLength));
          }
        }

        result.add({
          'id': _sanitizeId(m['id']),
          'title': _sanitizeString(m['title'], maxLength: kMaxShortStringLength),
          'items': sanitizedItems,
        });
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _sanitizeSocialLinks(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    final list = rawList.take(kMaxListLength);
    final result = <Map<String, dynamic>>[];

    const validPlatforms = ['LinkedIn', 'GitHub', 'Portfolio', 'Twitter', 'Website', 'Other'];

    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        String platform = _sanitizeString(m['platform'], maxLength: 30, defaultVal: 'LinkedIn');
        if (!validPlatforms.contains(platform)) {
          platform = 'LinkedIn';
        }

        result.add({
          'id': _sanitizeId(m['id']),
          'platform': platform,
          'url': ResumeInputScrubber.scrubUrl(_sanitizeString(m['url'], maxLength: 200)),
        });
      }
    }
    return result;
  }
}
