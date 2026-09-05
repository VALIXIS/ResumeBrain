import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure PIN authentication, PBKDF2 salt generation, password hashing, and attempt rate limiting.
class PinService {
  static const String kPinHashAlias = 'resume_brain_pin_hash';
  static const String kPinSaltAlias = 'resume_brain_pin_salt';
  static const int kPbkdf2Iterations = 10000;
  static const int kMaxFailedAttempts = 5;
  static const Duration kLockoutDuration = Duration(seconds: 30);

  final FlutterSecureStorage _secureStorage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  PinService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  DateTime? get lockoutUntil => _lockoutUntil;

  /// Returns true if a PIN has been set by the user.
  Future<bool> hasPin() async {
    try {
      final hash = await _secureStorage.read(key: kPinHashAlias);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking PIN presence: $e');
      return false;
    }
  }

  /// Sets or updates the PIN using salted PBKDF2 key derivation.
  Future<void> setPin(String pin) async {
    if (pin.trim().length < 4) {
      throw ArgumentError('PIN must be at least 4 digits long.');
    }

    final saltBytes = encrypt_pkg.IV.fromSecureRandom(16).bytes;
    final saltBase64 = base64Encode(saltBytes);

    final hashBytes = _pbkdf2Sha256(pin.trim(), saltBytes, kPbkdf2Iterations);
    final hashBase64 = base64Encode(hashBytes);

    await _secureStorage.write(key: kPinSaltAlias, value: saltBase64);
    await _secureStorage.write(key: kPinHashAlias, value: hashBase64);

    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Removes the stored PIN configuration.
  Future<void> removePin() async {
    await _secureStorage.delete(key: kPinSaltAlias);
    await _secureStorage.delete(key: kPinHashAlias);
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Verifies an entered PIN against the stored hash. Returns true on success.
  Future<bool> verifyPin(String enteredPin) async {
    if (isLockedOut) {
      return false;
    }

    try {
      final saltBase64 = await _secureStorage.read(key: kPinSaltAlias);
      final storedHashBase64 = await _secureStorage.read(key: kPinHashAlias);

      if (saltBase64 == null || storedHashBase64 == null) {
        return false;
      }

      final saltBytes = base64Decode(saltBase64);
      final storedHashBytes = base64Decode(storedHashBase64);

      final enteredHashBytes = _pbkdf2Sha256(enteredPin.trim(), saltBytes, kPbkdf2Iterations);

      if (_constantTimeCompare(storedHashBytes, enteredHashBytes)) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        return true;
      } else {
        _failedAttempts++;
        if (_failedAttempts >= kMaxFailedAttempts) {
          _lockoutUntil = DateTime.now().add(kLockoutDuration);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Simple PBKDF2-HMAC-SHA256 implementation in Dart.
  Uint8List _pbkdf2Sha256(String password, Uint8List salt, int iterations) {
    final passBytes = Uint8List.fromList(utf8.encode(password));
    final hmac = Hmac(sha256, passBytes);

    // Block 1 (derived key length 32 bytes for SHA-256)
    final block1Input = Uint8List(salt.length + 4);
    block1Input.setAll(0, salt);
    block1Input[salt.length + 3] = 1; // Block index = 1 in big-endian

    Uint8List u = Uint8List.fromList(hmac.convert(block1Input).bytes);
    Uint8List result = Uint8List.fromList(u);

    for (int i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
