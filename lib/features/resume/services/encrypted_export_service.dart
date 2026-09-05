import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../core/security/resume_encryption_service.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_import_sanitizer.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../../pdf/services/pdf_service.dart';

/// Exception thrown when encrypted import/export operations fail validation or decryption.
class EncryptedExportException implements Exception {
  final String message;
  const EncryptedExportException(this.message);

  @override
  String toString() => 'EncryptedExportException: $message';
}

/// Service handling production-grade authenticated AES-256 JSON & PDF encrypted import/export.
class EncryptedExportService {
  final ResumeEncryptionService _encryptionService;
  final PdfService _pdfService;

  EncryptedExportService({
    ResumeEncryptionService? encryptionService,
    PdfService? pdfService,
  })  : _encryptionService = encryptionService ?? ResumeEncryptionService(),
        _pdfService = pdfService ?? PdfService();

  // ---------------------------------------------------------------------------
  // ENCRYPTED JSON EXPORT & IMPORT (.resume.json.enc)
  // ---------------------------------------------------------------------------

  /// Encrypts a resume payload into an authenticated AES-256 protected JSON envelope string.
  Future<String> exportEncryptedJsonString(Resume resume) async {
    final rawMap = resume.toMap();
    final jsonStr = jsonEncode(rawMap);
    final envelope = await _encryptionService.encryptString(jsonStr);
    return jsonEncode(envelope);
  }

  /// Saves an encrypted resume payload to disk as a `.resume.json.enc` file.
  Future<File> exportEncryptedJsonFile(Resume resume) async {
    final envelopeJsonStr = await exportEncryptedJsonString(resume);
    final outputDir = await getApplicationDocumentsDirectory();
    final safeId = resume.id.length >= 6 ? resume.id.substring(0, 6) : resume.id;
    final safeTitle = resume.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final fileName = '${safeTitle}_$safeId.resume.json.enc';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsString(envelopeJsonStr);
    return file;
  }

  /// Decrypts, validates, migrates, and sanitizes a `.resume.json.enc` file content.
  Future<Resume> importEncryptedJsonString(String encryptedFileContent) async {
    if (encryptedFileContent.trim().isEmpty) {
      throw const EncryptedExportException('Encrypted JSON content cannot be empty.');
    }

    Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(encryptedFileContent);
      if (decoded is! Map) {
        throw const EncryptedExportException('Encrypted JSON envelope must be a JSON object.');
      }
      envelope = Map<String, dynamic>.from(decoded);
    } catch (e) {
      throw EncryptedExportException('Invalid envelope JSON format: $e');
    }

    // Step 1: Decrypt envelope
    String decryptedJsonStr;
    try {
      decryptedJsonStr = await _encryptionService.decryptStringEnvelope(envelope);
    } catch (e) {
      throw EncryptedExportException('Failed to decrypt protected JSON payload: $e');
    }

    // Step 2: Parse decrypted JSON
    dynamic rawJson;
    try {
      rawJson = jsonDecode(decryptedJsonStr);
    } catch (e) {
      throw EncryptedExportException('Decrypted payload is not valid JSON: $e');
    }

    // Step 3 & 4: Re-use ResumeSchemaMigrator and ResumeImportSanitizer
    final sanitizedMap = ResumeImportSanitizer.sanitizeResumeJson(rawJson);

    // Step 5: Instantiate Resume model
    return Resume.fromMap(sanitizedMap);
  }

  // ---------------------------------------------------------------------------
  // ENCRYPTED PDF EXPORT & IMPORT (.resume.pdf.enc)
  // ---------------------------------------------------------------------------

  /// Generates vector PDF bytes and encrypts them into a `.resume.pdf.enc` protected envelope string.
  Future<String> exportProtectedPdfString(
    Resume resume, {
    PdfExportConfig? config,
  }) async {
    final pdfBytes = await _pdfService.buildPdfBytes(resume, config: config);
    final envelope = await _encryptionService.encryptBytes(pdfBytes);
    return jsonEncode(envelope);
  }

  /// Saves an encrypted protected PDF to disk as a `.resume.pdf.enc` file.
  Future<File> exportProtectedPdfFile(
    Resume resume, {
    PdfExportConfig? config,
  }) async {
    final protectedPdfContent = await exportProtectedPdfString(resume, config: config);
    final outputDir = await getApplicationDocumentsDirectory();
    final safeId = resume.id.length >= 6 ? resume.id.substring(0, 6) : resume.id;
    final safeTitle = resume.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final fileName = '${safeTitle}_$safeId.resume.pdf.enc';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsString(protectedPdfContent);
    return file;
  }

  /// Decrypts a protected PDF envelope, validates magic bytes `%PDF-`, and returns raw PDF Uint8List.
  Future<Uint8List> importProtectedPdfBytes(String protectedPdfContent) async {
    if (protectedPdfContent.trim().isEmpty) {
      throw const EncryptedExportException('Protected PDF content cannot be empty.');
    }

    Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(protectedPdfContent);
      if (decoded is! Map) {
        throw const EncryptedExportException('Protected PDF envelope must be a JSON object.');
      }
      envelope = Map<String, dynamic>.from(decoded);
    } catch (e) {
      throw EncryptedExportException('Invalid protected PDF envelope JSON format: $e');
    }

    Uint8List pdfBytes;
    try {
      pdfBytes = await _encryptionService.decryptBytesEnvelope(envelope);
    } catch (e) {
      throw EncryptedExportException('Failed to decrypt protected PDF payload: $e');
    }

    // Verify PDF Magic Bytes (%PDF- / 0x25 0x50 0x44 0x46 0x2D)
    if (pdfBytes.length < 5 ||
        pdfBytes[0] != 0x25 ||
        pdfBytes[1] != 0x50 ||
        pdfBytes[2] != 0x44 ||
        pdfBytes[3] != 0x46 ||
        pdfBytes[4] != 0x2D) {
      throw const EncryptedExportException('Decrypted payload is not a valid vector PDF document.');
    }

    return pdfBytes;
  }
}
