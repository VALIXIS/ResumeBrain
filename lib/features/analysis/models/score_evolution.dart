import 'analysis_history_entry.dart';
import 'resume_analysis_report.dart';

/// Trend direction for score comparison.
enum ScoreTrend { improved, declined, unchanged, initial }

/// Represents score evolution for a specific resume section.
class SectionScoreDiff {
  final String categoryKey;
  final int currentScore;
  final int? previousScore;
  final int? difference;

  const SectionScoreDiff({
    required this.categoryKey,
    required this.currentScore,
    this.previousScore,
    this.difference,
  });

  bool get isImprovement => (difference ?? 0) > 0;
  bool get isDecline => (difference ?? 0) < 0;
  bool get isUnchanged => (difference ?? 0) == 0;
}

/// Represents the overall score evolution and section-level trends.
class ScoreEvolution {
  final int currentScore;
  final int? previousScore;
  final int? scoreDifference;
  final ScoreTrend trend;
  final DateTime currentDate;
  final DateTime? previousDate;
  final List<SectionScoreDiff> sectionDiffs;
  final int totalSnapshots;

  const ScoreEvolution({
    required this.currentScore,
    this.previousScore,
    this.scoreDifference,
    required this.trend,
    required this.currentDate,
    this.previousDate,
    this.sectionDiffs = const [],
    required this.totalSnapshots,
  });

  bool get hasPrevious => previousScore != null;

  /// Computes score evolution given the historical snapshots and the current report.
  factory ScoreEvolution.compute(
    List<AnalysisHistoryEntry> history,
    ResumeAnalysisReport currentReport,
  ) {
    if (history.isEmpty) {
      return ScoreEvolution(
        currentScore: currentReport.overallScore,
        trend: ScoreTrend.initial,
        currentDate: currentReport.timestamp,
        totalSnapshots: 1,
      );
    }

    // Sort entries descending by timestamp (newest first)
    final sorted = List<AnalysisHistoryEntry>.from(history)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Identify the previous snapshot (first snapshot older than currentReport or previous in list)
    AnalysisHistoryEntry? previousEntry;
    if (sorted.length > 1) {
      // If the latest history entry is the current report, pick the 2nd one
      if (sorted.first.overallScore == currentReport.overallScore &&
          sorted.first.timestamp.difference(currentReport.timestamp).inSeconds.abs() <= 5) {
        previousEntry = sorted[1];
      } else {
        previousEntry = sorted.first;
      }
    }

    if (previousEntry == null) {
      return ScoreEvolution(
        currentScore: currentReport.overallScore,
        trend: ScoreTrend.initial,
        currentDate: currentReport.timestamp,
        totalSnapshots: sorted.length,
      );
    }

    final diff = currentReport.overallScore - previousEntry.overallScore;
    ScoreTrend trend;
    if (diff > 0) {
      trend = ScoreTrend.improved;
    } else if (diff < 0) {
      trend = ScoreTrend.declined;
    } else {
      trend = ScoreTrend.unchanged;
    }

    // Compute section-level differences
    final sectionDiffs = <SectionScoreDiff>[];
    currentReport.categoryScores.forEach((key, currScore) {
      final prevScore = previousEntry?.categoryScores[key];
      final sDiff = prevScore != null ? currScore - prevScore : null;
      sectionDiffs.add(
        SectionScoreDiff(
          categoryKey: key,
          currentScore: currScore,
          previousScore: prevScore,
          difference: sDiff,
        ),
      );
    });

    return ScoreEvolution(
      currentScore: currentReport.overallScore,
      previousScore: previousEntry.overallScore,
      scoreDifference: diff,
      trend: trend,
      currentDate: currentReport.timestamp,
      previousDate: previousEntry.timestamp,
      sectionDiffs: sectionDiffs,
      totalSnapshots: sorted.length,
    );
  }
}
