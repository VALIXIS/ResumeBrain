import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/resume/presentation/resume_editor_screen.dart';

class InMemoryLiveResumeRepository implements ResumeRepository {
  final Map<String, Resume> _resumes = {};

  InMemoryLiveResumeRepository([List<Resume>? initial]) {
    if (initial != null) {
      for (final r in initial) {
        _resumes[r.id] = r;
      }
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async => _resumes.values.toList();

  @override
  Future<Resume?> getResumeById(String id) async => _resumes[id];

  @override
  Future<void> saveResume(Resume resume) async {
    _resumes[resume.id] = resume;
  }

  @override
  Future<void> deleteResume(String id) async {
    _resumes.remove(id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async {
    return CloudSyncResult.unsupported();
  }

  @override
  Future<CloudSyncResult> syncAllToCloud() async {
    return CloudSyncResult.unsupported();
  }
}

void main() {
  group('ResumeEditorScreen Navigation & PdfExportConfig Tests', () {
    late Resume sampleResume;
    late InMemoryLiveResumeRepository fakeRepo;

    setUp(() {
      sampleResume = Resume(
        id: 'test-live-1',
        title: 'Full Stack Engineer',
        personalInfo: PersonalInformation(
          fullName: 'Alex Morgan',
          email: 'alex.morgan@example.com',
          phone: '+1 555 0199',
          location: 'San Francisco, CA',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Experienced mobile systems architect.',
        ),
        experiences: [
          Experience(
            id: 'exp-1',
            company: 'Tech Corp',
            position: 'Lead Architect',
            startDate: '2021',
            endDate: 'Present',
            description: 'Designed microservices architecture.',
          ),
        ],
        skills: [
          Skill(name: 'Dart'),
          Skill(name: 'Flutter'),
          Skill(name: 'Cloud Architecture'),
        ],
      );
      fakeRepo = InMemoryLiveResumeRepository([sampleResume]);
    });

    test('PdfExportConfig extension properties calculate expected insets and colors', () {
      const config = PdfExportConfig(
        marginOption: PdfMarginOption.normal,
        customMargin: 24.0,
        lineHeight: 1.4,
        customPrimaryColor: Color(0xFF1E88E5),
      );

      expect(config.insets.left, equals(24.0));
      expect(config.insets.right, equals(24.0));
      expect(config.lineHeight, equals(1.4));
      expect(config.resolvedPdfColor, isNotNull);
    });

    testWidgets('ResumeEditorScreen renders Preview, Template, and Next bottom buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(fakeRepo),
            currentResumeProvider.overrideWith((ref) {
              final notifier = CurrentResumeNotifier(ref);
              notifier.setResume(sampleResume);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: ResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the 3 bottom bar options exist
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Template'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify 3D Studio button is removed
      expect(find.text('3D Studio'), findsNothing);
    });

    testWidgets('Tapping Next button in ResumeEditorScreen advances to the next section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(fakeRepo),
            currentResumeProvider.overrideWith((ref) {
              final notifier = CurrentResumeNotifier(ref);
              notifier.setResume(sampleResume);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: ResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Next button and tap it
      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
      } else {
        await tester.tap(find.text('Next'));
      }
      await tester.pumpAndSettle();

      // Verify we are now on the Summary tab
      expect(find.text('Professional Summary'), findsWidgets);
    });
  });
}
