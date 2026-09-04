import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/repositories/resume_database_migrator.dart';
import '../constants/app_constants.dart';

/// Represents the explicit status of centralized persistent storage.
enum StorageStatus {
  uninitialized,
  initializing,
  ready,
  error,
}

/// Stage labels for production startup diagnostics.
class StartupStages {
  static const String stage1Binding = 'STARTUP_STAGE_1_BINDING';
  static const String stage2RunApp = 'STARTUP_STAGE_2_RUN_APP';
  static const String stage3StorageInit = 'STARTUP_STAGE_3_STORAGE_INIT';
  static const String stage4ResumeBox = 'STARTUP_STAGE_4_RESUME_BOX';
  static const String stage5HistoryBox = 'STARTUP_STAGE_5_HISTORY_BOX';
  static const String stage6ProviderBoot = 'STARTUP_STAGE_6_PROVIDER_BOOT';
  static const String stage7HomeRender = 'STARTUP_STAGE_7_HOME_RENDER';

  static void logStage(String stage, [String? detail]) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] [STARTUP_DIAGNOSTICS] $stage${detail != null ? ' - $detail' : ''}');
  }
}

/// Centralized owner for Hive initialization and box management.
class StorageBootstrapService {
  static final StorageBootstrapService _instance = StorageBootstrapService._internal();
  factory StorageBootstrapService() => _instance;
  StorageBootstrapService._internal();

  StorageStatus _status = StorageStatus.uninitialized;
  String? _errorMessage;
  Box? _resumesBox;
  Box? _analysisHistoryBox;

  StorageStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == StorageStatus.ready;

  Box? get resumesBox => _resumesBox != null && _resumesBox!.isOpen ? _resumesBox : null;
  Box? get analysisHistoryBox =>
      _analysisHistoryBox != null && _analysisHistoryBox!.isOpen ? _analysisHistoryBox : null;

  /// Centralized storage initialization. Runs ONCE asynchronously after runApp().
  Future<void> initializeStorage() async {
    if (_status == StorageStatus.ready || _status == StorageStatus.initializing) {
      return;
    }

    _status = StorageStatus.initializing;
    _errorMessage = null;
    StartupStages.logStage('STORAGE_INIT_START', 'Initializing Hive core');

    try {
      // 1. Single owner initialization of Hive for Flutter
      await Hive.initFlutter();

      // 2. Open Resume box safely
      StartupStages.logStage('RESUME_BOX_OPEN_START', 'Opening ${AppConstants.hiveResumeBox}');
      if (Hive.isBoxOpen(AppConstants.hiveResumeBox)) {
        _resumesBox = Hive.box(AppConstants.hiveResumeBox);
      } else {
        _resumesBox = await Hive.openBox(AppConstants.hiveResumeBox);
      }
      StartupStages.logStage('RESUME_BOX_OPEN_COMPLETE', 'Opened ${AppConstants.hiveResumeBox}');

      // Run automatic, deterministic database migration hooks
      if (_resumesBox != null) {
        await ResumeDatabaseMigrator.runMigrations(_resumesBox!);
      }

      // 3. Open Analysis History box safely
      const historyBoxName = 'analysis_history_box';
      StartupStages.logStage('HISTORY_BOX_OPEN_START', 'Opening $historyBoxName');
      if (Hive.isBoxOpen(historyBoxName)) {
        _analysisHistoryBox = Hive.box(historyBoxName);
      } else {
        _analysisHistoryBox = await Hive.openBox(historyBoxName);
      }
      StartupStages.logStage('HISTORY_BOX_OPEN_COMPLETE', 'Opened $historyBoxName');

      _status = StorageStatus.ready;
      StartupStages.logStage('STORAGE_INIT_COMPLETE', 'Centralized storage initialized successfully');
    } catch (e, stack) {
      _status = StorageStatus.error;
      _errorMessage = e.toString();
      StartupStages.logStage(
        'STORAGE_INIT_ERROR',
        'Storage init error: $e\n$stack',
      );
      // NOTE: We DO NOT call deleteBoxFromDisk to preserve user data.
    }
  }

  /// Retries storage initialization if a temporary lock or error occurred.
  Future<void> retryInitialization() async {
    _status = StorageStatus.uninitialized;
    await initializeStorage();
  }
}
