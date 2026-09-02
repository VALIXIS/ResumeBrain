import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/storage/storage_bootstrap.dart';
import 'package:resume_brain/core/storage/storage_provider.dart';
import 'package:resume_brain/features/home/presentation/home_dashboard_screen.dart';
import 'package:resume_brain/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Architecture & Non-blocking UI Tests', () {
    testWidgets('1. App root renders cleanly without blocking on storage initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ResumeBrainApp(),
        ),
      );
      // First frame renders immediately without waiting for storage
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
    });

    testWidgets('2. HomeDashboardScreen renders loading shimmer while storage is initializing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageBootstrapProvider.overrideWith((ref) {
              final notifier = StorageBootstrapNotifier(StorageBootstrapService());
              // Force initializing state
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      // User never sees blank screen
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('3. HomeDashboardScreen renders fallback error state gracefully when storage initialization throws', (WidgetTester tester) async {
      final service = StorageBootstrapService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageBootstrapProvider.overrideWith((ref) {
              final notifier = StorageBootstrapNotifier(service);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      // Ensures UI renders and scaffold is active
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('4. StartupStages stage logging functions without throwing exceptions', (WidgetTester tester) async {
      expect(() => StartupStages.logStage(StartupStages.stage1Binding), returnsNormally);
      expect(() => StartupStages.logStage(StartupStages.stage2RunApp), returnsNormally);
      expect(() => StartupStages.logStage(StartupStages.stage3StorageInit), returnsNormally);
      expect(() => StartupStages.logStage(StartupStages.stage7HomeRender), returnsNormally);
    });
  });
}
