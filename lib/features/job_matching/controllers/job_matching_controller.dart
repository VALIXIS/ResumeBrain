import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_description.dart';

class JobMatchingState {
  final List<JobDescription> jobDescriptions;
  final JobDescription? currentJob;
  final bool isLoading;
  final String? error;

  const JobMatchingState({
    this.jobDescriptions = const [],
    this.currentJob,
    this.isLoading = false,
    this.error,
  });

  JobMatchingState copyWith({
    List<JobDescription>? jobDescriptions,
    JobDescription? currentJob,
    bool? isLoading,
    String? error,
  }) {
    return JobMatchingState(
      jobDescriptions: jobDescriptions ?? this.jobDescriptions,
      currentJob: currentJob ?? this.currentJob,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class JobMatchingController extends StateNotifier<JobMatchingState> {
  JobMatchingController() : super(const JobMatchingState());

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
      state = state.copyWith(
        isLoading: false,
        currentJob: newJob,
        jobDescriptions: [...state.jobDescriptions, newJob],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearCurrentJob() {
    state = state.copyWith(currentJob: null);
  }
}

final jobMatchingControllerProvider =
    StateNotifierProvider<JobMatchingController, JobMatchingState>((ref) {
  return JobMatchingController();
});
