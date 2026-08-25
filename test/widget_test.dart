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
    expect(find.text('Resume Brain'), findsOneWidget);
  });
}
