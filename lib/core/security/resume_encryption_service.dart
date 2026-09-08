import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown when cryptographic operations, key retrieval, or envelope validation fails.
class ResumeEncryptionException implements Exception {
  final String message;
  const ResumeEncryptionException(this.message);

  @override
  String toString() => 'ResumeEncryptionException: $message';
}

/// Core service providing authenticated AES-256 encryption and secure master key storage.
class ResumeEncryptionService {
  static const String kKeyAlias = 'resume_brain_master_key_v1';
  static const String kAlgorithm = 'AES-256-CBC-HMAC-SHA256';
  static const int kFormatVersion = 1;
  static const int kKeyVersion = 1;

  final FlutterSecureStorage _secureStorage;
  encrypt_pkg.Key? _cachedKey;

  ResumeEncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Retrieves or generates the 256-bit AES master key backed by platform secure storage.
  Future<encrypt_pkg.Key> getMasterKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      final storedKeyBase64 = await _secureStorage.read(key: kKeyAlias);
      if (storedKeyBase64 != null && storedKeyBase64.isNotEmpty) {
        final keyBytes = base64Decode(storedKeyBase64);
        if (keyBytes.length == 32) {
          _cachedKey = encrypt_pkg.Key(keyBytes);
          return _cachedKey!;
        }
      }
    } catch (e) {
      debugPrint('Error reading master key from secure storage: $e');
    }

    // Generate cryptographically secure 256-bit (32-byte) key
    final newKey = encrypt_pkg.Key.fromSecureRandom(32);
    final base64Key = base64Encode(newKey.bytes);

    try {
      await _secureStorage.write(key: kKeyAlias, value: base64Key);
    } catch (e) {
      debugPrint('Error writing master key to secure storage: $e');
    }

    _cachedKey = newKey;
    return newKey;
  }

  /// Sets an explicit key (used for testing or key rotation).
  void setKeyForTesting(encrypt_pkg.Key key) {
    _cachedKey = key;
  }

  /// Encrypts UTF-8 plaintext string using authenticated AES-256 into a structured envelope map.
  Future<Map<String, dynamic>> encryptString(String plaintext) async {
    final bytes = Uint8List.fromList(utf8.encode(plaintext));
    return encryptBytes(bytes);
  }

  /// Encrypts raw binary bytes using authenticated AES-256 into a structured envelope map.
  Future<Map<String, dynamic>> encryptBytes(Uint8List bytes) async {
    final key = await getMasterKey();
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
    );

    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final mac = _computeHmac(key: key.bytes, iv: iv.bytes, ciphertext: encrypted.bytes);

    return {
      'formatVersion': kFormatVersion,
      'algorithm': kAlgorithm,
      'keyVersion': kKeyVersion,
      'nonce': base64Encode(iv.bytes),
      'ciphertext': encrypted.base64,
      'mac': base64Encode(mac),
    };
  }

  /// Decrypts an authenticated encryption envelope map into a UTF-8 plaintext string.
  Future<String> decryptStringEnvelope(Map<String, dynamic> envelope) async {
    final decryptedBytes = await decryptBytesEnvelope(envelope);
    return utf8.decode(decryptedBytes);
  }

  /// Decrypts an authenticated encryption envelope map into raw binary bytes.
  Future<Uint8List> decryptBytesEnvelope(Map<String, dynamic> envelope) async {
    if (envelope.isEmpty) {
      throw const ResumeEncryptionException('Envelope map cannot be empty.');
    }

    final formatVersion = envelope['formatVersion'];
    if (formatVersion != kFormatVersion) {
      throw ResumeEncryptionException(
        'Unsupported encryption envelope format version: $formatVersion',
      );
    }

    final algorithm = envelope['algorithm'];
    if (algorithm != kAlgorithm) {
      throw ResumeEncryptionException('Unsupported encryption algorithm: $algorithm');
    }

    final nonceStr = envelope['nonce'] as String?;
    final ciphertextStr = envelope['ciphertext'] as String?;
    final macStr = envelope['mac'] as String?;

    if (nonceStr == null || ciphertextStr == null || macStr == null) {
      throw const ResumeEncryptionException('Encryption envelope missing required fields.');
    }

    final ivBytes = base64Decode(nonceStr);
    final ciphertextBytes = base64Decode(ciphertextStr);
    final macBytes = base64Decode(macStr);

    final key = await getMasterKey();

    // Authenticate ciphertext before decryption (Encrypt-then-MAC)
    final expectedMac = _computeHmac(key: key.bytes, iv: ivBytes, ciphertext: ciphertextBytes);
    if (!_constantTimeCompare(macBytes, expectedMac)) {
      throw const ResumeEncryptionException(
        'Authentication tag mismatch. Data may be corrupted or tampered.',
      );
    }

    try {
      final iv = encrypt_pkg.IV(ivBytes);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
      );
      final encrypted = encrypt_pkg.Encrypted(ciphertextBytes);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw ResumeEncryptionException('Decryption failed with current master key: $e');
    }
  }

  /// Computes HMAC-SHA256 over IV + Ciphertext using key.
  Uint8List _computeHmac({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List ciphertext,
  }) {
    final hmac = Hmac(sha256, key);
    final bytesToAuth = Uint8List(iv.length + ciphertext.length);
    bytesToAuth.setAll(0, iv);
    bytesToAuth.setAll(iv.length, ciphertext);
    final digest = hmac.convert(bytesToAuth);
    return Uint8List.fromList(digest.bytes);
  }

  /// Constant-time byte comparison to mitigate timing attacks.
  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
