import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/resume_models.dart';
import '../data/repositories/resume_repository.dart';
import '../features/ai/services/ai_service.dart';
import '../features/pdf/services/pdf_service.dart';
import '../features/ai/services/hybrid_ai_provider.dart';

// Services & Repositories
final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return HiveResumeRepository();
});

final aiServiceProvider = Provider<AIService>((ref) {
  const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  const groqKey = String.fromEnvironment('GROQ_API_KEY');

  return ResumeBrainAIService(
    provider: HybridAIProvider(
      geminiApiKey: geminiKey,
      groqApiKey: groqKey,
    ),
  );
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

// Active List of Saved Resumes
class ResumesListNotifier extends StateNotifier<AsyncValue<List<Resume>>> {
  final ResumeRepository _repository;

  ResumesListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadResumes();
  }

  Future<void> loadResumes() async {
    try {
      state = const AsyncValue.loading();
      final resumes = await _repository.getAllResumes();
      state = AsyncValue.data(resumes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveResume(Resume resume) async {
    await _repository.saveResume(resume);
    await loadResumes();
  }

  Future<void> deleteResume(String id) async {
    await _repository.deleteResume(id);
    await loadResumes();
  }
}

final resumesListProvider = StateNotifierProvider<ResumesListNotifier, AsyncValue<List<Resume>>>((ref) {
  final repo = ref.watch(resumeRepositoryProvider);
  return ResumesListNotifier(repo);
});

// Currently Editing Resume Notifier with Debounced Auto-Save & Revision Race Protection
class CurrentResumeNotifier extends StateNotifier<Resume?> {
  final Ref _ref;
  Timer? _debounceTimer;
  Duration debounceDuration;

  int _revisionToken = 0;
  int _lastSavedRevision = 0;
  bool _isSaving = false;

  CurrentResumeNotifier(this._ref, {this.debounceDuration = const Duration(milliseconds: 500)})
      : super(null);

  /// Accessor for current revision token (useful for unit testing race conditions).
  int get revisionToken => _revisionToken;

  /// Accessor for last saved revision token.
  int get lastSavedRevision => _lastSavedRevision;

  /// Returns true if an auto-save timer is currently pending.
  bool get isSavePending => _debounceTimer?.isActive ?? false;

  /// Sets active resume, resetting pending timers and updating revision token baseline.
  void setResume(Resume resume) {
    _debounceTimer?.cancel();
    state = resume;
    _revisionToken++;
    _lastSavedRevision = _revisionToken;
  }

  /// Updates resume state and schedules a debounced auto-save write.
  /// If [immediate] is true, persists state immediately without debouncing.
  void updateResume(
    Resume Function(Resume current) updateFn, {
    bool immediate = false,
  }) {
    if (state == null) return;

    final updated = updateFn(state!);
    state = updated;
    _revisionToken++;

    _debounceTimer?.cancel();
    if (immediate) {
      _triggerSave();
    } else {
      _debounceTimer = Timer(debounceDuration, () {
        _triggerSave();
      });
    }
  }

  /// Flushes any pending auto-save immediately.
  Future<void> flushPendingSave() async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
      await _triggerSave();
    }
  }

  Future<void> _triggerSave() async {
    if (state == null || _isSaving || _revisionToken <= _lastSavedRevision) {
      return;
    }

    _isSaving = true;
    final tokenToSave = _revisionToken;
    final resumeToSave = state!;

    try {
      await _ref.read(resumesListProvider.notifier).saveResume(resumeToSave);
      if (tokenToSave > _lastSavedRevision) {
        _lastSavedRevision = tokenToSave;
      }
    } catch (e) {
      debugPrint('Error auto-saving resume: $e');
    } finally {
      _isSaving = false;
      // If new edits arrived while saving was in progress, save latest revision
      if (_revisionToken > _lastSavedRevision) {
        await _triggerSave();
      }
    }
  }

  void updatePersonalInfo(PersonalInformation info) {
    updateResume((r) => r.copyWith(personalInfo: info));
  }

  void updateSummary(ProfessionalSummary summary) {
    updateResume((r) => r.copyWith(summary: summary));
  }

  void setTemplate(String templateId) {
    updateResume((r) => r.copyWith(templateId: templateId), immediate: true);
  }

  void addExperience(Experience exp) {
    updateResume((r) {
      final list = List<Experience>.from(r.experiences);
      final index = list.indexWhere((item) => item.id == exp.id);
      if (index != -1) {
        list[index] = exp;
      } else {
        list.add(exp);
      }
      return r.copyWith(experiences: list);
    });
  }

  void deleteExperience(String id) {
    updateResume((r) => r.copyWith(
      experiences: r.experiences.where((e) => e.id != id).toList(),
    ));
  }

  void addEducation(Education edu) {
    updateResume((r) {
      final list = List<Education>.from(r.educationList);
      final index = list.indexWhere((item) => item.id == edu.id);
      if (index != -1) {
        list[index] = edu;
      } else {
        list.add(edu);
      }
      return r.copyWith(educationList: list);
    });
  }

  void deleteEducation(String id) {
    updateResume((r) => r.copyWith(
      educationList: r.educationList.where((e) => e.id != id).toList(),
    ));
  }

  void addSkill(Skill skill) {
    updateResume((r) {
      final list = List<Skill>.from(r.skills);
      final index = list.indexWhere((item) => item.id == skill.id);
      if (index != -1) {
        list[index] = skill;
      } else {
        list.add(skill);
      }
      return r.copyWith(skills: list);
    });
  }

  void deleteSkill(String id) {
    updateResume((r) => r.copyWith(
      skills: r.skills.where((s) => s.id != id).toList(),
    ));
  }

  void addProject(Project project) {
    updateResume((r) {
      final list = List<Project>.from(r.projects);
      final index = list.indexWhere((item) => item.id == project.id);
      if (index != -1) {
        list[index] = project;
      } else {
        list.add(project);
      }
      return r.copyWith(projects: list);
    });
  }

  void deleteProject(String id) {
    updateResume((r) => r.copyWith(
      projects: r.projects.where((p) => p.id != id).toList(),
    ));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final currentResumeProvider = StateNotifierProvider<CurrentResumeNotifier, Resume?>((ref) {
  return CurrentResumeNotifier(ref);
});
