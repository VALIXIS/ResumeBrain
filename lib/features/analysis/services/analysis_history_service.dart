import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/storage/storage_bootstrap.dart';
import '../models/analysis_history_entry.dart';
import '../models/resume_analysis_report.dart';

/// Service responsible for persisting and retrieving historical analysis snapshots
/// for each resume document.
class AnalysisHistoryService {
  static const String boxName = 'analysis_history_box';
  static const int maxHistoryPerResume = 20;

  final Map<String, List<AnalysisHistoryEntry>> _memoryFallback = {};

  /// Storage is initialized centrally by StorageBootstrapService.
  Future<void> init() async {
    await StorageBootstrapService().initializeStorage();
  }

  Box? get _safeBox => StorageBootstrapService().analysisHistoryBox;

  /// Retrieves the history of analysis entries for a given [resumeId],
  /// sorted from newest to oldest.
  Future<List<AnalysisHistoryEntry>> getHistoryForResume(String resumeId) async {
    if (resumeId.isEmpty) return [];

    try {
      final box = _safeBox;
      if (box != null) {
        final dynamic rawList = box.get(resumeId);
        if (rawList is List) {
          final entries = <AnalysisHistoryEntry>[];
          for (final item in rawList) {
            if (item is Map) {
              entries.add(
                AnalysisHistoryEntry.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              );
            }
          }
          entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return entries;
        }
      }

      // Memory fallback lookup
      final memList = _memoryFallback[resumeId] ?? [];
      memList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(memList);
    } catch (_) {
      return [];
    }
  }

  /// Records a new analysis snapshot for a resume.
  Future<void> recordAnalysis(ResumeAnalysisReport report) async {
    if (report.resumeId.isEmpty) return;

    try {
      final currentHistory = await getHistoryForResume(report.resumeId);

      // Check if duplicate snapshot (same score and within 10 seconds)
      if (currentHistory.isNotEmpty) {
        final latest = currentHistory.first;
        if (latest.overallScore == report.overallScore &&
            latest.timestamp.difference(report.timestamp).inSeconds.abs() <= 10) {
          return;
        }
      }

      final newEntry = AnalysisHistoryEntry.fromReport(report);
      final updatedList = [newEntry, ...currentHistory];

      // Bound history length
      if (updatedList.length > maxHistoryPerResume) {
        updatedList.removeRange(maxHistoryPerResume, updatedList.length);
      }

      // Save to Hive
      final box = _safeBox;
      if (box != null) {
        final mapList = updatedList.map((e) => e.toMap()).toList();
        await box.put(report.resumeId, mapList);
      }

      // Sync memory fallback
      _memoryFallback[report.resumeId] = updatedList;
    } catch (_) {
      // Non-fatal error handling: keep in memory fallback
      final entry = AnalysisHistoryEntry.fromReport(report);
      final mem = _memoryFallback[report.resumeId] ?? [];
      _memoryFallback[report.resumeId] = [entry, ...mem];
    }
  }

  /// Clears the analysis history for a given [resumeId].
  Future<void> clearHistory(String resumeId) async {
    try {
      final box = _safeBox;
      if (box != null) {
        await box.delete(resumeId);
      }
      _memoryFallback.remove(resumeId);
    } catch (_) {
      _memoryFallback.remove(resumeId);
    }
  }
}
