import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/storage_bootstrap.dart';
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
  final CloudSyncAdapter _cloudSyncAdapter;

  HiveResumeRepository({CloudSyncAdapter? cloudSyncAdapter})
      : _cloudSyncAdapter = cloudSyncAdapter ?? const StubCloudSyncAdapter();

  @override
  Future<void> init() async {
    // Storage initialization is handled centrally by StorageBootstrapService.
    await StorageBootstrapService().initializeStorage();
  }

  Box? get _safeBox => StorageBootstrapService().resumesBox;

  @override
  Future<List<Resume>> getAllResumes() async {
    final box = _safeBox;
    if (box == null) {
      debugPrint('HiveResumeRepository: Storage box unavailable. Returning empty list.');
      return [];
    }

    final list = <Resume>[];
    for (var key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null && data is Map) {
          list.add(Resume.fromMap(Map<String, dynamic>.from(data)));
        }
      } catch (e) {
        debugPrint('Skipping corrupted resume record for key $key: $e');
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Resume?> getResumeById(String id) async {
    final box = _safeBox;
    if (box == null) return null;
    try {
      final data = box.get(id);
      if (data == null || data is! Map) return null;
      return Resume.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('Error retrieving resume $id: $e');
      return null;
    }
  }

  @override
  Future<void> saveResume(Resume resume) async {
    final box = _safeBox;
    if (box == null) {
      debugPrint('Cannot save resume ${resume.id}: Storage box unavailable.');
      return;
    }
    await box.put(resume.id, resume.toMap());
  }

  @override
  Future<void> deleteResume(String id) async {
    final box = _safeBox;
    if (box == null) return;
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
