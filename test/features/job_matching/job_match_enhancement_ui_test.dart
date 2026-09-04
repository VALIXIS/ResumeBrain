import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/job_matching/models/job_description.dart';
import 'package:resume_brain/features/job_matching/presentation/job_match_results_screen.dart';

void main() {
  group('JobMatchResultsScreen Enhancement UI Tests', () {
    testWidgets('Renders TF-IDF scores, missing skills, and side-by-side comparison', (WidgetTester tester) async {
      final job = JobDescription(
        title: 'Senior Flutter Engineer',
        descriptionText: 'Looking for a Senior Flutter Developer with Dart, Docker, AWS, and PostgreSQL experience. Salary: ₹15-20 LPA.',
      );

      final resume = Resume(
        skills: [Skill(name: 'Flutter'), Skill(name: 'Dart')],
        experiences: [
          Experience(
            company: 'ABC Tech',
            position: 'Flutter Developer',
            startDate: '2020',
            endDate: '2026',
            isCurrent: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: JobMatchResultsScreen(
              jobDescription: job,
              resume: resume,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Job Match Results'), findsOneWidget);
      expect(find.text('Senior Flutter Engineer'), findsOneWidget);

      // Verify TF-IDF section
      expect(find.text('Top TF-IDF Keyword Scores'), findsOneWidget);

      // Verify comparison section header
      expect(find.text('Resume vs Job Description Comparison'), findsOneWidget);

      // Verify Matched & Missing skills
      expect(find.text('Flutter'), findsWidgets);
      expect(find.text('Docker'), findsWidgets);
    });

    testWidgets('Adapts responsively to mobile small screen constraints', (WidgetTester tester) async {
      final job = JobDescription(
        title: 'Backend Engineer',
        descriptionText: r'Python Developer with Django and PostgreSQL experience. Salary: $100k-$130k.',
      );

      final resume = Resume(
        skills: [Skill(name: 'Python')],
      );

      // Set small physical screen bounds (<600px width)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: JobMatchResultsScreen(
              jobDescription: job,
              resume: resume,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify mobile segmented tab headers render cleanly
      expect(find.text('Matched & Gaps'), findsOneWidget);
      expect(find.text('Salary & Seniority'), findsOneWidget);

      // Reset view size
      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
