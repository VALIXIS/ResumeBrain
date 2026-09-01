import '../models/resume_models.dart';

/// Status of cloud synchronization operations.
enum CloudSyncStatus {
  unsupported,
  success,
  failed,
  offline,
}

/// Represents the result of a cloud synchronization attempt.
class CloudSyncResult {
  final CloudSyncStatus status;
  final String message;
  final DateTime timestamp;
  final Resume? syncedResume;

  const CloudSyncResult({
    required this.status,
    required this.message,
    required this.timestamp,
    this.syncedResume,
  });

  /// Factory constructor for unsupported cloud sync operations.
  factory CloudSyncResult.unsupported([String? customMessage]) {
    return CloudSyncResult(
      status: CloudSyncStatus.unsupported,
      message: customMessage ?? 'Cloud synchronization is currently unsupported.',
      timestamp: DateTime.now(),
    );
  }

  bool get isSupported => status != CloudSyncStatus.unsupported;
  bool get isSuccess => status == CloudSyncStatus.success;
}

/// Boundary adapter interface and stub implementation for future cloud synchronization.
abstract class CloudSyncAdapter {
  /// Whether cloud synchronization is currently available and enabled.
  bool get isCloudSyncAvailable;

  /// Uploads or updates a resume to remote cloud storage (stubbed).
  Future<CloudSyncResult> uploadResume(Resume resume);

  /// Downloads a resume from remote cloud storage by ID (stubbed).
  Future<CloudSyncResult> downloadResume(String id);

  /// Performs a full synchronization of local and remote resumes (stubbed).
  Future<CloudSyncResult> syncAll(List<Resume> localResumes);
}

/// Default stub implementation of [CloudSyncAdapter].
///
/// Intentionally performs no network or remote authentication operations.
/// Explicitly reports [CloudSyncStatus.unsupported] for all sync operations
/// to ensure predictable boundary behavior without fake success indicators.
class StubCloudSyncAdapter implements CloudSyncAdapter {
  const StubCloudSyncAdapter();

  @override
  bool get isCloudSyncAvailable => false;

  @override
  Future<CloudSyncResult> uploadResume(Resume resume) async {
    return CloudSyncResult.unsupported(
      'Cloud sync is not configured. Local persistence remains active.',
    );
  }

  @override
  Future<CloudSyncResult> downloadResume(String id) async {
    return CloudSyncResult.unsupported(
      'Cloud sync is not configured. Local persistence remains active.',
    );
  }

  @override
  Future<CloudSyncResult> syncAll(List<Resume> localResumes) async {
    return CloudSyncResult.unsupported(
      'Cloud sync is not configured. Local persistence remains active.',
    );
  }
}
