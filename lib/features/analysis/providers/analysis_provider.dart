import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../models/analysis_dashboard_stats.dart';
import '../models/analysis_history_entry.dart';
import '../models/resume_analysis_report.dart';
import '../models/score_evolution.dart';
import '../services/ai_analysis_adapter.dart';
import '../services/analysis_engine.dart';
import '../services/analysis_history_service.dart';

/// Provider exposing the deterministic [AnalysisEngine] fallback instance.
final analysisEngineProvider = Provider<AnalysisEngine>((ref) {
  return MockAnalysisEngine();
});

/// Provider exposing the [AnalysisHistoryService] for persisting score history.
final analysisHistoryServiceProvider = Provider<AnalysisHistoryService>((ref) {
  final service = AnalysisHistoryService();
  service.init();
  return service;
});

/// Provider exposing the [AiAnalysisAdapter] connecting the [AIService] contract
/// to the analysis layer with safe deterministic mock fallback handling.
final aiAnalysisAdapterProvider = Provider<AiAnalysisAdapter>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final fallbackEngine = ref.watch(analysisEngineProvider);
  return AiAnalysisAdapter(
    aiService: aiService,
    fallbackEngine: fallbackEngine,
  );
});

/// FutureProvider exposing historical analysis snapshots for a given [resumeId].
final resumeAnalysisHistoryProvider =
    FutureProvider.family<List<AnalysisHistoryEntry>, String>(
        (ref, resumeId) async {
  if (resumeId.isEmpty) return [];
  final historyService = ref.watch(analysisHistoryServiceProvider);
  return historyService.getHistoryForResume(resumeId);
});

/// FutureProvider computing [ScoreEvolution] for a given [ResumeAnalysisReport].
final scoreEvolutionProvider =
    FutureProvider.family<ScoreEvolution, ResumeAnalysisReport>(
        (ref, report) async {
  final history =
      await ref.watch(resumeAnalysisHistoryProvider(report.resumeId).future);
  return ScoreEvolution.compute(history, report);
});

/// FutureProvider exposing analysis for a single specific [Resume].
final singleResumeAnalysisProvider =
    FutureProvider.family<ResumeAnalysisReport, Resume>((ref, resume) async {
  final adapter = ref.watch(aiAnalysisAdapterProvider);
  final report = await adapter.analyze(resume);

  // Persist snapshot to history
  final historyService = ref.read(analysisHistoryServiceProvider);
  await historyService.recordAnalysis(report);
  Future.microtask(() {
    ref.invalidate(resumeAnalysisHistoryProvider(resume.id));
  });

  return report;
});

/// FutureProvider exposing analysis for the current active resume in [currentResumeProvider].
final currentResumeAnalysisProvider =
    FutureProvider<ResumeAnalysisReport?>((ref) async {
  final resume = ref.watch(currentResumeProvider);
  if (resume == null) return null;
  final adapter = ref.watch(aiAnalysisAdapterProvider);
  final report = await adapter.analyze(resume);

  // Persist snapshot to history
  final historyService = ref.read(analysisHistoryServiceProvider);
  await historyService.recordAnalysis(report);
  Future.microtask(() {
    ref.invalidate(resumeAnalysisHistoryProvider(resume.id));
  });

  return report;
});

/// FutureProvider exposing the aggregated [AnalysisDashboardStats] for the dashboard.
final analysisDashboardStatsProvider =
    FutureProvider<AnalysisDashboardStats>((ref) async {
  // Watch the resumes list provider state.
  final resumesState = ref.watch(resumesListProvider);

  // If the resumes state is in error and has no previous data, propagate the error.
  if (resumesState is AsyncError && resumesState.value == null) {
    throw resumesState.error!;
  }

  final List<Resume>? resumes = resumesState.value;
  if (resumes == null || resumes.isEmpty) {
    return AnalysisDashboardStats(
      totalResumes: 0,
      averageAtsScore: 0.0,
      recentActivity: const [],
    );
  }

  final adapter = ref.watch(aiAnalysisAdapterProvider);

  // Generate analysis reports for all resumes.
  final reports =
      await Future.wait(resumes.map((resume) => adapter.analyze(resume)));

  // Calculate statistics.
  final totalResumes = resumes.length;

  double averageAtsScore = 0.0;
  if (reports.isNotEmpty) {
    final totalScore =
        reports.fold<int>(0, (sum, report) => sum + report.overallScore);
    averageAtsScore = (totalScore / reports.length).clamp(0.0, 100.0);
  }

  // Obtain the recent activity.
  final recentActivity = _calculateRecentActivity(resumes, reports);

  return AnalysisDashboardStats(
    totalResumes: totalResumes,
    averageAtsScore: averageAtsScore,
    recentActivity: recentActivity,
  );
});

/// Isolated helper to compute the deterministic recent activity.
List<ResumeAnalysisReport> _calculateRecentActivity(
  List<Resume> resumes,
  List<ResumeAnalysisReport> reports,
) {
  if (reports.isEmpty) return const [];

  final pairedReports = <MapEntry<DateTime, ResumeAnalysisReport>>[];
  for (final report in reports) {
    final index = resumes.indexWhere((r) => r.id == report.resumeId);
    final timestamp =
        index != -1 ? resumes[index].updatedAt : report.timestamp;
    pairedReports.add(MapEntry(
      timestamp,
      report.copyWith(timestamp: timestamp),
    ));
  }

  // Sort by timestamp descending (most recent first)
  pairedReports.sort((a, b) => b.key.compareTo(a.key));

  // Take the 3 most recent activities
  return pairedReports
      .map((entry) => entry.value)
      .take(3)
      .toList();
}
