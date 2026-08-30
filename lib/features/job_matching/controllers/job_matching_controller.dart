import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/resume_models.dart';
import '../models/job_description.dart';
import '../models/keyword_extraction_result.dart';
import '../services/keyword_extractor_service.dart';

class JobMatchingState {
  final List<JobDescription> jobDescriptions;
  final JobDescription? currentJob;
  final KeywordExtractionResult? extractionResult;
  final bool isLoading;
  final String? error;

  const JobMatchingState({
    this.jobDescriptions = const [],
    this.currentJob,
    this.extractionResult,
    this.isLoading = false,
    this.error,
  });

  JobMatchingState copyWith({
    List<JobDescription>? jobDescriptions,
    JobDescription? currentJob,
    KeywordExtractionResult? extractionResult,
    bool? isLoading,
    String? error,
  }) {
    return JobMatchingState(
      jobDescriptions: jobDescriptions ?? this.jobDescriptions,
      currentJob: currentJob ?? this.currentJob,
      extractionResult: extractionResult ?? this.extractionResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class JobMatchingController extends StateNotifier<JobMatchingState> {
  final KeywordExtractorService _keywordExtractorService;

  JobMatchingController({KeywordExtractorService? keywordExtractorService})
      : _keywordExtractorService =
            keywordExtractorService ?? KeywordExtractorService(),
        super(const JobMatchingState());

  Future<void> submitJobDescription(String description, {String? title, String? url}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Simulate matching latency
      await Future.delayed(const Duration(milliseconds: 10));
      final newJob = JobDescription(
        descriptionText: description,
        title: title ?? 'Job Description',
        url: url,
      );

      final extractionResult = _keywordExtractorService.extractAndCompare(
        jobDescriptionText: description,
      );

      state = state.copyWith(
        isLoading: false,
        currentJob: newJob,
        extractionResult: extractionResult,
        jobDescriptions: [...state.jobDescriptions, newJob],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitJobDescriptionWithResume(
    String description, {
    String? title,
    String? url,
    Resume? resume,
    List<String>? userSkills,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 10));
      final newJob = JobDescription(
        descriptionText: description,
        title: title ?? 'Job Description',
        url: url,
      );

      final extractionResult = _keywordExtractorService.extractAndCompare(
        jobDescriptionText: description,
        resume: resume,
        userSkills: userSkills,
      );

      state = state.copyWith(
        isLoading: false,
        currentJob: newJob,
        extractionResult: extractionResult,
        jobDescriptions: [...state.jobDescriptions, newJob],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearCurrentJob() {
    state = JobMatchingState(
      jobDescriptions: state.jobDescriptions,
      currentJob: null,
      extractionResult: null,
      isLoading: false,
      error: null,
    );
  }
}

final jobMatchingControllerProvider =
    StateNotifierProvider<JobMatchingController, JobMatchingState>((ref) {
  final extractorService = ref.watch(keywordExtractorServiceProvider);
  return JobMatchingController(keywordExtractorService: extractorService);
});

