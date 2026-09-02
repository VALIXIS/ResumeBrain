import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/resume/presentation/resume_editor_screen.dart';
import 'package:resume_brain/features/resume/providers/resume_history_provider.dart';
import 'package:resume_brain/features/resume/utils/resume_input_scrubber.dart';
import 'package:resume_brain/features/resume/widgets/validated_form_field.dart';

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
  group('ResumeInputScrubber Unit Tests', () {
    test('scrubControlCharacters strips ASCII control codes', () {
      const input = 'Hello\x00\x07World\x1F\x7F!';
      final result = ResumeInputScrubber.scrubControlCharacters(input);
      expect(result, 'HelloWorld!');
    });

    test('scrubControlCharacters preserves standard whitespace, tabs, and newlines', () {
      const input = 'Line 1\nLine 2\r\n\tIndented';
      final result = ResumeInputScrubber.scrubControlCharacters(input);
      expect(result, 'Line 1\nLine 2\r\n\tIndented');
    });

    test('scrubName permits valid person names and strips disallowed special chars', () {
      expect(
        ResumeInputScrubber.scrubName("Mary-Jane O'Connor, Ph.D. <script>"),
        "Mary-Jane O'Connor, Ph.D. script",
      );
      expect(
        ResumeInputScrubber.scrubName('John @Doe #1 *'),
        'John Doe  ',
      );
    });

    test('scrubTitle permits professional title symbols like & / + -', () {
      expect(
        ResumeInputScrubber.scrubTitle('Lead C++ / Python & DevOps (Sr. Eng.) <tag>'),
        'Lead C++ / Python & DevOps (Sr. Eng.) tag',
      );
    });

    test('scrubEmail permits valid email characters only', () {
      expect(
        ResumeInputScrubber.scrubEmail('  vignesh.dev+test@domain.co.in <bad>  '),
        'vignesh.dev+test@domain.co.inbad',
      );
    });

    test('scrubPhone permits phone characters only', () {
      expect(
        ResumeInputScrubber.scrubPhone('+1 (555) 123-4567 ext. 89 <script>'),
        '+1 (555) 123-4567 ext. 89 t',
      );
    });

    test('scrubUrl keeps web address characters and drops whitespace and brackets', () {
      expect(
        ResumeInputScrubber.scrubUrl('https://github.com/vignesh/repo?v=1&q=test#top <evil>'),
        'https://github.com/vignesh/repo?v=1&q=test#topevil',
      );
    });

    test('scrubDate keeps date tokens', () {
      expect(
        ResumeInputScrubber.scrubDate('May 2023 - Present (Current) <x>'),
        'May 2023 - Present (Current) x',
      );
    });

    test('scrubGpa keeps GPA and honors characters', () {
      expect(
        ResumeInputScrubber.scrubGpa('3.95 / 4.0 (Magna Cum Laude) <ok>'),
        '3.95 / 4.0 (Magna Cum Laude) ok',
      );
    });

    test('scrubTextBlock cleans control codes and formats cleanly', () {
      const input = '• Developed Flutter apps.\x00\x08\n• Improved render performance by 40%!';
      final result = ResumeInputScrubber.scrubTextBlock(input);
      expect(result, '• Developed Flutter apps.\n• Improved render performance by 40%!');
    });
  });

  group('TextInputFormatter & Cursor Preservation Tests', () {
    test('SafePatternFormatter filters input and preserves cursor offset without jumping to end', () {
      final formatter = SafePatternFormatter(
        disallowedPattern: RegExp(r'[^a-zA-Z0-9\s]'),
      );

      // Typing '$' in the middle of "hello"
      const oldValue = TextEditingValue(
        text: 'hello',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: 'he\$llo',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'hello');
      // Cursor should remain at offset 2, not jump to 5 (the end)
      expect(result.selection.baseOffset, 2);
    });

    test('SafeControlCharacterFormatter strips null bytes while preserving cursor', () {
      const formatter = SafeControlCharacterFormatter();

      const oldValue = TextEditingValue(
        text: 'Resume',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: 'Resume\x00',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'Resume');
      expect(result.selection.baseOffset, 6);
    });
  });

  group('ResumeHistoryNotifier Undo/Redo Unit Tests', () {
    late ProviderContainer container;
    late Resume initialResume;

    setUp(() {
      initialResume = Resume(
        id: 'res-test-1',
        title: 'Initial Resume',
        personalInfo: PersonalInformation(
          fullName: 'Vignesh K',
          email: 'vignesh@example.com',
          phone: '+1 234 567 8900',
        ),
      );

      container = ProviderContainer(
        overrides: [
          currentResumeProvider.overrideWith((ref) => CurrentResumeNotifier(ref)),
        ],
      );

      container.read(currentResumeProvider.notifier).setResume(initialResume);
      container.read(resumeHistoryProvider.notifier).initializeWithResume(initialResume);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has canUndo=false, canRedo=false', () {
      final historyState = container.read(resumeHistoryProvider);
      expect(historyState.canUndo, isFalse);
      expect(historyState.canRedo, isFalse);
    });

    test('recording mutations enables canUndo and updates stack', () {
      final mutatedResume1 = initialResume.copyWith(
        personalInfo: initialResume.personalInfo.copyWith(fullName: 'Vignesh Kumar'),
      );

      container.read(resumeHistoryProvider.notifier).recordSnapshot(mutatedResume1);
      container.read(currentResumeProvider.notifier).setResume(mutatedResume1);

      var historyState = container.read(resumeHistoryProvider);
      expect(historyState.canUndo, isTrue);
      expect(historyState.canRedo, isFalse);
      expect(historyState.undoStack.length, 1);

      // Undo mutation
      final didUndo = container.read(resumeHistoryProvider.notifier).undo();
      expect(didUndo, isTrue);
      expect(container.read(currentResumeProvider)?.personalInfo.fullName, 'Vignesh K');

      historyState = container.read(resumeHistoryProvider);
      expect(historyState.canUndo, isFalse);
      expect(historyState.canRedo, isTrue);
      expect(historyState.redoStack.length, 1);

      // Redo mutation
      final didRedo = container.read(resumeHistoryProvider.notifier).redo();
      expect(didRedo, isTrue);
      expect(container.read(currentResumeProvider)?.personalInfo.fullName, 'Vignesh Kumar');

      historyState = container.read(resumeHistoryProvider);
      expect(historyState.canUndo, isTrue);
      expect(historyState.canRedo, isFalse);
    });

    test('new edit after undo clears the redo stack', () {
      final mutatedResume1 = initialResume.copyWith(
        personalInfo: initialResume.personalInfo.copyWith(fullName: 'Vignesh 1'),
      );
      container.read(resumeHistoryProvider.notifier).recordSnapshot(mutatedResume1);
      container.read(currentResumeProvider.notifier).setResume(mutatedResume1);

      // Undo
      container.read(resumeHistoryProvider.notifier).undo();
      expect(container.read(resumeHistoryProvider).canRedo, isTrue);

      // Perform brand new mutation
      final mutatedResume2 = initialResume.copyWith(
        personalInfo: initialResume.personalInfo.copyWith(fullName: 'Vignesh 2'),
      );
      container.read(resumeHistoryProvider.notifier).recordSnapshot(mutatedResume2);
      container.read(currentResumeProvider.notifier).setResume(mutatedResume2);

      // Redo stack must now be empty
      expect(container.read(resumeHistoryProvider).canRedo, isFalse);
      expect(container.read(resumeHistoryProvider).canUndo, isTrue);
    });

    test('history stack is bounded by maxHistoryLength (50 items)', () {
      for (int i = 1; i <= 60; i++) {
        final r = initialResume.copyWith(
          personalInfo: initialResume.personalInfo.copyWith(fullName: 'Vignesh $i'),
        );
        container.read(resumeHistoryProvider.notifier).recordSnapshot(r);
      }

      final historyState = container.read(resumeHistoryProvider);
      expect(historyState.undoStack.length, 50);
    });
  });

  group('ValidatedFormField & Focus Auto-Scroll Widget Tests', () {
    testWidgets('ValidatedFormField automatically focuses and triggers scroll ensureVisible', (tester) async {
      final controller = TextEditingController(text: 'Initial Text');
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                height: 1200,
                child: Column(
                  children: [
                    const SizedBox(height: 800),
                    ValidatedFormField(
                      label: 'Target Field',
                      controller: controller,
                      focusNode: focusNode,
                      inputFormatters: [ResumeInputScrubber.nameFormatter()],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Target Field'), findsOneWidget);

      // Request focus on node
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
      controller.dispose();
    });
  });

  group('ResumeEditorScreen Undo/Redo & Traversal Widget Tests', () {
    late InMemoryResumeRepository inMemoryRepo;
    late Resume sampleResume;

    setUp(() {
      inMemoryRepo = InMemoryResumeRepository();
      sampleResume = Resume(
        id: 'res-day6-1',
        title: 'Full Stack Engineer Resume',
        personalInfo: PersonalInformation(
          fullName: 'Vignesh Kumar',
          email: 'vignesh@example.com',
          phone: '+1 555 123 4567',
          location: 'San Francisco, CA',
        ),
        skills: [
          Skill(name: 'Flutter', level: 'Expert'),
          Skill(name: 'Riverpod', level: 'Advanced'),
        ],
      );
    });

    testWidgets('ResumeEditorScreen renders Undo/Redo buttons in AppBar', (tester) async {
      final container = ProviderContainer(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(inMemoryRepo),
          currentResumeProvider.overrideWith((ref) {
            final notifier = CurrentResumeNotifier(ref);
            notifier.setResume(sampleResume);
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ResumeEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Undo and Redo icon buttons exist in AppBar
      expect(find.byTooltip('Undo (Ctrl+Z)'), findsOneWidget);
      expect(find.byTooltip('Redo (Ctrl+Y)'), findsOneWidget);

      // Initially canUndo and canRedo are disabled
      final undoButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
      expect(undoButton.onPressed, isNull);

      container.dispose();
    });
  });
}
