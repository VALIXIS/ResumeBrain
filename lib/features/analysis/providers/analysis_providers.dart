import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../models/analysis_models.dart';
import '../services/analysis_engine.dart';

/// StateNotifier that manages the active resume analysis report.
class ResumeAnalysisNotifier extends StateNotifier<AsyncValue<ResumeAnalysisReport?>> {
  final Ref _ref;

  ResumeAnalysisNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Analyzes a specific resume or the active resume in [currentResumeProvider].
  Future<void> analyzeResume([Resume? targetResume]) async {
    final resume = targetResume ?? _ref.read(currentResumeProvider);
    if (resume == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      state = const AsyncValue.loading();
      // Perform fast deterministic ATS evaluation
      final report = ResumeAnalysisEngine.evaluate(resume);
      state = AsyncValue.data(report);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Clears the current analysis report.
  void clearAnalysis() {
    state = const AsyncValue.data(null);
  }
}

/// Provider exposing the latest [ResumeAnalysisReport] state for the active resume.
final resumeAnalysisProvider =
    StateNotifierProvider<ResumeAnalysisNotifier, AsyncValue<ResumeAnalysisReport?>>((ref) {
  return ResumeAnalysisNotifier(ref);
});

/// Auto-analyzing provider that derives the analysis from [currentResumeProvider].
final activeResumeAnalysisProvider = Provider<AsyncValue<ResumeAnalysisReport?>>((ref) {
  final resume = ref.watch(currentResumeProvider);
  if (resume == null) {
    return const AsyncValue.data(null);
  }
  try {
    final report = ResumeAnalysisEngine.evaluate(resume);
    return AsyncValue.data(report);
  } catch (e, stack) {
    return AsyncValue.error(e, stack);
  }
});
