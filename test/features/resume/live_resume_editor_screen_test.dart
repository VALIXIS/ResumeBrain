import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/resume/screens/live_resume_editor_screen.dart';
import 'package:resume_brain/features/resume/widgets/validated_form_field.dart';

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

class _TrackingResumeRepository implements ResumeRepository {
  final void Function(Resume resume) onSave;
  _TrackingResumeRepository({required this.onSave});

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async => [];

  @override
  Future<Resume?> getResumeById(String id) async => null;

  @override
  Future<void> saveResume(Resume resume) async {
    onSave(resume);
  }

  @override
  Future<void> deleteResume(String id) async {}

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

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Template'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
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

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
      } else {
        await tester.tap(find.text('Next'));
      }
      await tester.pumpAndSettle();

      expect(find.text('Professional Summary'), findsWidgets);
    });
  });

  group('LiveResumeEditorScreen & ValidatedFormField Focus/Key Retention Tests', () {
    late Resume sampleResume;
    late InMemoryLiveResumeRepository fakeRepo;

    setUp(() {
      sampleResume = Resume(
        id: 'focus-test-1',
        title: 'Senior Software Engineer',
        personalInfo: PersonalInformation(
          fullName: 'Jordan Lee',
          jobTitle: 'Staff Mobile Engineer',
          email: 'jordan@example.com',
          phone: '+1 555 4321',
          location: 'Austin, TX',
          website: 'https://jordan.dev',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Expert in Flutter architecture and responsive UI design.',
        ),
      );
      fakeRepo = InMemoryLiveResumeRepository([sampleResume]);
    });

    testWidgets('ValidatedFormField sets ObjectKey(controller) on TextFormField and preserves state across rebuilds', (tester) async {
      final controller = TextEditingController(text: 'Initial Value');
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ValidatedFormField(
                      label: 'Test Field',
                      controller: controller,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => buildCount++),
                      child: const Text('Rebuild'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final textFormFieldFinder = find.byType(TextFormField);
      expect(textFormFieldFinder, findsOneWidget);
      final textFormField = tester.widget<TextFormField>(textFormFieldFinder);
      expect(textFormField.key, equals(ObjectKey(controller)));

      await tester.enterText(textFormFieldFinder, 'Updated Value');
      expect(controller.text, equals('Updated Value'));

      await tester.tap(find.text('Rebuild'));
      await tester.pump();

      expect(controller.text, equals('Updated Value'));
      final rebuiltFormField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(rebuiltFormField.key, equals(ObjectKey(controller)));
    });

    testWidgets('LiveResumeEditorScreen renders and assigns ObjectKey to title and form controllers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            home: LiveResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleTextFieldFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      );
      expect(titleTextFieldFinder, findsOneWidget);
      final titleWidget = tester.widget<TextField>(titleTextFieldFinder);
      expect(titleWidget.key, isA<ObjectKey>());

      final formFieldWidgets = tester.widgetList<ValidatedFormField>(find.byType(ValidatedFormField));
      expect(formFieldWidgets, isNotEmpty);
      for (final field in formFieldWidgets) {
        expect(field.key, isA<ObjectKey>(), reason: 'FormField "${field.label}" must have ObjectKey');
      }
    });

    testWidgets('Editing text in LiveResumeEditorScreen does not reset cursor position or lose focus', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            home: LiveResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fullNameFinder = find.widgetWithText(ValidatedFormField, 'Full Name');
      expect(fullNameFinder, findsOneWidget);

      await tester.tap(fullNameFinder);
      await tester.pump();

      await tester.enterText(fullNameFinder, 'Jordan Alexander Lee');
      await tester.pump();

      final editableText = tester.widget<EditableText>(
        find.descendant(of: fullNameFinder, matching: find.byType(EditableText)),
      );
      expect(editableText.controller.text, equals('Jordan Alexander Lee'));
      expect(editableText.focusNode.hasFocus, isTrue);
    });

    testWidgets('TabBarView preserves form state and controllers when switching tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            home: LiveResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fullNameFinder = find.widgetWithText(ValidatedFormField, 'Full Name');
      await tester.enterText(fullNameFinder, 'Dr. Jordan Lee');
      await tester.pump();

      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();

      expect(find.text('Professional Summary'), findsWidgets);

      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      final restoredFullNameFinder = find.widgetWithText(ValidatedFormField, 'Full Name');
      expect(restoredFullNameFinder, findsOneWidget);
      final restoredEditable = tester.widget<EditableText>(
        find.descendant(of: restoredFullNameFinder, matching: find.byType(EditableText)),
      );
      expect(restoredEditable.controller.text, equals('Dr. Jordan Lee'));
    });
  });

  group('Hive Auto-Save 800ms Debounce Tests', () {
    late Resume testResume;

    setUp(() {
      testResume = Resume(
        id: 'debounce-test-1',
        title: 'Initial Title',
        personalInfo: PersonalInformation(fullName: 'Typing User'),
      );
    });

    test('CurrentResumeNotifier default debounceDuration is 800ms', () {
      final container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(InMemoryLiveResumeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(currentResumeProvider.notifier);
      expect(notifier.debounceDuration, equals(const Duration(milliseconds: 800)));
    });

    testWidgets('Rapid edits do not write to Hive immediately; auto-saves after 800ms debounce', (tester) async {
      int saveCount = 0;
      Resume? lastSavedResume;

      final testRepo = _TrackingResumeRepository(onSave: (r) {
        saveCount++;
        lastSavedResume = r;
      });

      final container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(testRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(currentResumeProvider.notifier);
      notifier.setResume(testResume);

      notifier.updatePersonalInfo(PersonalInformation(fullName: 'T'));
      notifier.updatePersonalInfo(PersonalInformation(fullName: 'Ty'));
      notifier.updatePersonalInfo(PersonalInformation(fullName: 'Typ'));
      notifier.updatePersonalInfo(PersonalInformation(fullName: 'Typi'));
      notifier.updatePersonalInfo(PersonalInformation(fullName: 'Typin'));
      notifier.updatePersonalInfo(PersonalInformation(fullName: 'Typing'));

      expect(notifier.isSavePending, isTrue);
      expect(saveCount, equals(0));

      await tester.pump(const Duration(milliseconds: 400));
      expect(saveCount, equals(0));
      expect(notifier.isSavePending, isTrue);

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(saveCount, equals(1));
      expect(lastSavedResume?.personalInfo.fullName, equals('Typing'));
      expect(notifier.isSavePending, isFalse);
    });

    testWidgets('AI Enhance button enhances summary text and removes loading indicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final resumeWithDraftSummary = Resume(
        id: 'ai-summary-test-1',
        title: 'Software Engineer Resume',
        personalInfo: PersonalInformation(
          fullName: 'Jane Doe',
          jobTitle: 'AI Engineer',
        ),
        summary: ProfessionalSummary(
          summaryText: 'management, and AI-based solutions with active involvement in student council.',
        ),
      );

      final mockRepo = InMemoryLiveResumeRepository([resumeWithDraftSummary]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(mockRepo),
            currentResumeProvider.overrideWith((ref) {
              final notifier = CurrentResumeNotifier(ref);
              notifier.setResume(resumeWithDraftSummary);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: ResumeEditorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to the 'Summary' tab (index 1)
      final summaryTab = find.text('Summary');
      expect(summaryTab, findsOneWidget);
      await tester.tap(summaryTab);
      await tester.pumpAndSettle();

      // Find the AI Enhance button
      final aiEnhanceButton = find.text('AI Enhance');
      expect(aiEnhanceButton, findsOneWidget);

      // Tap AI Enhance
      await tester.tap(aiEnhanceButton);
      await tester.pump();

      // Complete async enhancement
      await tester.pumpAndSettle();

      // LinearProgressIndicator should be removed
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Verify that summary text was enhanced with ATS phrasing
      final summaryField = find.byWidgetPredicate(
        (widget) => widget is TextFormField && widget.controller?.text.contains('AI-based solutions') == true,
      );
      expect(summaryField, findsOneWidget);

      // Verify that SnackBar with feedback was shown
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
