import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/features/job_matching/presentation/job_description_input_screen.dart';
import 'package:resume_brain/features/job_matching/controllers/job_matching_controller.dart';
import 'package:resume_brain/features/job_matching/models/job_description.dart';

class FakeJobMatchingController extends JobMatchingController {
  int submitCallsCount = 0;
  String? lastSubmittedDescription;

  @override
  Future<void> submitJobDescription(String description, {String? title, String? url}) async {
    submitCallsCount++;
    lastSubmittedDescription = description;
    state = state.copyWith(isLoading: true);
    
    // We yield control back to the test runner so it can observe the loading state
    await Future.delayed(Duration.zero);
    
    final job = JobDescription(
      descriptionText: description,
      title: title ?? 'Fake Job Title',
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
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            jobMatchingControllerProvider.overrideWith((ref) => fakeController),
          ],
        ),
      );

      // Verify the AppBar Title
      expect(find.text('Job Description Match'), findsOneWidget);

      // Verify main headings/titles
      expect(find.text('Enter Job Details'), findsOneWidget);
      expect(find.text('Paste the target job description to match and tailor your resume.'), findsOneWidget);

      // Verify input text field label and hint
      expect(find.text('Job Description'), findsOneWidget);
      expect(find.text('Paste the job description here...'), findsOneWidget);

      // Verify the action button
      expect(find.text('Submit Description'), findsOneWidget);

      // Ensure no error state is displayed initially
      expect(find.text('Job description cannot be empty'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('Empty input displays local validation error and does not call controller', (WidgetTester tester) async {
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
      final submitButton = find.text('Submit Description');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify local validation error is displayed
      expect(find.text('Job description cannot be empty'), findsOneWidget);

      // Verify that the controller method was NOT called
      expect(fakeController.submitCallsCount, equals(0));
    });

    testWidgets('Whitespace-only input displays local validation error and does not call controller', (WidgetTester tester) async {
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
      final submitButton = find.text('Submit Description');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify local validation error is displayed
      expect(find.text('Job description cannot be empty'), findsOneWidget);

      // Verify that the controller method was NOT called
      expect(fakeController.submitCallsCount, equals(0));
    });

    testWidgets('Valid job description submission calls controller and updates state', (WidgetTester tester) async {
      bool successCallbackCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          onSuccess: () {
            successCallbackCalled = true;
          },
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
      final submitButton = find.text('Submit Description');
      await tester.tap(submitButton);
      
      // Pump to trigger build after submit triggers loading
      await tester.pump();
      
      // Verify button shows loading status or controller has been triggered
      expect(fakeController.submitCallsCount, equals(1));
      expect(fakeController.lastSubmittedDescription, equals(validText));

      // Settle the delayed future inside fakeController
      await tester.pumpAndSettle();

      // Verify success status/text is rendered on screen
      expect(find.text('Successfully matched with: Fake Job Title'), findsOneWidget);
      expect(successCallbackCalled, isTrue);
    });

    testWidgets('Input editing correctly modifies text and submits latest value', (WidgetTester tester) async {
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
      final submitButton = find.text('Submit Description');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 4. Verify only the latest value was submitted
      expect(fakeController.submitCallsCount, equals(1));
      expect(fakeController.lastSubmittedDescription, equals('Updated Description'));
    });
  });
}
