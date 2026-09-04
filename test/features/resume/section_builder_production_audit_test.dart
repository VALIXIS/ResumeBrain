import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/core/widgets/custom_button.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/resume/providers/resume_history_provider.dart';
import 'package:resume_brain/features/resume/utils/resume_input_scrubber.dart';
import 'package:resume_brain/features/resume/widgets/certification_editor_dialog.dart';
import 'package:resume_brain/features/resume/widgets/education_editor_dialog.dart';
import 'package:resume_brain/features/resume/widgets/language_editor_dialog.dart';
import 'package:resume_brain/features/resume/widgets/project_editor_dialog.dart';
import 'package:resume_brain/features/resume/widgets/reorderable_section_card.dart';
import 'package:resume_brain/features/resume/widgets/resume_validators.dart';

class InMemoryAuditResumeRepository implements ResumeRepository {
  final Map<String, Resume> _resumes = {};

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
  group('Day 7 Audit — Resume Edge Cases & Validation Matrix', () {
    test('Empty resume creation and minimal field access does not throw', () {
      final emptyResume = Resume(id: 'empty-1', title: '');
      expect(emptyResume.personalInfo.fullName, isEmpty);
      expect(emptyResume.experiences, isEmpty);
      expect(emptyResume.educationList, isEmpty);
      expect(emptyResume.skills, isEmpty);
      expect(emptyResume.projects, isEmpty);
      expect(emptyResume.certifications, isEmpty);
      expect(emptyResume.languages, isEmpty);
      expect(emptyResume.customSections, isEmpty);
    });

    test('Resume with single section vs many sections behaves stably', () {
      final singleSecResume = Resume(
        id: 'single-1',
        title: 'One Section',
        skills: [Skill(name: 'Flutter')],
      );
      expect(singleSecResume.skills.length, equals(1));

      final manySecResume = singleSecResume.copyWith(
        experiences: List.generate(
          15,
          (i) => Experience(
            company: 'Company $i',
            position: 'Role $i',
            startDate: '202$i',
            endDate: 'Present',
            isCurrent: true,
          ),
        ),
        customSections: List.generate(
          10,
          (i) => CustomSection(
            title: 'Custom Section $i',
            items: ['Bullet 1', 'Bullet 2', 'Bullet 3'],
          ),
        ),
      );
      expect(manySecResume.experiences.length, equals(15));
      expect(manySecResume.customSections.length, equals(10));
    });

    test('Empty optional fields validation returns null (valid)', () {
      expect(ResumeValidators.validateOptionalLength(null, 'Location'), isNull);
      expect(ResumeValidators.validateOptionalLength('', 'Location'), isNull);
      expect(ResumeValidators.validateOptionalLength('   ', 'Location'), isNull);
      expect(ResumeValidators.validateEmail(null), isNull);
      expect(ResumeValidators.validateEmail(''), isNull);
      expect(ResumeValidators.validatePhone(null), isNull);
      expect(ResumeValidators.validatePhone(''), isNull);
      expect(ResumeValidators.validateUrl(null), isNull);
      expect(ResumeValidators.validateUrl(''), isNull);
      expect(ResumeValidators.validateGpa(null), isNull);
      expect(ResumeValidators.validateGpa(''), isNull);
      expect(ResumeValidators.validateDate(null, 'End date', isRequired: false), isNull);
    });

    test('Required fields validation accurately rejects missing or too short values', () {
      expect(ResumeValidators.validateRequired(null, 'Full Name'), contains('is required'));
      expect(ResumeValidators.validateRequired('', 'Full Name'), contains('is required'));
      expect(ResumeValidators.validateRequired('A', 'Full Name', minLength: 2), contains('at least 2'));
      expect(ResumeValidators.validateRequired('John Doe', 'Full Name'), isNull);
    });

    test('Date range validation handles ongoing and current jobs safely', () {
      expect(ResumeValidators.validateDateRange('2020', '2023'), isNull);
      expect(ResumeValidators.validateDateRange('2023', '2020'), contains('cannot be earlier'));
      expect(ResumeValidators.validateDateRange('2023', 'Present', isCurrent: true), isNull);
      expect(ResumeValidators.validateDateRange('2023', 'Present', isCurrent: false), isNull);
    });
  });

