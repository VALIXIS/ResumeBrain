import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/core/widgets/custom_button.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/resume/presentation/section_editor_tab.dart';
import 'package:resume_brain/features/resume/widgets/custom_section_editor_dialog.dart';
import 'package:resume_brain/features/resume/widgets/resume_validators.dart';

class InMemoryResumeRepository implements ResumeRepository {
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
}

void main() {
  group('ResumeValidators - Custom Section Validation Tests', () {
    test('validateSectionTitle accepts valid unique title', () {
      final error = ResumeValidators.validateSectionTitle(
        'Publications & Research',
        existingTitles: ['Work Experience', 'Education'],
      );
      expect(error, isNull);
    });

    test('validateSectionTitle rejects empty and whitespace-only title', () {
      expect(ResumeValidators.validateSectionTitle(''), isNotNull);
      expect(ResumeValidators.validateSectionTitle('   '), isNotNull);
      expect(ResumeValidators.validateSectionTitle(null), isNotNull);
    });

    test('validateSectionTitle enforces min and max length constraints', () {
      expect(ResumeValidators.validateSectionTitle('A'), isNotNull);
      expect(ResumeValidators.validateSectionTitle('A' * 81), isNotNull);
      expect(ResumeValidators.validateSectionTitle('Valid Title'), isNull);
    });

    test('validateSectionTitle detects duplicate titles case-insensitively', () {
      final error = ResumeValidators.validateSectionTitle(
        'publications',
        existingTitles: ['Publications', 'Awards'],
      );
      expect(error, contains('already exists'));
    });

    test('validateSectionTitle allows keeping same title when editing', () {
      final error = ResumeValidators.validateSectionTitle(
        'Publications',
        existingTitles: ['Publications', 'Awards'],
        currentTitle: 'Publications',
      );
      expect(error, isNull);
    });

    test('validateBulletPoint validates length and optionality', () {
      expect(ResumeValidators.validateBulletPoint('Published a paper at NeurIPS 2024'), isNull);
      expect(ResumeValidators.validateBulletPoint(''), isNull);
      expect(ResumeValidators.validateBulletPoint('', isRequired: true), isNotNull);
      expect(ResumeValidators.validateBulletPoint('X' * 501), isNotNull);
    });
  });

  group('Dynamic Custom Section Engine - State Mutation Tests', () {
    late ProviderContainer container;
    late InMemoryResumeRepository inMemoryRepo;

    setUp(() {
      inMemoryRepo = InMemoryResumeRepository();
      container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(inMemoryRepo),
        ],
      );
      final initialResume = Resume(
        id: 'test-resume-1',
        title: 'Software Engineer Resume',
        customSections: [],
      );
      container.read(currentResumeProvider.notifier).setResume(initialResume);
    });

    tearDown(() {
      container.dispose();
    });

    test('Create Publications preset section with bullet points', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final pubSection = CustomSection(
        title: 'Publications & Research',
        items: [
          'Attention is All You Need - Co-author (2023)',
          'Efficient Multi-Modal LLM Fine-Tuning - NeurIPS (2024)',
        ],
      );

      notifier.updateResume((r) => r.copyWith(customSections: [...r.customSections, pubSection]));

      final updatedResume = container.read(currentResumeProvider);
      expect(updatedResume?.customSections.length, equals(1));
      expect(updatedResume?.customSections.first.title, equals('Publications & Research'));
      expect(updatedResume?.customSections.first.items.length, equals(2));
      expect(updatedResume?.customSections.first.items[0], contains('Attention is All You Need'));
    });

    test('Create Volunteer section and independently edit title and bullets', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final volSection = CustomSection(
        title: 'Volunteer Experience',
        items: ['Code.org Volunteer Mentor (2022-Present)'],
      );

      notifier.updateResume((r) => r.copyWith(customSections: [...r.customSections, volSection]));

      // Add a second bullet
      notifier.updateResume((r) {
        final list = List<CustomSection>.from(r.customSections);
        final index = list.indexWhere((s) => s.id == volSection.id);
        list[index] = list[index].copyWith(
          title: 'Community Leadership & Volunteering',
          items: [...list[index].items, 'Organized Open Source Hackathon 2023'],
        );
        return r.copyWith(customSections: list);
      });

      final updatedResume = container.read(currentResumeProvider);
      expect(updatedResume?.customSections.length, equals(1));
      final section = updatedResume!.customSections.first;
      expect(section.title, equals('Community Leadership & Volunteering'));
      expect(section.items.length, equals(2));
      expect(section.items[1], equals('Organized Open Source Hackathon 2023'));
    });

    test('Create Awards section and remove an individual bullet point while preserving order', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final awardSection = CustomSection(
        title: 'Awards & Honors',
        items: [
          '1st Place - Global AI Hackathon (2024)',
          'Dean\'s Honor List (2022-2023)',
          'Employee of the Year (2021)',
        ],
      );

      notifier.updateResume((r) => r.copyWith(customSections: [...r.customSections, awardSection]));

      // Remove the middle bullet (Dean's Honor List)
      notifier.updateResume((r) {
        final list = List<CustomSection>.from(r.customSections);
        final index = list.indexWhere((s) => s.id == awardSection.id);
        final updatedItems = List<String>.from(list[index].items)..removeAt(1);
        list[index] = list[index].copyWith(items: updatedItems);
        return r.copyWith(customSections: list);
      });

      final section = container.read(currentResumeProvider)!.customSections.first;
      expect(section.items.length, equals(2));
      expect(section.items[0], equals('1st Place - Global AI Hackathon (2024)'));
      expect(section.items[1], equals('Employee of the Year (2021)'));
    });

    test('Multiple custom sections coexist without data corruption or collision', () {
      final notifier = container.read(currentResumeProvider.notifier);

      final pub = CustomSection(title: 'Publications', items: ['Paper 1', 'Paper 2']);
      final vol = CustomSection(title: 'Volunteer', items: ['Org A']);
      final awd = CustomSection(title: 'Awards', items: ['Award X', 'Award Y']);
      final custom = CustomSection(title: 'Patents', items: ['US Patent 1234567']);

      notifier.updateResume((r) => r.copyWith(customSections: [pub, vol, awd, custom]));

      var current = container.read(currentResumeProvider)!;
      expect(current.customSections.length, equals(4));

      // Modify only Volunteer section
      notifier.updateResume((r) {
        final list = List<CustomSection>.from(r.customSections);
        final index = list.indexWhere((s) => s.id == vol.id);
        list[index] = list[index].copyWith(items: ['Org A', 'Org B']);
        return r.copyWith(customSections: list);
      });

      current = container.read(currentResumeProvider)!;
      expect(current.customSections[0].items.length, equals(2));
      expect(current.customSections[1].items.length, equals(2)); // updated
      expect(current.customSections[2].items.length, equals(2)); // untouched
      expect(current.customSections[3].items.length, equals(1)); // untouched

      // Delete Publications section
      notifier.updateResume((r) => r.copyWith(
            customSections: r.customSections.where((s) => s.id != pub.id).toList(),
          ));

      current = container.read(currentResumeProvider)!;
      expect(current.customSections.length, equals(3));
      expect(current.customSections.map((s) => s.title).toList(), equals(['Volunteer', 'Awards', 'Patents']));
    });

    test('Custom section reordering works cleanly', () {
      final notifier = container.read(currentResumeProvider.notifier);
      final sec1 = CustomSection(title: 'Section 1', items: ['Item 1']);
      final sec2 = CustomSection(title: 'Section 2', items: ['Item 2']);
      final sec3 = CustomSection(title: 'Section 3', items: ['Item 3']);

      notifier.updateResume((r) => r.copyWith(customSections: [sec1, sec2, sec3]));

      // Move Section 3 to first position
      notifier.updateResume((r) {
        final list = List<CustomSection>.from(r.customSections);
        final item = list.removeAt(2);
        list.insert(0, item);
        return r.copyWith(customSections: list);
      });

      final current = container.read(currentResumeProvider)!;
      expect(current.customSections[0].title, equals('Section 3'));
      expect(current.customSections[1].title, equals('Section 1'));
      expect(current.customSections[2].title, equals('Section 2'));
    });
  });

  group('CustomSectionEditorDialog - Widget Tests', () {
    testWidgets('CustomSectionEditorDialog renders presets, title, and bullet inputs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      CustomSection? savedSection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CustomSectionEditorDialog.show(
                    context: context,
                    existingTitles: ['Certifications'],
                    onSave: (sec) => savedSection = sec,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Section'), findsOneWidget);
      expect(find.text('Publications'), findsOneWidget);
      expect(find.text('Volunteer'), findsOneWidget);
      expect(find.text('Awards'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Bullet Points / Entries'), findsOneWidget);

      // Select 'Publications' preset
      await tester.tap(find.text('Publications'));
      await tester.pumpAndSettle();

      final titleCtrlFinder = find.byType(TextFormField).first;
      expect((tester.widget(titleCtrlFinder) as TextFormField).controller?.text, equals('Publications & Research'));

      // Enter bullet point text
      final bulletField = find.byType(TextFormField).at(1);
      await tester.enterText(bulletField, 'Published NeurIPS paper');
      await tester.pumpAndSettle();

      // Add another bullet point
      await tester.tap(find.widgetWithText(AppButton, 'Add Bullet'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3)); // title + 2 bullets

      final secondBulletField = find.byType(TextFormField).at(2);
      await tester.enterText(secondBulletField, 'Keynote speaker at ICML 2024');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.widgetWithText(AppButton, 'Create Section'));
      await tester.pumpAndSettle();

      expect(savedSection, isNotNull);
      expect(savedSection!.title, equals('Publications & Research'));
      expect(savedSection!.items.length, equals(2));
      expect(savedSection!.items[0], equals('Published NeurIPS paper'));
      expect(savedSection!.items[1], equals('Keynote speaker at ICML 2024'));
    });

    testWidgets('CustomSectionEditorDialog allows editing existing section and removing bullets', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      CustomSection? savedSection;
      final initialSection = CustomSection(
        id: 'existing-sec-1',
        title: 'Volunteer Experience',
        items: ['Item A', 'Item B', 'Item C'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CustomSectionEditorDialog.show(
                    context: context,
                    section: initialSection,
                    onSave: (sec) => savedSection = sec,
                  );
                },
                child: const Text('Edit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Custom Section'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify all 3 bullets loaded
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);

      // Remove the 2nd bullet (Item B)
      final deleteIcons = find.byTooltip('Remove Bullet Point');
      expect(deleteIcons, findsNWidgets(3));
      await tester.tap(deleteIcons.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Item B'), findsNothing);
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);

      // Save changes
      await tester.tap(find.widgetWithText(AppButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(savedSection, isNotNull);
      expect(savedSection!.id, equals('existing-sec-1'));
      expect(savedSection!.items, equals(['Item A', 'Item C']));
    });
  });

  group('SectionEditorTab - Custom Section Integration Tests', () {
    testWidgets('SectionEditorTab displays presets, custom sections, and handles deletion', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final inMemoryRepo = InMemoryResumeRepository();
      final container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(inMemoryRepo),
        ],
      );
      final sampleResume = Resume(
        id: 'resume-int-1',
        title: 'Integration Test Resume',
        customSections: [
          CustomSection(
            id: 'sec-pub-1',
            title: 'Publications & Research',
            items: ['Distributed Transformers Architecture'],
          ),
        ],
      );
      container.read(currentResumeProvider.notifier).setResume(sampleResume);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SectionEditorTab(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom sections header and quick preset action chips
      expect(find.text('Custom Sections'), findsOneWidget);
      expect(find.text('Publications & Research'), findsOneWidget);
      expect(find.text('Distributed Transformers Architecture'), findsOneWidget);
      expect(find.text('Quick Presets: '), findsOneWidget);

      // Scroll to custom section card if needed and tap delete
      final deleteCardBtn = find.byTooltip('Delete Item');
      if (deleteCardBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteCardBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Delete Custom Section'), findsOneWidget);
        await tester.tap(find.widgetWithText(AppButton, 'Delete'));
        await tester.pumpAndSettle();

        final updatedResume = container.read(currentResumeProvider);
        expect(updatedResume?.customSections, isEmpty);
      }
    });
  });
}

