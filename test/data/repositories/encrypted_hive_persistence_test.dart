import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resume_brain/core/security/resume_encryption_service.dart';
import 'package:resume_brain/data/repositories/resume_database_migrator.dart';

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
  group('Encrypted Hive Persistence & Migration Tests', () {
    late Box testBox;
    late ResumeEncryptionService encryptionService;

    setUpAll(() async {
      Hive.init('./test_hive_tmp');
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    setUp(() async {
      final mockStorage = MockSecureStorage();
      encryptionService = ResumeEncryptionService(secureStorage: mockStorage);
      testBox = await Hive.openBox('test_resume_box_${DateTime.now().microsecondsSinceEpoch}');
    });

    tearDown(() async {
      await testBox.clear();
      await testBox.close();
    });

    test('Legacy unencrypted resume records are migrated to encrypted payloads without losing data', () async {
      // Put legacy plaintext map into box
      final legacyMap = {
        'schemaVersion': 1,
        'id': 'legacy-res-1',
        'title': 'Legacy Unencrypted Resume',
        'templateId': 'modern_classic',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'personalInfo': {
          'fullName': 'Legacy User',
          'email': 'legacy@example.com',
        },
      };
      await testBox.put('legacy-res-1', legacyMap);

      // Verify stored initially as raw plaintext map without ciphertext
      final rawBefore = testBox.get('legacy-res-1');
      expect(rawBefore, isA<Map>());
      expect(rawBefore.containsKey('ciphertext'), isFalse);

      // Run migration
      await ResumeDatabaseMigrator.runMigrations(testBox, encryptionService: encryptionService);

      // Verify stored after migration as encrypted envelope map with ciphertext
      final rawAfter = testBox.get('legacy-res-1');
      expect(rawAfter, isA<Map>());
      expect(rawAfter.containsKey('ciphertext'), isTrue);
      expect(rawAfter.containsKey('nonce'), isTrue);

      // Decrypt and verify contents preserved
      final decryptedJson = await encryptionService.decryptStringEnvelope(Map<String, dynamic>.from(rawAfter));
      final decoded = jsonDecode(decryptedJson);
      expect(decoded['id'], equals('legacy-res-1'));
      expect(decoded['personalInfo']['fullName'], equals('Legacy User'));
    });
  });
}
