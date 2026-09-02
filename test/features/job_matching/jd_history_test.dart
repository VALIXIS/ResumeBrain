import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/job_matching/controllers/job_matching_controller.dart';
import 'package:resume_brain/features/job_matching/models/job_description.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('JD History - State & Controller Tests', () {
    test('1. Initial history state is empty and currentJob is null', () {
      final state = container.read(jobMatchingControllerProvider);
      expect(state.jobDescriptions, isEmpty);
      expect(state.currentJob, isNull);
      expect(state.extractionResult, isNull);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });

    test('2. Submitting Job Descriptions populates history list sequentially', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      await controller.submitJobDescription(
        'Looking for a Flutter Developer with Dart expertise.',
        title: 'Flutter Developer Role',
      );

      await controller.submitJobDescription(
        'Backend Engineer needed with Python and PostgreSQL knowledge.',
        title: 'Backend Engineer Role',
      );

      final state = container.read(jobMatchingControllerProvider);
      expect(state.jobDescriptions.length, equals(2));
      expect(state.jobDescriptions[0].title, equals('Flutter Developer Role'));
      expect(state.jobDescriptions[1].title, equals('Backend Engineer Role'));
      expect(state.currentJob!.title, equals('Backend Engineer Role'));
    });

    test('3. Submitting duplicate JDs records multiple history entries cleanly', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      await controller.submitJobDescription('Duplicate Job Text', title: 'Job A');
      await controller.submitJobDescription('Duplicate Job Text', title: 'Job A');

      final state = container.read(jobMatchingControllerProvider);
      expect(state.jobDescriptions.length, equals(2));
      expect(state.jobDescriptions[0].descriptionText, equals('Duplicate Job Text'));
      expect(state.jobDescriptions[1].descriptionText, equals('Duplicate Job Text'));
    });

    test('4. Selecting a historical JD updates currentJob state without corrupting history', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      await controller.submitJobDescription('First Job: Flutter & Riverpod', title: 'Job 1');
      await controller.submitJobDescription('Second Job: Java & Spring Boot', title: 'Job 2');
      await controller.submitJobDescription('Third Job: Rust & WebAssembly', title: 'Job 3');

      final stateBefore = container.read(jobMatchingControllerProvider);
      final firstJob = stateBefore.jobDescriptions[0];

      // Re-submit or select first historical job
      await controller.submitJobDescriptionWithResume(
        firstJob.descriptionText,
        title: firstJob.title,
      );

      final stateAfter = container.read(jobMatchingControllerProvider);
      expect(stateAfter.currentJob!.title, equals('Job 1'));
      expect(stateAfter.currentJob!.descriptionText, equals('First Job: Flutter & Riverpod'));
      expect(stateAfter.jobDescriptions.length, equals(4)); // Preserved full audit log
    });

    test('5. Clearing current job removes active selection while preserving history list', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      await controller.submitJobDescription('Job description for testing clear action', title: 'Clear Test');
      expect(container.read(jobMatchingControllerProvider).currentJob, isNotNull);

      controller.clearCurrentJob();

      final state = container.read(jobMatchingControllerProvider);
      expect(state.currentJob, isNull);
      expect(state.extractionResult, isNull);
      expect(state.jobDescriptions.length, equals(1));
    });

    test('6. Edge cases: Handles long text, special characters, unicode, and empty fields', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      const specialTitle = 'Lead C++ & C# Engineer 🚀 <script>alert(1)</script>';
      final longDescription = 'Skill: Flutter. ' * 500;

      await controller.submitJobDescription(
        longDescription,
        title: specialTitle,
        url: 'https://valixis.com/jobs/123?ref=test&category=eng#top',
      );

      final state = container.read(jobMatchingControllerProvider);
      expect(state.jobDescriptions.length, equals(1));
      final job = state.jobDescriptions.first;
      expect(job.title, equals(specialTitle));
      expect(job.descriptionText.length, equals(longDescription.length));
      expect(job.url, equals('https://valixis.com/jobs/123?ref=test&category=eng#top'));
    });

    test('7. Provider state isolation: independent containers maintain isolated history', () async {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();

      await containerA.read(jobMatchingControllerProvider.notifier).submitJobDescription('Job A text');
      await containerB.read(jobMatchingControllerProvider.notifier).submitJobDescription('Job B text');

      expect(containerA.read(jobMatchingControllerProvider).jobDescriptions.length, equals(1));
      expect(containerA.read(jobMatchingControllerProvider).jobDescriptions.first.descriptionText, equals('Job A text'));

      expect(containerB.read(jobMatchingControllerProvider).jobDescriptions.length, equals(1));
      expect(containerB.read(jobMatchingControllerProvider).jobDescriptions.first.descriptionText, equals('Job B text'));

      containerA.dispose();
      containerB.dispose();
    });
  });

  group('JD History - Widget & Drawer UI Tests', () {
    testWidgets('8. Renders empty history state UI cleanly when no JDs are submitted', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(jobMatchingControllerProvider);
                  if (state.jobDescriptions.isEmpty) {
                    return const Center(
                      child: Text('No Job Description History'),
                    );
                  }
                  return ListView(
                    children: state.jobDescriptions
                        .map((j) => ListTile(title: Text(j.title)))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('No Job Description History'), findsOneWidget);
    });

    testWidgets('9. Renders historical JDs in history list and selects entry on tap', (tester) async {
      late ProviderContainer testContainer;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                testContainer = ProviderScope.containerOf(context);
                final state = ref.watch(jobMatchingControllerProvider);

                return Scaffold(
                  appBar: AppBar(title: Text(state.currentJob?.title ?? 'No Selected Job')),
                  body: ListView.builder(
                    itemCount: state.jobDescriptions.length,
                    itemBuilder: (context, index) {
                      final jd = state.jobDescriptions[index];
                      return ListTile(
                        key: Key('history-item-$index'),
                        title: Text(jd.title),
                        subtitle: Text(
                          jd.descriptionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          ref.read(jobMatchingControllerProvider.notifier).submitJobDescriptionWithResume(
                                jd.descriptionText,
                                title: jd.title,
                              );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Populate history via controller
      await testContainer.read(jobMatchingControllerProvider.notifier).submitJobDescription(
            'Requirements: Flutter, Dart, Riverpod.',
            title: 'Mobile Engineer',
          );
      await testContainer.read(jobMatchingControllerProvider.notifier).submitJobDescription(
            'Requirements: Python, Django, PostgreSQL.',
            title: 'Backend Engineer',
          );

      await tester.pump(const Duration(milliseconds: 50));

      // Verify both items appear in the list
      expect(find.text('Mobile Engineer'), findsOneWidget);
      expect(find.text('Backend Engineer'), findsOneWidget);

      // Tap on the first item ('Mobile Engineer')
      await tester.tap(find.byKey(const Key('history-item-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify selected job updated in currentJob state and displayed in AppBar
      expect(testContainer.read(jobMatchingControllerProvider).currentJob!.title, equals('Mobile Engineer'));
      expect(find.text('Mobile Engineer'), findsOneWidget);
    });
  });
}