  group('Day 7 Audit — Riverpod State Management & Undo/Redo Invariants', () {
    late ProviderContainer container;
    late InMemoryAuditResumeRepository repo;
    late Resume testResume;

    setUp(() {
      repo = InMemoryAuditResumeRepository();
      container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(repo),
          currentResumeProvider.overrideWith((ref) => CurrentResumeNotifier(ref)),
        ],
      );
      testResume = Resume(
        id: 'audit-resume-101',
        title: 'Senior Engineer Resume',
        personalInfo: PersonalInformation(fullName: 'Vignesh', email: 'vignesh@test.com'),
        skills: [Skill(name: 'Dart')],
      );
      container.read(currentResumeProvider.notifier).setResume(testResume);
      container.read(resumeHistoryProvider.notifier).initializeWithResume(testResume);
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo with empty history returns false safely without modifying state', () {
      final didUndo = container.read(resumeHistoryProvider.notifier).undo();
      expect(didUndo, isFalse);
      expect(container.read(currentResumeProvider)?.title, equals('Senior Engineer Resume'));
    });

    test('Redo with empty history returns false safely without modifying state', () {
      final didRedo = container.read(resumeHistoryProvider.notifier).redo();
      expect(didRedo, isFalse);
      expect(container.read(currentResumeProvider)?.title, equals('Senior Engineer Resume'));
    });

