import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/security/resume_encryption_service.dart';

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
  group('ResumeEncryptionService Tests', () {
    late MockSecureStorage mockStorage;
    late ResumeEncryptionService encryptionService;

    setUp(() {
      mockStorage = MockSecureStorage();
      encryptionService = ResumeEncryptionService(secureStorage: mockStorage);
    });

    test('Master key generation produces valid 256-bit key and stores it securely', () async {
      final key = await encryptionService.getMasterKey();
      expect(key.bytes.length, equals(32));

      final storedKey = await mockStorage.read(key: ResumeEncryptionService.kKeyAlias);
      expect(storedKey, isNotNull);
      expect(base64Decode(storedKey!).length, equals(32));
    });

    test('Encrypt and decrypt string round trip returns identical plaintext', () async {
      const plaintext = 'Jane Doe - Senior Software Architect (jane@example.com)';
      final envelope = await encryptionService.encryptString(plaintext);

      expect(envelope['formatVersion'], equals(1));
      expect(envelope['algorithm'], equals('AES-256-CBC-HMAC-SHA256'));
      expect(envelope['nonce'], isNotNull);
      expect(envelope['ciphertext'], isNotNull);
      expect(envelope['mac'], isNotNull);

      // Ciphertext must NOT contain plaintext string
      expect(envelope['ciphertext'], isNot(contains(plaintext)));

      final decrypted = await encryptionService.decryptStringEnvelope(envelope);
      expect(decrypted, equals(plaintext));
    });

    test('Encrypt and decrypt raw binary bytes round trip', () async {
      final rawBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]); // %PDF-1.4
      final envelope = await encryptionService.encryptBytes(rawBytes);

      final decryptedBytes = await encryptionService.decryptBytesEnvelope(envelope);
      expect(decryptedBytes, equals(rawBytes));
    });

    test('Tampered ciphertext causes authentication MAC mismatch exception', () async {
      const plaintext = 'Sensitive Resume Content';
      final envelope = await encryptionService.encryptString(plaintext);

      // Tamper ciphertext payload
      final tamperedCiphertextBytes = base64Decode(envelope['ciphertext']);
      tamperedCiphertextBytes[0] ^= 0xFF; // Flip bits
      envelope['ciphertext'] = base64Encode(tamperedCiphertextBytes);

      expect(
        () async => await encryptionService.decryptStringEnvelope(envelope),
        throwsA(isA<ResumeEncryptionException>().having(
          (e) => e.message,
          'message',
          contains('Authentication tag mismatch'),
        )),
      );
    });

    test('Decrypting with wrong master key fails authentication', () async {
      const plaintext = 'Top Secret Resume Info';
      final envelope = await encryptionService.encryptString(plaintext);

      // Create separate encryption service with different key
      final otherService = ResumeEncryptionService(secureStorage: MockSecureStorage());
      otherService.setKeyForTesting(encrypt_pkg.Key.fromSecureRandom(32));

      expect(
        () async => await otherService.decryptStringEnvelope(envelope),
        throwsA(isA<ResumeEncryptionException>()),
      );
    });

    test('Unsupported envelope format version throws ResumeEncryptionException', () async {
      final invalidEnvelope = {
        'formatVersion': 999,
        'algorithm': 'AES-256-CBC-HMAC-SHA256',
        'nonce': 'abc',
        'ciphertext': 'def',
        'mac': 'ghi',
      };

      expect(
        () async => await encryptionService.decryptStringEnvelope(invalidEnvelope),
        throwsA(isA<ResumeEncryptionException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported encryption envelope format version'),
        )),
      );
    });
  });
}
