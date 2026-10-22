import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/features/job_matching/presentation/job_description_input_screen.dart';
import 'package:resume_brain/features/job_matching/controllers/job_matching_controller.dart';
import 'package:resume_brain/features/job_matching/models/job_description.dart';
import 'package:resume_brain/data/models/resume_models.dart';

class FakeJobMatchingController extends JobMatchingController {
  int submitCallsCount = 0;
  String? lastSubmittedDescription;

  @override
  Future<void> submitJobDescriptionWithResume(
    String description, {
    String? title,
    String? url,
    Resume? resume,
    List<String>? userSkills,
  }) async {
    submitCallsCount++;
    lastSubmittedDescription = description;
    state = state.copyWith(isLoading: true);

    await Future.delayed(Duration.zero);

    final job = JobDescription(
      descriptionText: description,
      title: title ?? 'Target Job Description',
      url: url,
    );
    state = state.copyWith(
      isLoading: false,
      currentJob: job,
      jobDescriptions: [...state.jobDescriptions, job],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeJobMatchingController fakeController;

  setUp(() {
    fakeController = FakeJobMatchingController();
  });

  Widget buildTestWidget({
    required List<Override> overrides,
    VoidCallback? onSuccess,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: JobDescriptionInputScreen(
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  group('JobDescriptionInputScreen Widget Tests', () {
    testWidgets('Initial screen rendering loads successfully and displays all elements', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      // Verify the AppBar Title
      expect(find.text('Job Description Matcher'), findsOneWidget);

      // Verify input text field label and hint
      expect(find.text('Job Description Text'), findsOneWidget);
      expect(find.text('Paste requirements, responsibilities, or skills list here...'), findsOneWidget);

      // Verify the action button
      expect(find.text('Compute Keyword Match'), findsOneWidget);
    });

    testWidgets('Empty input displays local validation error and does not call controller', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      // Verify controller is not called yet
      expect(fakeController.submitCallsCount, equals(0));

      // Tap submit immediately (with empty input)
      final submitButton = find.text('Compute Keyword Match');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify local validation error is displayed
      expect(find.text('Please paste or enter a job description.'), findsOneWidget);

      // Verify that the controller method was NOT called
      expect(fakeController.submitCallsCount, equals(0));
    });

    testWidgets('Whitespace-only input displays local validation error and does not call controller', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      // Enter whitespace-only input
      final textFormField = find.byType(TextFormField);
      await tester.enterText(textFormField, '   \n   \t   ');
      await tester.pump();

      // Tap submit
      final submitButton = find.text('Compute Keyword Match');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify local validation error is displayed
      expect(find.text('Please paste or enter a job description.'), findsOneWidget);

      // Verify that the controller method was NOT called
      expect(fakeController.submitCallsCount, equals(0));
    });

    testWidgets('Valid job description submission calls controller and updates state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      const validText = 'Flutter Developer with 5 years experience in state management and unit testing.';

      // Enter valid job description
      final textFormField = find.byType(TextFormField);
      await tester.enterText(textFormField, validText);
      await tester.pump();

      // Tap submit button
      final submitButton = find.text('Compute Keyword Match');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);

      // Settle the delayed future inside fakeController
      await tester.pumpAndSettle();

      expect(fakeController.submitCallsCount, equals(1));
      expect(fakeController.lastSubmittedDescription, equals(validText));
    });

    testWidgets('Input editing correctly modifies text and submits latest value', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      final textFormField = find.byType(TextFormField);

      // 1. Enter initial text
      await tester.enterText(textFormField, 'Initial Description');
      await tester.pump();
      expect(find.text('Initial Description'), findsOneWidget);

      // 2. Modify/replace text
      await tester.enterText(textFormField, 'Updated Description');
      await tester.pump();
      expect(find.text('Initial Description'), findsNothing);
      expect(find.text('Updated Description'), findsOneWidget);

      // 3. Submit
      final submitButton = find.text('Compute Keyword Match');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 4. Verify only the latest value was submitted
      expect(fakeController.submitCallsCount, equals(1));
      expect(fakeController.lastSubmittedDescription, equals('Updated Description'));
    });
  });
}
