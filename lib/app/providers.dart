import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/resume_models.dart';
import '../data/repositories/resume_repository.dart';
import '../features/ai/services/ai_service.dart';
import '../features/pdf/services/pdf_service.dart';

// Services & Repositories
final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return HiveResumeRepository();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return ResumeBrainAIService(provider: MockAIProvider());
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

// Currently Editing Resume Notifier
class CurrentResumeNotifier extends StateNotifier<Resume?> {
  final Ref _ref;

  CurrentResumeNotifier(this._ref) : super(null);

  void setResume(Resume resume) {
    state = resume;
  }

  void updateResume(Resume Function(Resume current) updateFn) {
    if (state != null) {
      final updated = updateFn(state!);
      state = updated;
      _ref.read(resumesListProvider.notifier).saveResume(updated);
    }
  }

  void updatePersonalInfo(PersonalInformation info) {
    updateResume((r) => r.copyWith(personalInfo: info));
  }

  void updateSummary(ProfessionalSummary summary) {
    updateResume((r) => r.copyWith(summary: summary));
  }

  void setTemplate(String templateId) {
    updateResume((r) => r.copyWith(templateId: templateId));
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
}

final currentResumeProvider = StateNotifierProvider<CurrentResumeNotifier, Resume?>((ref) {
  return CurrentResumeNotifier(ref);
});
