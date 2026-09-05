import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/security/pin_service.dart';

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
  group('PinService Tests', () {
    late MockSecureStorage mockStorage;
    late PinService pinService;

    setUp(() {
      mockStorage = MockSecureStorage();
      pinService = PinService(secureStorage: mockStorage);
    });

    test('Initial state reports no PIN set', () async {
      expect(await pinService.hasPin(), isFalse);
    });

    test('Setting PIN computes PBKDF2 hash with unique salt and never stores raw PIN', () async {
      await pinService.setPin('1234');
      expect(await pinService.hasPin(), isTrue);

      final storedHash = await mockStorage.read(key: PinService.kPinHashAlias);
      final storedSalt = await mockStorage.read(key: PinService.kPinSaltAlias);

      expect(storedHash, isNotNull);
      expect(storedSalt, isNotNull);
      expect(storedHash, isNot(contains('1234')));
      expect(storedSalt, isNot(contains('1234')));
    });

    test('Valid PIN verifies successfully and resets failed attempt count', () async {
      await pinService.setPin('5678');
      final success = await pinService.verifyPin('5678');

      expect(success, isTrue);
      expect(pinService.failedAttempts, equals(0));
      expect(pinService.isLockedOut, isFalse);
    });

    test('Invalid PIN increments failed attempt counter and enforces lockout at threshold', () async {
      await pinService.setPin('9999');

      for (int i = 1; i <= 4; i++) {
        final res = await pinService.verifyPin('0000');
        expect(res, isFalse);
        expect(pinService.failedAttempts, equals(i));
        expect(pinService.isLockedOut, isFalse);
      }

      // 5th failed attempt triggers lockout
      final res5 = await pinService.verifyPin('0000');
      expect(res5, isFalse);
      expect(pinService.failedAttempts, equals(5));
      expect(pinService.isLockedOut, isTrue);

      // Subsequent attempt during lockout returns false immediately
      final res6 = await pinService.verifyPin('9999'); // Even correct PIN during lockout fails
      expect(res6, isFalse);
    });

    test('Removing PIN clears stored cryptographic credentials', () async {
      await pinService.setPin('4321');
      expect(await pinService.hasPin(), isTrue);

      await pinService.removePin();
      expect(await pinService.hasPin(), isFalse);
      expect(await mockStorage.read(key: PinService.kPinHashAlias), isNull);
    });
  });
}
