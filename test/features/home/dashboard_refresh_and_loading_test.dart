import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/core/storage/storage_bootstrap.dart';
import 'package:resume_brain/core/storage/storage_provider.dart';
import 'package:resume_brain/core/widgets/shimmer_placeholders.dart';
import 'package:resume_brain/core/widgets/state_widgets.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/home/presentation/home_dashboard_screen.dart';

class MockResumeRepository implements ResumeRepository {
  final List<Resume> _resumes;
  bool shouldFail;

  MockResumeRepository({List<Resume>? initialResumes, this.shouldFail = false})
      : _resumes = initialResumes ?? [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async {
    if (shouldFail) {
      throw Exception('Database connection failed');
    }
    return List.unmodifiable(_resumes);
  }

  @override
  Future<Resume?> getResumeById(String id) async {
    return _resumes.firstWhere((r) => r.id == id, orElse: () => _resumes.first);
  }

  @override
  Future<void> saveResume(Resume resume) async {
    final index = _resumes.indexWhere((r) => r.id == resume.id);
    if (index != -1) {
      _resumes[index] = resume;
    } else {
      _resumes.add(resume);
    }
  }

  @override
  Future<void> deleteResume(String id) async {
    _resumes.removeWhere((r) => r.id == id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async => CloudSyncResult.unsupported();

  @override
  Future<CloudSyncResult> syncAllToCloud() async => CloudSyncResult.unsupported();
}

class FakeStorageBootstrapNotifier extends StateNotifier<StorageStatus> implements StorageBootstrapNotifier {
  FakeStorageBootstrapNotifier(super.initialStatus);

  @override
  Future<void> retry() async {
    state = StorageStatus.ready;
  }
}

void main() {
  late MockResumeRepository mockRepo;

  Resume createTestResume({String id = 'res-1', String title = 'Full Stack Resume'}) {
    return Resume(
      id: id,
      title: title,
      personalInfo: PersonalInformation(fullName: 'Alex Vance', jobTitle: 'Senior Engineer'),
      summary: ProfessionalSummary(summaryText: 'Experienced developer.'),
    );
  }

  setUp(() {
    mockRepo = MockResumeRepository();
  });

  group('HomeDashboardScreen Refresh & Loading Tests', () {
    testWidgets('1. Displays empty state widget when no resumes exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(mockRepo),
            storageBootstrapProvider.overrideWith((ref) => FakeStorageBootstrapNotifier(StorageStatus.ready)),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Resumes Yet'), findsOneWidget);
      expect(find.text('Create Resume Now'), findsOneWidget);
    });

    testWidgets('2. Displays resume list cards when data is loaded successfully', (tester) async {
      mockRepo = MockResumeRepository(initialResumes: [
        createTestResume(id: 'r1', title: 'Tech Resume 2026'),
        createTestResume(id: 'r2', title: 'Executive CV'),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(mockRepo),
            storageBootstrapProvider.overrideWith((ref) => FakeStorageBootstrapNotifier(StorageStatus.ready)),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tech Resume 2026'), findsOneWidget);
      expect(find.text('Executive CV'), findsOneWidget);
      expect(find.text('2 saved'), findsOneWidget);
    });

    testWidgets('3. Triggers loadResumes when ErrorStateWidget retry button is pressed', (tester) async {
      mockRepo = MockResumeRepository(shouldFail: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(mockRepo),
            storageBootstrapProvider.overrideWith((ref) => FakeStorageBootstrapNotifier(StorageStatus.ready)),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);

      // Fix failure and tap retry
      mockRepo.shouldFail = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
    });

    testWidgets('4. Responsive layout adapts between Mobile and Desktop breakpoints', (tester) async {
      mockRepo = MockResumeRepository(initialResumes: [createTestResume()]);

      // Set Desktop size (> 800px)
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(mockRepo),
            storageBootstrapProvider.overrideWith((ref) => FakeStorageBootstrapNotifier(StorageStatus.ready)),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('VALIXIS CAREER ENGINE'), findsOneWidget);
      expect(find.text('Resume Intelligence Suite'), findsOneWidget);

      // Reset view size
      addTearDown(tester.view.resetPhysicalSize);
    });
  });

  group('Shimmer & Skeleton Loading Placeholders Unit Tests', () {
    testWidgets('5. StatCardShimmer renders with correct accessibility semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardShimmer(),
          ),
        ),
      );

      expect(find.byType(StatCardShimmer), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(StatCardShimmer));
      expect(semantics.label, equals('Loading statistics card'));
    });

    testWidgets('6. ListRowShimmer renders placeholder shapes cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListRowShimmer(),
          ),
        ),
      );

      expect(find.byType(ListRowShimmer), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(ListRowShimmer));
      expect(semantics.label, equals('Loading list item'));
    });

    testWidgets('7. DashboardCardShimmer renders feature card skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCardShimmer(),
          ),
        ),
      );

      expect(find.byType(DashboardCardShimmer), findsOneWidget);
    });

    testWidgets('8. TextBlockShimmer renders requested number of line placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextBlockShimmer(lines: 4),
          ),
        ),
      );

      expect(find.byType(TextBlockShimmer), findsOneWidget);
    });
  });
}
