import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:resume_brain/core/security/pin_service.dart';
import 'package:resume_brain/core/security/security_controller.dart';

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

class MockLocalAuthentication implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityController Tests', () {
    late MockSecureStorage mockStorage;
    late PinService pinService;
    late MockLocalAuthentication mockLocalAuth;
    late SecurityController controller;

    setUp(() async {
      mockStorage = MockSecureStorage();
      pinService = PinService(secureStorage: mockStorage);
      mockLocalAuth = MockLocalAuthentication();
      controller = SecurityController(
        localAuth: mockLocalAuth,
        pinService: pinService,
        secureStorage: mockStorage,
      );
      await controller.init();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is unlocked when privacy lock is disabled', () {
      expect(controller.state.isLockEnabled, isFalse);
      expect(controller.state.isLocked, isFalse);
    });

    test('Enabling lock sets state and locks app when requested', () async {
      await controller.setLockEnabled(true);
      expect(controller.state.isLockEnabled, isTrue);

      controller.lock();
      expect(controller.state.isLocked, isTrue);

      controller.unlock();
      expect(controller.state.isLocked, isFalse);
    });

    test('App lifecycle background transition automatically locks app when lock is enabled', () async {
      await controller.setLockEnabled(true);
      controller.unlock();
      expect(controller.state.isLocked, isFalse);

      // Simulate app going to background
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(controller.state.isLocked, isTrue);
    });

    test('Authenticating with valid PIN unlocks state', () async {
      await controller.setLockEnabled(true);
      await controller.setPin('1234');
      controller.lock();
      expect(controller.state.isLocked, isTrue);

      final success = await controller.authenticateWithPin('1234');
      expect(success, isTrue);
      expect(controller.state.isLocked, isFalse);
    });
  });
}
