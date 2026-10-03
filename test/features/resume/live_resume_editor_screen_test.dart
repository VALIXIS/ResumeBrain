import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:printing/printing.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/resume/screens/live_resume_editor_screen.dart';

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
  group('LiveResumeEditorScreen & PdfExportConfig Tests', () {
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

    testWidgets('LiveResumeEditorScreen renders dual panes on wide screen (desktop/tablet)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: LiveResumeEditorScreen(resumeId: sampleResume.id),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Check AppBar badge
      expect(find.text('3D STUDIO'), findsOneWidget);

      // In wide mode, both form pane tabs and PdfPreview canvas should exist
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });

    testWidgets('LiveResumeEditorScreen renders toggle view on mobile screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: LiveResumeEditorScreen(resumeId: sampleResume.id),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // On mobile, the responsive bottom bar buttons are present
      expect(find.text('Styling'), findsOneWidget);
      expect(find.text('Live Preview'), findsOneWidget);
    });

    testWidgets('LiveResumeEditorScreen toggles 3D customizer floating panel', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: LiveResumeEditorScreen(resumeId: sampleResume.id),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // The customization pill icon button is present
      final customizePill = find.byTooltip('3D Styling Studio');
      expect(customizePill, findsOneWidget);

      // Tap to open styling controls
      await tester.tap(customizePill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Live Styling Controls'), findsOneWidget);
      expect(find.text('FONT FAMILY'), findsOneWidget);
      expect(find.text('PRIMARY ACCENT COLOR'), findsOneWidget);
    });
  });
}
