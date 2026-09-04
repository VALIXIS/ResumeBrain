import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_brain/core/theme/app_typography.dart';
import 'package:resume_brain/core/widgets/app_navigation_drawer.dart';
import 'package:resume_brain/core/widgets/custom_button.dart';
import 'package:resume_brain/core/widgets/custom_card.dart';
import 'package:resume_brain/core/widgets/smooth_page_route.dart';

void main() {
  setUp(() {
    // Disable HTTP runtime font fetching to verify offline typography safety
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Offline Google Fonts Fallback & Typography Safety Tests', () {
    testWidgets('1. AppTypography styles render without network calls when runtime fetching is disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Display Large', style: AppTypography.displayLarge),
                Text('Display Medium', style: AppTypography.displayMedium),
                Text('Title Large', style: AppTypography.titleLarge),
                Text('Body Medium', style: AppTypography.bodyMedium),
                Text('Label Small', style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Display Large'), findsOneWidget);
      expect(find.text('Display Medium'), findsOneWidget);
      expect(find.text('Title Large'), findsOneWidget);
      expect(find.text('Body Medium'), findsOneWidget);
      expect(find.text('Label Small'), findsOneWidget);
    });

    testWidgets('2. UI components render correctly offline with fallback typography', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Column(
                children: [
                  Text('Card Header', style: AppTypography.titleMedium),
                  Text('Card description text rendered offline.', style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Offline Action',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Header'), findsOneWidget);
      expect(find.text('Offline Action'), findsOneWidget);
    });
  });

  group('Page Transitions & Smooth Navigation Tests', () {
    testWidgets('3. SmoothPageRoute completes transition and mounts target screen cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: const Scaffold(
                          body: Text('Target Transition Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Target Transition Screen'), findsOneWidget);
    });

    testWidgets('4. AppNavigationDrawer renders destinations and triggers selection callback', (tester) async {
      int selected = 0;
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppNavigationDrawer(
                selectedIndex: selected,
                onDestinationSelected: (index) => selected = index,
                isPermanent: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Resumes'), findsOneWidget);
      expect(find.text('ATS Analysis'), findsOneWidget);
      expect(find.text('Job Match'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);

      await tester.tap(find.text('ATS Analysis'));
      await tester.pump();

      expect(selected, equals(1));
    });
  });
}
