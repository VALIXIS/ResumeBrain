import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_bootstrap.dart';

/// StateNotifier providing real-time [StorageStatus] to the UI.
class StorageBootstrapNotifier extends StateNotifier<StorageStatus> {
  final StorageBootstrapService _service;

  StorageBootstrapNotifier(this._service) : super(_service.status) {
    _init();
  }

  Future<void> _init() async {
    if (_service.status == StorageStatus.uninitialized) {
      state = StorageStatus.initializing;
      await _service.initializeStorage();
      state = _service.status;
    }
  }

  Future<void> retry() async {
    state = StorageStatus.initializing;
    await _service.retryInitialization();
    state = _service.status;
  }
}

/// Provider for centralized storage bootstrap status.
final storageBootstrapProvider =
    StateNotifierProvider<StorageBootstrapNotifier, StorageStatus>((ref) {
  return StorageBootstrapNotifier(StorageBootstrapService());
});
