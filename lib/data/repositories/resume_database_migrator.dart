import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/resume_schema_migrator.dart';

/// Handles automatic, deterministic, and idempotent Hive database schema migrations.
class ResumeDatabaseMigrator {
  ResumeDatabaseMigrator._();

  /// Current database schema version.
  static const int kCurrentDatabaseVersion = 1;

  /// Internal key stored in Hive box to track the database schema version.
  static const String kDbVersionKey = '__schema_version__';

  /// Runs database migrations on the given [box] if stored version is older than [kCurrentDatabaseVersion].
  ///
  /// Executed sequentially before normal reads/writes occur, preserving all existing user records.
  static Future<void> runMigrations(Box box) async {
    final rawVer = box.get(kDbVersionKey);
    int storedVersion = 0;
    if (rawVer is int) {
      storedVersion = rawVer;
    } else if (rawVer is num) {
      storedVersion = rawVer.toInt();
    } else if (rawVer is String) {
      storedVersion = int.tryParse(rawVer) ?? 0;
    }

    if (storedVersion >= kCurrentDatabaseVersion) {
      return;
    }

    debugPrint('Running database migration from version $storedVersion to $kCurrentDatabaseVersion...');

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
    debugPrint('Database migration completed successfully. Current version: $kCurrentDatabaseVersion');
  }

  static Future<void> _migrateDatabaseV0ToV1(Box box) async {
    final keysToMigrate = box.keys.where((k) => k != kDbVersionKey).toList();

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
}
