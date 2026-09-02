import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/main.dart';

void main() {
  testWidgets('Resume Brain App boots up cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ResumeBrainApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ResumeBrainApp), findsOneWidget);
  });
}