    test('Consecutive mutations, sequential undo, and sequential redo restore exact valid states', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final historyNotifier = container.read(resumeHistoryProvider.notifier);

      // Mutation 1: Title update
      notifier.updateResume((r) => r.copyWith(title: 'Lead Architect Resume'));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      // Mutation 2: Add Skill
      notifier.updateResume((r) => r.copyWith(skills: [...r.skills, Skill(name: 'Flutter')]));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      // Mutation 3: Add Certification
      notifier.updateResume((r) => r.copyWith(certifications: [
            Certification(name: 'GCP Cloud Architect', issuingOrganization: 'Google', issueDate: '2024')
          ]));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      expect(container.read(currentResumeProvider)?.title, equals('Lead Architect Resume'));
      expect(container.read(currentResumeProvider)?.skills.length, equals(2));
      expect(container.read(currentResumeProvider)?.certifications.length, equals(1));
      expect(container.read(resumeHistoryProvider).undoStack.length, equals(3));

      // Undo 3
      expect(historyNotifier.undo(), isTrue);
      expect(container.read(currentResumeProvider)?.certifications, isEmpty);
      expect(container.read(currentResumeProvider)?.skills.length, equals(2));

      // Undo 2
      expect(historyNotifier.undo(), isTrue);
      expect(container.read(currentResumeProvider)?.skills.length, equals(1));
      expect(container.read(currentResumeProvider)?.title, equals('Lead Architect Resume'));

      // Undo 1
      expect(historyNotifier.undo(), isTrue);
      expect(container.read(currentResumeProvider)?.title, equals('Senior Engineer Resume'));

      // Cannot undo further
      expect(historyNotifier.undo(), isFalse);

      // Redo 1
      expect(historyNotifier.redo(), isTrue);
      expect(container.read(currentResumeProvider)?.title, equals('Lead Architect Resume'));

      // Redo 2
      expect(historyNotifier.redo(), isTrue);
      expect(container.read(currentResumeProvider)?.skills.length, equals(2));

      // Redo 3
      expect(historyNotifier.redo(), isTrue);
      expect(container.read(currentResumeProvider)?.certifications.length, equals(1));

      // Cannot redo further
      expect(historyNotifier.redo(), isFalse);
    });

    test('New edit after undo invalidates redo stack completely', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final historyNotifier = container.read(resumeHistoryProvider.notifier);

      notifier.updateResume((r) => r.copyWith(title: 'State 1'));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      notifier.updateResume((r) => r.copyWith(title: 'State 2'));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      // Undo back to State 1
      expect(historyNotifier.undo(), isTrue);
      expect(container.read(currentResumeProvider)?.title, equals('State 1'));
      expect(container.read(resumeHistoryProvider).canRedo, isTrue);

      // New branch of edits: State 3
      notifier.updateResume((r) => r.copyWith(title: 'State 3'));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));

      expect(container.read(resumeHistoryProvider).canRedo, isFalse);
      expect(container.read(resumeHistoryProvider).canUndo, isTrue);
      expect(container.read(currentResumeProvider)?.title, equals('State 3'));
    });

    test('Switching active resume clears previous resume history stack', () {
      final historyNotifier = container.read(resumeHistoryProvider.notifier);
      final notifier = container.read(currentResumeProvider.notifier);

      notifier.updateResume((r) => r.copyWith(title: 'Edited Resume 1'));
      historyNotifier.recordSnapshot(container.read(currentResumeProvider));
      expect(container.read(resumeHistoryProvider).canUndo, isTrue);

      // Switch to Resume 2
      final resume2 = Resume(id: 'audit-resume-202', title: 'Resume Two');
      historyNotifier.initializeWithResume(resume2);

      expect(container.read(resumeHistoryProvider).canUndo, isFalse);
      expect(container.read(resumeHistoryProvider).canRedo, isFalse);
    });
  });

  group('Day 7 Audit — Special Character Scrubbing & Unicode Preservation', () {
    test('Name scrubber preserves international names, accents, and hyphenated names', () {
      expect(ResumeInputScrubber.scrubName('Björn Sörensen-O\'Hagan, M.Sc.'), 'Björn Sörensen-O\'Hagan, M.Sc.');
      expect(ResumeInputScrubber.scrubName('Élodie René-Dupont'), 'Élodie René-Dupont');
      expect(ResumeInputScrubber.scrubName('李小龙 <alert>'), '李小龙 alert');
      expect(ResumeInputScrubber.scrubName('John123#\$%Doe'), 'JohnDoe');
    });

    test('Email scrubber strips spaces and illegal characters without breaking valid formats', () {
      expect(ResumeInputScrubber.scrubEmail('  john.doe+aws@valixis.co.uk  '), 'john.doe+aws@valixis.co.uk');
      expect(ResumeInputScrubber.scrubEmail('user@domain.com<script>'), 'user@domain.comscript');
    });

    test('Phone scrubber permits +, -, (), spaces, and extensions', () {
      expect(ResumeInputScrubber.scrubPhone('+1 (800) 555-0199 ext. 42'), '+1 (800) 555-0199 ext. 42');
      expect(ResumeInputScrubber.scrubPhone('+44 20 7946 0991'), '+44 20 7946 0991');
      expect(ResumeInputScrubber.scrubPhone('abc+1-555-xyz'), '+1-555-x');
    });

    test('URL scrubber strips whitespace and quotes while preserving paths and query params', () {
      expect(
        ResumeInputScrubber.scrubUrl('  https://github.com/vignesh/project?tab=readme#overview  '),
        'https://github.com/vignesh/project?tab=readme#overview',
      );
    });

    test('TextBlock scrubber strips control and zero-width codes while preserving bullets and code symbols', () {
      const complexText = '• Architected C++ / Python pipeline.\x00\x1F\n'
          '• Achieved 99.9% uptime (\$1.2M cost savings).\n'
          '• Used Docker & Kubernetes (K8s) for CI/CD.';
      final cleaned = ResumeInputScrubber.scrubTextBlock(complexText);
      expect(cleaned, contains('• Architected C++ / Python pipeline.\n'));
      expect(cleaned, contains('\$1.2M cost savings'));
      expect(cleaned, contains('& Kubernetes (K8s)'));
      expect(cleaned.contains('\x00'), isFalse);
      expect(cleaned.contains('\x1F'), isFalse);
    });
  });

  group('Day 7 Audit — Section Dialogs & UI Flow Verification', () {
    testWidgets('CertificationEditorDialog validates required fields and emits onSave', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Certification? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CertificationEditorDialog.show(
                  context: ctx,
                  onSave: (c) => saved = c,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CertificationEditorDialog), findsOneWidget);

      // Save directly without filling -> should fail validation
      await tester.tap(find.widgetWithText(AppButton, 'Add Certification'));
      await tester.pumpAndSettle();
      expect(saved, isNull);

      // Fill in required fields
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'CKA - Certified Kubernetes Administrator');
      await tester.enterText(fields.at(1), 'Linux Foundation / CNCF');
      await tester.enterText(fields.at(2), '05/2023');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Add Certification'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, equals('CKA - Certified Kubernetes Administrator'));
      expect(saved!.issuingOrganization, equals('Linux Foundation / CNCF'));
      expect(saved!.issueDate, equals('05/2023'));
    });

    testWidgets('EducationEditorDialog validates and creates Education entry', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Education? savedEdu;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EducationEditorDialog.show(
                  context: ctx,
                  onSave: (e) => savedEdu = e,
                ),
                child: const Text('Open Edu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edu'));
      await tester.pumpAndSettle();

      expect(find.byType(EducationEditorDialog), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'MIT');
      await tester.enterText(fields.at(1), 'Master of Science');
      await tester.enterText(fields.at(2), 'Computer Science');
      await tester.enterText(fields.at(3), '2021');
      await tester.enterText(fields.at(4), '2023');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Add Education'));
      await tester.pumpAndSettle();

      expect(savedEdu, isNotNull);
      expect(savedEdu!.institution, equals('MIT'));
      expect(savedEdu!.degree, equals('Master of Science'));
    });

    testWidgets('LanguageEditorDialog enforces duplicate prevention and saves Language', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Language? savedLang;
      final existing = [Language(id: 'l1', name: 'English', proficiency: 'Native')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => LanguageEditorDialog.show(
                  context: ctx,
                  existingLanguages: existing,
                  onSave: (l) => savedLang = l,
                ),
                child: const Text('Open Lang'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Lang'));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;

      // Try typing duplicate "english"
      await tester.enterText(nameField, 'english');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Add Language'));
      await tester.pumpAndSettle();

      expect(find.text('This language has already been added'), findsOneWidget);
      expect(savedLang, isNull);

      // Type unique language "German"
      await tester.enterText(nameField, 'German');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Add Language'));
      await tester.pumpAndSettle();

      expect(savedLang, isNotNull);
      expect(savedLang!.name, equals('German'));
    });

    testWidgets('ProjectEditorDialog saves valid project with technologies and links', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Project? savedProj;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ProjectEditorDialog.show(
                  context: ctx,
                  onSave: (p) => savedProj = p,
                ),
                child: const Text('Open Project'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectEditorDialog), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ResumeBrain AI Engine');
      await tester.enterText(fields.at(1), 'Lead Architect');
      await tester.enterText(fields.at(2), 'Flutter, Dart, Riverpod');
      await tester.enterText(fields.at(3), 'https://github.com/VALIXIS/ResumeBrain');
      await tester.enterText(fields.at(4), 'Built full-featured AI resume builder with 100% tests.');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Add Project'));
      await tester.pumpAndSettle();

      expect(savedProj, isNotNull);
      expect(savedProj!.name, equals('ResumeBrain AI Engine'));
      expect(savedProj!.role, equals('Lead Architect'));
      expect(savedProj!.link, contains('github.com'));
    });

    testWidgets('ReorderableSectionCard renders drag handle, title, tags, and actions', (tester) async {
      bool edited = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableSectionCard(
              index: 0,
              title: 'Card Title',
              subtitle: 'Card Subtitle',
              description: 'Card Description',
              tags: [
                const Text('Tag1'),
                const Text('Tag2'),
              ],
              onEdit: () => edited = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Subtitle'), findsOneWidget);
      expect(find.text('Card Description'), findsOneWidget);
      expect(find.text('Tag1'), findsOneWidget);
      expect(find.text('Tag2'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(edited, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);
    });
  });
}
