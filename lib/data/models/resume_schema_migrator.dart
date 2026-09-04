import 'package:flutter/foundation.dart';

/// Exception thrown when an imported or read resume JSON uses an unsupported future schema version.
class ResumeSchemaException implements Exception {
  final String message;
  const ResumeSchemaException(this.message);

  @override
  String toString() => 'ResumeSchemaException: $message';
}

/// Central manager for resume JSON schema versioning and backward-compatible schema migrations.
class ResumeSchemaMigrator {
  ResumeSchemaMigrator._();

  /// Central constant defining the current supported schema version.
  static const int kCurrentSchemaVersion = 1;

  /// Inspects raw map payload, detects its schema version, and migrates older versions
  /// sequentially to [kCurrentSchemaVersion].
  ///
  /// Throws [ResumeSchemaException] if the schema version is newer than [kCurrentSchemaVersion].
  static Map<String, dynamic> migrateJsonMap(Map<String, dynamic> inputMap) {
    final map = Map<String, dynamic>.from(inputMap);

    final rawVersion = map['schemaVersion'];
    int schemaVersion = 0;
    if (rawVersion is int) {
      schemaVersion = rawVersion;
    } else if (rawVersion is num) {
      schemaVersion = rawVersion.toInt();
    } else if (rawVersion is String) {
      schemaVersion = int.tryParse(rawVersion) ?? 0;
    }

    if (schemaVersion > kCurrentSchemaVersion) {
      throw ResumeSchemaException(
        'Unsupported schema version $schemaVersion. Current version is $kCurrentSchemaVersion.',
      );
    }

    // Sequential migration pipeline
    while (schemaVersion < kCurrentSchemaVersion) {
      switch (schemaVersion) {
        case 0:
          _migrateV0ToV1(map);
          schemaVersion = 1;
          break;
        default:
          debugPrint('Unknown legacy schema version $schemaVersion during migration.');
          schemaVersion = kCurrentSchemaVersion;
          break;
      }
    }

    map['schemaVersion'] = kCurrentSchemaVersion;
    return map;
  }

  /// Migrates unversioned legacy (v0) resume maps to Schema V1 format.
  static void _migrateV0ToV1(Map<String, dynamic> map) {
    map['schemaVersion'] = 1;
    map['templateId'] ??= 'modern_classic';
    map['title'] ??= 'Untitled Resume';

    if (map['personalInfo'] == null || map['personalInfo'] is! Map) {
      map['personalInfo'] = <String, dynamic>{};
    }
    if (map['summary'] == null || map['summary'] is! Map) {
      map['summary'] = <String, dynamic>{};
    }

    // Ensure list collections are non-null lists
    const listKeys = [
      'experiences',
      'educationList',
      'projects',
      'skills',
      'certifications',
      'languages',
      'customSections',
      'socialLinks',
    ];

    for (final key in listKeys) {
      if (map[key] == null || map[key] is! List) {
        map[key] = <dynamic>[];
      }
    }
  }
}
