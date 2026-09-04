import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';
import 'package:resume_brain/features/job_matching/presentation/widgets/missing_skill_badge_widget.dart';

class MockResumeRepository implements ResumeRepository {
  final List<Resume> _resumes = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async => List.unmodifiable(_resumes);

  @override
  Future<Resume?> getResumeById(String id) async {
    final idx = _resumes.indexWhere((r) => r.id == id);
    return idx != -1 ? _resumes[idx] : null;
  }

  @override
  Future<void> saveResume(Resume resume) async {
    final idx = _resumes.indexWhere((r) => r.id == resume.id);
    if (idx != -1) {
      _resumes[idx] = resume;
    } else {
      _resumes.add(resume);
    }
  }

  @override
  Future<void> deleteResume(String id) async {
    _resumes.removeWhere((r) => r.id == id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async {
    return CloudSyncResult.unsupported();
  }

  @override
  Future<CloudSyncResult> syncAllToCloud() async {
    return CloudSyncResult.unsupported();
  }
}

void main() {
  late MockResumeRepository repo;

  setUp(() {
    repo = MockResumeRepository();
  });

  testWidgets('MissingSkillBadgeWidget renders badge and adds skill on click', (WidgetTester tester) async {
    final initialResume = Resume(
      id: 'test-resume-1',
      skills: [Skill(name: 'Python')],
    );
    await repo.saveResume(initialResume);

    bool callbackFired = false;

    final container = ProviderContainer(
      overrides: [
        resumeRepositoryProvider.overrideWithValue(repo),
      ],
    );
    container.read(currentResumeProvider.notifier).setResume(initialResume);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MissingSkillBadgeWidget(
              skill: 'Docker',
              onInserted: () {
                callbackFired = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify badge initial state
    expect(find.text('Docker'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Click 'Add'
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify callback fired
    expect(callbackFired, isTrue);

    // Verify resume state updated with Docker skill
    final updatedResume = container.read(currentResumeProvider);
    expect(updatedResume, isNotNull);
    expect(updatedResume!.skills.any((s) => s.name == 'Docker'), isTrue);

    container.dispose();
  });
}
