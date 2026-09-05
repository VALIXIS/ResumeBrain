import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/security/resume_encryption_service.dart';
import '../models/resume_schema_migrator.dart';

/// Handles automatic, deterministic, idempotent Hive database schema and encryption migrations.
class ResumeDatabaseMigrator {
  ResumeDatabaseMigrator._();

  /// Current database schema version.
  static const int kCurrentDatabaseVersion = 1;

  /// Internal key stored in Hive box to track the database schema version.
  static const String kDbVersionKey = '__schema_version__';

  /// Runs database schema and local encryption migrations on the given [box].
  ///
  /// Executed sequentially before normal reads/writes occur, preserving all existing user records.
  static Future<void> runMigrations(
    Box box, {
    ResumeEncryptionService? encryptionService,
  }) async {
    final encService = encryptionService ?? ResumeEncryptionService();

    final rawVer = box.get(kDbVersionKey);
    int storedVersion = 0;
    if (rawVer is int) {
      storedVersion = rawVer;
    } else if (rawVer is num) {
      storedVersion = rawVer.toInt();
    } else if (rawVer is String) {
      storedVersion = int.tryParse(rawVer) ?? 0;
    }

    if (storedVersion < kCurrentDatabaseVersion) {
      debugPrint('Running database schema migration from version $storedVersion to $kCurrentDatabaseVersion...');
      while (storedVersion < kCurrentDatabaseVersion) {
        switch (storedVersion) {
          case 0:
            await _migrateDatabaseV0ToV1(box);
            storedVersion = 1;
            break;
          default:
            storedVersion = kCurrentDatabaseVersion;
            break;
        }
      }
      await box.put(kDbVersionKey, kCurrentDatabaseVersion);
      debugPrint('Database schema migration completed successfully.');
    }

    // Always run idempotent encryption migration for any legacy unencrypted records
    await _migrateUnencryptedToEncrypted(box, encService);
  }

  static Future<void> _migrateDatabaseV0ToV1(Box box) async {
    final keysToMigrate = box.keys.where((k) => k != kDbVersionKey && !k.toString().startsWith('__')).toList();

    for (final key in keysToMigrate) {
      try {
        final data = box.get(key);
        if (data != null && data is Map) {
          final rawMap = Map<String, dynamic>.from(data);
          final migratedMap = ResumeSchemaMigrator.migrateJsonMap(rawMap);
          await box.put(key, migratedMap);
        }
      } catch (e) {
        debugPrint('Warning: Database migration skipping corrupted key $key: $e');
      }
    }
  }

  /// Encrypts any existing legacy plaintext resume records in Hive without deleting unmigrated data.
  static Future<void> _migrateUnencryptedToEncrypted(
    Box box,
    ResumeEncryptionService encryptionService,
  ) async {
    final keys = box.keys.where((k) => k != kDbVersionKey && !k.toString().startsWith('__')).toList();

    for (final key in keys) {
      try {
        final data = box.get(key);
        if (data != null && data is Map) {
          final map = Map<String, dynamic>.from(data);
          // Check if payload is already an encrypted envelope
          if (map.containsKey('ciphertext') && map.containsKey('nonce')) {
            continue; // Already encrypted
          }

          // Plaintext resume record found -> migrate to encrypted envelope
          debugPrint('Migrating plaintext resume key $key to AES-256 encrypted persistence...');
          final jsonString = jsonEncode(map);
          final envelope = await encryptionService.encryptString(jsonString);

          // Put encrypted payload only after successful encryption
          await box.put(key, envelope);
          debugPrint('Successfully encrypted resume record key $key.');
        }
      } catch (e) {
        debugPrint('Warning: Encryption migration failed for key $key. Data preserved: $e');
      }
    }
  }
}
