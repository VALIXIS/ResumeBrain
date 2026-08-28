import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../models/analysis_dashboard_stats.dart';
import '../models/resume_analysis_report.dart';
import '../services/analysis_engine.dart';

/// Provider exposing the [AnalysisEngine] instance.
final analysisEngineProvider = Provider<AnalysisEngine>((ref) {
  return MockAnalysisEngine();
});

/// FutureProvider exposing the aggregated [AnalysisDashboardStats] for the dashboard.
final analysisDashboardStatsProvider = FutureProvider<AnalysisDashboardStats>((ref) async {
  // Watch the resumes list provider state.
  final resumesState = ref.watch(resumesListProvider);

  // If the resumes state is in error and has no previous data, propagate the error.
  if (resumesState is AsyncError && resumesState.value == null) {
    throw resumesState.error!;
  }

  // If the resumes list is not loaded yet, return a future that remains in loading state.
  final List<Resume>? resumes = resumesState.value;
  if (resumes == null) {
    return Completer<AnalysisDashboardStats>().future;
  }

  final engine = ref.watch(analysisEngineProvider);

  // Generate analysis reports for all resumes.
  final reports = await Future.wait(resumes.map((resume) => engine.analyze(resume)));

  // Calculate statistics.
  final totalResumes = resumes.length;
  
  double averageAtsScore = 0.0;
  if (reports.isNotEmpty) {
    final totalScore = reports.fold<int>(0, (sum, report) => sum + report.overallScore);
    averageAtsScore = (totalScore / reports.length).clamp(0.0, 100.0);
  }

  // Obtain the recent activity.
  // This is isolated in a separate helper function to allow easy replacement in the future.
  final recentActivity = _calculateRecentActivity(resumes, reports);

  return AnalysisDashboardStats(
    totalResumes: totalResumes,
    averageAtsScore: averageAtsScore,
    recentActivity: recentActivity,
  );
});

/// Isolated helper to compute the deterministic recent activity.
/// Currently, since there is no persistent history layer for reports,
/// we pair reports with their corresponding resume's `updatedAt` field,
/// sort them descending by date, and take the top 3.
List<ResumeAnalysisReport> _calculateRecentActivity(
  List<Resume> resumes,
  List<ResumeAnalysisReport> reports,
) {
  if (reports.isEmpty) return const [];

  final pairedReports = <MapEntry<DateTime, ResumeAnalysisReport>>[];
  for (final report in reports) {
    final index = resumes.indexWhere((r) => r.id == report.resumeId);
    final timestamp = index != -1 ? resumes[index].updatedAt : report.timestamp;
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
