import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/resume/services/bullet_enhancement_service.dart';
import 'package:resume_brain/features/resume/widgets/bullet_point_enhancer.dart';

void main() {
  group('BulletPointEnhancer Visual Diff Comparison Tests (RSM-REF-04)', () {
    testWidgets('Renders side-by-side visual diff comparison card with Original and AI-Enhanced',
        (WidgetTester tester) async {
      String? appliedResult;

      // Set test window size to tablet/desktop landscape so elements fit cleanly
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bulletEnhancementServiceProvider.overrideWithValue(
              BulletEnhancementService(aiService: null),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      BulletPointEnhancerDialog.show(
                        context: context,
                        initialBullet: 'Managed team and built software applications.',
                        roleContext: 'Software Engineer',
                        onApply: (val) {
                          appliedResult = val;
                        },
                      );
                    },
                    child: const Text('Open Enhancer'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Enhancer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify diff comparison UI elements exist
      expect(find.text('Original'), findsAtLeastNWidgets(1));
      expect(find.text('AI-Enhanced'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Managed team and built software applications.'), findsAtLeastNWidgets(1));

      // Verify action buttons exist: Accept Diff, Edit in Box
      expect(find.text('Accept Diff'), findsAtLeastNWidgets(1));
      expect(find.text('Edit in Box'), findsAtLeastNWidgets(1));

      // Scroll to the first Accept Diff button to make it visible
      await tester.ensureVisible(find.text('Accept Diff').first);
      await tester.pumpAndSettle();

      // Tap Accept Diff on the first suggestion
      await tester.tap(find.text('Accept Diff').first);
      await tester.pumpAndSettle();

      // Tap Replace Bullet in footer to finalize
      expect(find.text('Replace Bullet'), findsOneWidget);
      await tester.tap(find.text('Replace Bullet'));
      await tester.pumpAndSettle();

      // Verify callback was triggered with enhanced text
      expect(appliedResult, isNotNull);
      expect(appliedResult, isNot(equals('Managed team and built software applications.')));
    });
  });
}
