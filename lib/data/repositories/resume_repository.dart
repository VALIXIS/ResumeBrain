import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/resume_models.dart';
import 'cloud_sync_adapter.dart';

/// Abstract persistence boundary for resume data storage, retrieval, and cloud synchronization.
abstract class ResumeRepository {
  /// Initializes persistence storage mechanisms.
  Future<void> init();

  /// Retrieves all saved resumes, ordered by most recently updated first.
  Future<List<Resume>> getAllResumes();

  /// Retrieves a specific resume by its unique identifier.
  Future<Resume?> getResumeById(String id);

  /// Persists a resume locally.
  Future<void> saveResume(Resume resume);

  /// Removes a resume by its unique identifier from local storage.
  Future<void> deleteResume(String id);

  /// Synchronizes a specific resume with remote cloud storage via [CloudSyncAdapter].
  Future<CloudSyncResult> syncResumeToCloud(Resume resume);

  /// Performs full cloud sync of all local resumes via [CloudSyncAdapter].
  Future<CloudSyncResult> syncAllToCloud();
}

/// Local Hive implementation of [ResumeRepository].
class HiveResumeRepository implements ResumeRepository {
  Box? _box;
  final CloudSyncAdapter _cloudSyncAdapter;

  HiveResumeRepository({CloudSyncAdapter? cloudSyncAdapter})
      : _cloudSyncAdapter = cloudSyncAdapter ?? const StubCloudSyncAdapter();

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(AppConstants.hiveResumeBox);
  }

  Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('ResumeRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<List<Resume>> getAllResumes() async {
    final list = <Resume>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        list.add(Resume.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Resume?> getResumeById(String id) async {
    final data = box.get(id);
    if (data == null) return null;
    return Resume.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> saveResume(Resume resume) async {
    await box.put(resume.id, resume.toMap());
  }

  @override
  Future<void> deleteResume(String id) async {
    await box.delete(id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async {
    return _cloudSyncAdapter.uploadResume(resume);
  }

  @override
  Future<CloudSyncResult> syncAllToCloud() async {
    final resumes = await getAllResumes();
    return _cloudSyncAdapter.syncAll(resumes);
  }
}
