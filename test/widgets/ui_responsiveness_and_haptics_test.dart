import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/widgets/custom_button.dart';
import 'package:resume_brain/core/widgets/tap_scale_widget.dart';

void main() {
  group('AppButton & TapScaleWidget Responsiveness & Interaction Tests', () {
    testWidgets('1. AppButton renders text, icon, and triggers onPressed callback when enabled', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Submit Resume',
              icon: Icons.send_rounded,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Resume'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('2. AppButton in loading state displays CircularProgressIndicator and ignores taps', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Saving Data',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('3. AppButton disabled state (onPressed: null) ignores gestures cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.label, contains('Disabled Button'));
    });

    testWidgets('4. AppButton variants (Primary, Secondary, Outline, Text, AI) render without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(text: 'Primary', variant: AppButtonVariant.primary, onPressed: () {}),
                AppButton(text: 'Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
                AppButton(text: 'Outline', variant: AppButtonVariant.outline, onPressed: () {}),
                AppButton(text: 'Text', variant: AppButtonVariant.text, onPressed: () {}),
                AppButton(text: 'AI', variant: AppButtonVariant.ai, onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('5. TapScaleWidget performs micro-scaling gesture handling when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TapScaleWidget(
                onTap: () => tapped = true,
                child: const Text('Interactive Card'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Interactive Card'), findsOneWidget);

      final scaleFinder = find.descendant(
        of: find.byType(TapScaleWidget),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleFinder, findsOneWidget);

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('6. TapScaleWidget with null onTap renders child directly without gesture Listener', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TapScaleWidget(
              onTap: null,
              child: Text('Static Non-Interactive Card'),
            ),
          ),
        ),
      );

      expect(find.text('Static Non-Interactive Card'), findsOneWidget);

      final listenerFinder = find.descendant(
        of: find.byType(TapScaleWidget),
        matching: find.byType(Listener),
      );
      expect(listenerFinder, findsNothing);
    });

    testWidgets('7. TapScaleWidget triggers tap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapScaleWidget(
              onTap: () => tapped = true,
              child: const Text('Accessible Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Accessible Button'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
