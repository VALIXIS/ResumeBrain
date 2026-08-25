import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/resume_models.dart';

abstract class ResumeRepository {
  Future<void> init();
  Future<List<Resume>> getAllResumes();
  Future<Resume?> getResumeById(String id);
  Future<void> saveResume(Resume resume);
  Future<void> deleteResume(String id);
}

class HiveResumeRepository implements ResumeRepository {
  Box? _box;

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
}
