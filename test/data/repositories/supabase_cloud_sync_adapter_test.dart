import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/security/resume_encryption_service.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/supabase_cloud_sync_adapter.dart';

class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({required String key, iOptions, aOptions, eOptions, mOptions, lOptions, webOptions, wOptions, macOsOptions}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String? value, iOptions, aOptions, eOptions, mOptions, lOptions, webOptions, wOptions, macOsOptions}) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, iOptions, aOptions, eOptions, mOptions, lOptions, webOptions, wOptions, macOsOptions}) async {
    _storage.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SupabaseCloudSyncAdapter Boundary Tests', () {
    late ResumeEncryptionService encryptionService;
    late SupabaseCloudSyncAdapter adapter;

    setUp(() {
      final mockStorage = MockSecureStorage();
      encryptionService = ResumeEncryptionService(secureStorage: mockStorage);
      adapter = SupabaseCloudSyncAdapter(encryptionService: encryptionService);
    });

    final sampleResume = Resume(
      id: 'res-sync-1',
      title: 'Cloud Test Resume',
      updatedAt: DateTime.now(),
    );

    test('Unconfigured / unauthenticated Supabase client returns explicit unsupported or failed result', () async {
      expect(adapter.isCloudSyncAvailable, isFalse);

      final uploadResult = await adapter.uploadResume(sampleResume);
      expect(uploadResult.isSuccess, isFalse);
      expect(uploadResult.status, anyOf(equals(CloudSyncStatus.unsupported), equals(CloudSyncStatus.failed)));

      final downloadResult = await adapter.downloadResume('res-sync-1');
      expect(downloadResult.isSuccess, isFalse);

      final syncAllResult = await adapter.syncAll([sampleResume]);
      expect(syncAllResult.isSuccess, isFalse);
    });
  });
}
