import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/models/resume_schema_migrator.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_database_migrator.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/resume/utils/resume_import_sanitizer.dart';

class MockInMemoryResumeRepository implements ResumeRepository {
  final Map<String, Resume> savedResumes = {};
  int saveCallCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async => savedResumes.values.toList();

  @override
  Future<Resume?> getResumeById(String id) async => savedResumes[id];

  @override
  Future<void> saveResume(Resume resume) async {
    saveCallCount++;
    savedResumes[resume.id] = resume;
  }

  @override
  Future<void> deleteResume(String id) async {
    savedResumes.remove(id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async => CloudSyncResult.unsupported();

  @override
  Future<CloudSyncResult> syncAllToCloud() async => CloudSyncResult.unsupported();
}

void main() {
  group('JSON Schema Versioning & Migration Tests', () {
    test('New Resume instance sets schemaVersion to kCurrentSchemaVersion (1)', () {
      final resume = Resume(title: 'Schema Test Resume');
      expect(resume.schemaVersion, ResumeSchemaMigrator.kCurrentSchemaVersion);
      expect(resume.toMap()['schemaVersion'], 1);
    });

    test('Resume.fromMap seamlessly migrates unversioned legacy (v0) payload to v1', () {
      final legacyMap = <String, dynamic>{
        'id': 'legacy-res-123',
        'title': 'Legacy Unversioned Resume',
        'personalInfo': {
          'fullName': 'Jane Doe',
          'email': 'jane@example.com',
        },
      };

      final resume = Resume.fromMap(legacyMap);
      expect(resume.schemaVersion, 1);
      expect(resume.title, 'Legacy Unversioned Resume');
      expect(resume.personalInfo.fullName, 'Jane Doe');
      expect(resume.templateId, 'modern_classic');
      expect(resume.experiences, isEmpty);
    });

    test('Resume.fromMap throws ResumeSchemaException on unsupported future schema versions', () {
      final futureMap = <String, dynamic>{
        'schemaVersion': 99,
        'id': 'future-res-999',
        'title': 'Future Schema Resume',
      };

      expect(
        () => Resume.fromMap(futureMap),
        throwsA(isA<ResumeSchemaException>()),
      );
    });

    test('Missing optional fields receive safe default values without crashing', () {
      final incompleteMap = <String, dynamic>{
        'schemaVersion': 1,
        'id': 'incomplete-1',
      };

      final resume = Resume.fromMap(incompleteMap);
      expect(resume.title, 'Untitled Resume');
      expect(resume.templateId, 'modern_classic');
      expect(resume.personalInfo.fullName, isEmpty);
      expect(resume.summary.summaryText, isEmpty);
      expect(resume.skills, isEmpty);
    });
  });

  group('Strict Resume Import Sanitizer Tests', () {
    test('Rejects null, non-map, or empty root JSON with ResumeImportException', () {
      expect(
        () => ResumeImportSanitizer.sanitizeResumeJson(null),
        throwsA(isA<ResumeImportException>()),
      );
      expect(
        () => ResumeImportSanitizer.sanitizeResumeJson(['not', 'a', 'map']),
        throwsA(isA<ResumeImportException>()),
      );
      expect(
        () => ResumeImportSanitizer.sanitizeResumeJson(<String, dynamic>{}),
        throwsA(isA<ResumeImportException>()),
      );
    });

    test('Strips control characters and zero-width codes from imported fields', () {
      final rawImport = {
        'id': 'imp-001',
        'title': 'Senior\x00 Developer\x07 Resume\u200B',
        'personalInfo': {
          'fullName': 'Alice\x1F Smith',
          'email': 'alice.smith@example.com\x00',
        },
      };

      final sanitized = ResumeImportSanitizer.sanitizeResumeJson(rawImport);
      expect(sanitized['title'], 'Senior Developer Resume');
      expect(sanitized['personalInfo']['fullName'], 'Alice Smith');
      expect(sanitized['personalInfo']['email'], 'alice.smith@example.com');
    });

    test('Removes embedded script tags from imported text', () {
      final rawImport = {
        'id': 'imp-xss',
        'title': 'Normal Title <script>alert("xss")</script>',
        'summary': {
          'summaryText': 'Experienced engineer <script>console.log("bad")</script> looking for roles.',
        },
      };

      final sanitized = ResumeImportSanitizer.sanitizeResumeJson(rawImport);
      expect(sanitized['title'], 'Normal Title');
      expect(sanitized['summary']['summaryText'], 'Experienced engineer  looking for roles.');
    });

    test('Normalizes invalid enums and template IDs to safe defaults', () {
      final rawImport = {
        'id': 'imp-enum',
        'templateId': 'invalid_fancy_template',
        'skills': [
          {'name': 'Flutter', 'level': 'GodMode'},
        ],
        'languages': [
          {'name': 'English', 'proficiency': 'SuperNative'},
        ],
        'socialLinks': [
          {'platform': 'Tik-Tok-Invalid', 'url': 'https://example.com'},
        ],
      };

      final sanitized = ResumeImportSanitizer.sanitizeResumeJson(rawImport);
      expect(sanitized['templateId'], 'modern_classic');
      expect(sanitized['skills'][0]['level'], 'Intermediate');
      expect(sanitized['languages'][0]['proficiency'], 'Fluent');
      expect(sanitized['socialLinks'][0]['platform'], 'LinkedIn');
    });

    test('Truncates oversized strings and limits max list item count to 100', () {
      final superLongString = 'A' * 15000;
      final oversizedList = List.generate(150, (i) => {'name': 'Skill $i'});

      final rawImport = {
        'id': 'imp-oversized',
        'title': 'Title',
        'summary': {'summaryText': superLongString},
        'skills': oversizedList,
      };

      final sanitized = ResumeImportSanitizer.sanitizeResumeJson(rawImport);
      expect((sanitized['summary']['summaryText'] as String).length, 10000);
      expect((sanitized['skills'] as List).length, 100);
    });

    test('Preserves legitimate international Unicode, URLs, bullet points, and formatting', () {
      final rawImport = {
        'id': 'imp-unicode',
        'title': 'Résumé - François Müller ( Müller & Co. )',
        'personalInfo': {
          'fullName': 'François Müller',
          'website': 'https://müller-portfolio.de/path?a=1&b=2#section',
        },
        'summary': {
          'summaryText': '• Led international team across Munich & Paris.\n• Revenue increased by +25%!',
        },
      };

      final sanitized = ResumeImportSanitizer.sanitizeResumeJson(rawImport);
      final resume = Resume.fromMap(sanitized);

      expect(resume.personalInfo.fullName, 'François Müller');
      expect(resume.personalInfo.website, 'https://müller-portfolio.de/path?a=1&b=2#section');
      expect(resume.summary.summaryText, contains('• Led international team across Munich & Paris.'));
    });
  });

  group('Debounced Auto-Save & Race-Condition Protection Unit Tests', () {
    late MockInMemoryResumeRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockInMemoryResumeRepository();
      container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(mockRepo),
          currentResumeProvider.overrideWith((ref) => CurrentResumeNotifier(
                ref,
                debounceDuration: const Duration(milliseconds: 50),
              )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Rapid consecutive edits result in 1 debounced save write after timer expires', () async {
      final initialResume = Resume(id: 'res-deb-1', title: 'Initial');
      final notifier = container.read(currentResumeProvider.notifier);

      notifier.setResume(initialResume);
      expect(mockRepo.saveCallCount, 0);

      // Perform 5 rapid consecutive edits
      for (int i = 1; i <= 5; i++) {
        notifier.updateResume((r) => r.copyWith(title: 'Edit $i'));
      }

      expect(notifier.isSavePending, isTrue);
      expect(mockRepo.saveCallCount, 0);

      // Wait for debounce duration to expire
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.isSavePending, isFalse);
      expect(mockRepo.saveCallCount, 1);

      final saved = await mockRepo.getResumeById('res-deb-1');
      expect(saved?.title, 'Edit 5');
    });

    test('flushPendingSave triggers immediate save without waiting for timer expiration', () async {
      final initialResume = Resume(id: 'res-flush-1', title: 'Initial');
      final notifier = container.read(currentResumeProvider.notifier);

      notifier.setResume(initialResume);
      notifier.updateResume((r) => r.copyWith(title: 'Flushed Edit'));

      expect(notifier.isSavePending, isTrue);
      expect(mockRepo.saveCallCount, 0);

      await notifier.flushPendingSave();

      expect(notifier.isSavePending, isFalse);
      expect(mockRepo.saveCallCount, 1);
      expect(mockRepo.savedResumes['res-flush-1']?.title, 'Flushed Edit');
    });

    test('setResume cancels pending debounce timer from pre-import/previous resume state', () async {
      final resume1 = Resume(id: 'res-1', title: 'Old Resume');
      final resume2 = Resume(id: 'res-2', title: 'Newly Imported Resume');

      final notifier = container.read(currentResumeProvider.notifier);

      notifier.setResume(resume1);
      notifier.updateResume((r) => r.copyWith(title: 'Stale Edit'));
      expect(notifier.isSavePending, isTrue);

      // Import / switch to resume2 before timer expires
      notifier.setResume(resume2);
      expect(notifier.isSavePending, isFalse);

      await Future.delayed(const Duration(milliseconds: 150));

      // Ensure stale edit for res-1 was never saved
      expect(mockRepo.savedResumes.containsKey('res-1'), isFalse);
    });

    test('Revision token protects against overwriting newer state during async save', () async {
      final initialResume = Resume(id: 'res-race-1', title: 'Base');
      final notifier = container.read(currentResumeProvider.notifier);

      notifier.setResume(initialResume);
      final initialRevision = notifier.revisionToken;

      notifier.updateResume((r) => r.copyWith(title: 'Edit 1'));
      expect(notifier.revisionToken, initialRevision + 1);

      notifier.updateResume((r) => r.copyWith(title: 'Edit 2'));
      expect(notifier.revisionToken, initialRevision + 2);

      await notifier.flushPendingSave();
      expect(notifier.lastSavedRevision, notifier.revisionToken);
    });
  });

  group('Hive Database Schema Migrator Integration Tests', () {
    test('ResumeDatabaseMigrator constant is 1 and version key is __schema_version__', () {
      expect(ResumeDatabaseMigrator.kCurrentDatabaseVersion, 1);
      expect(ResumeDatabaseMigrator.kDbVersionKey, '__schema_version__');
    });
  });
}
