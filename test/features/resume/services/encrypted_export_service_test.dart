import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/security/resume_encryption_service.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';
import 'package:resume_brain/features/resume/services/encrypted_export_service.dart';

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
  group('EncryptedExportService Tests', () {
    late ResumeEncryptionService encryptionService;
    late PdfService pdfService;
    late EncryptedExportService exportService;

    setUp(() {
      final mockStorage = MockSecureStorage();
      encryptionService = ResumeEncryptionService(secureStorage: mockStorage);
      pdfService = PdfService();
      exportService = EncryptedExportService(
        encryptionService: encryptionService,
        pdfService: pdfService,
      );
    });

    final testResume = Resume(
      id: 'test-uuid-1234',
      title: 'Senior Software Engineer Resume',
      templateId: 'modern_classic',
      personalInfo: PersonalInformation(
        fullName: 'Vaseem Engineer',
        email: 'vaseem@valixis.com',
        phone: '+1 555-0199',
        jobTitle: 'Principal Lead Architect',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Extensive experience in Flutter security, cryptography, and cloud systems.',
      ),
      skills: [
        Skill(name: 'Flutter & Dart', level: 'Expert'),
        Skill(name: 'AES Encryption', level: 'Expert'),
      ],
    );

    test('.resume.json.enc export contains no readable resume text and imports cleanly', () async {
      final envelopeJsonStr = await exportService.exportEncryptedJsonString(testResume);

      expect(envelopeJsonStr, isNot(contains('Vaseem Engineer')));
      expect(envelopeJsonStr, isNot(contains('vaseem@valixis.com')));
      expect(envelopeJsonStr, isNot(contains('Principal Lead Architect')));
      expect(envelopeJsonStr, contains('ciphertext'));
      expect(envelopeJsonStr, contains('nonce'));

      final importedResume = await exportService.importEncryptedJsonString(envelopeJsonStr);

      expect(importedResume.id, equals(testResume.id));
      expect(importedResume.title, equals(testResume.title));
      expect(importedResume.personalInfo.fullName, equals('Vaseem Engineer'));
      expect(importedResume.personalInfo.email, equals('vaseem@valixis.com'));
      expect(importedResume.skills.length, equals(2));
    });

    test('.resume.pdf.enc export encrypts PDF bytes and decrypts into valid vector PDF', () async {
      final protectedPdfContent = await exportService.exportProtectedPdfString(testResume);

      expect(protectedPdfContent, isNot(contains('%PDF-'))); // Encrypted, not readable PDF
      expect(protectedPdfContent, contains('ciphertext'));

      final pdfBytes = await exportService.importProtectedPdfBytes(protectedPdfContent);

      expect(pdfBytes.length, greaterThan(100));
      // Verify PDF Magic Bytes (%PDF- / 0x25 0x50 0x44 0x46 0x2D)
      expect(pdfBytes[0], equals(0x25));
      expect(pdfBytes[1], equals(0x50));
      expect(pdfBytes[2], equals(0x44));
      expect(pdfBytes[3], equals(0x46));
      expect(pdfBytes[4], equals(0x2D));
    });

    test('Protected PDF export compiles across all five templates', () async {
      const templates = [
        'modern_classic',
        'executive_minimal',
        'creative_professional',
        'tech_specialist',
        'academic_cv',
      ];

      for (final templateId in templates) {
        final resume = testResume.copyWith(templateId: templateId);
        final protectedPdfContent = await exportService.exportProtectedPdfString(resume);
        final pdfBytes = await exportService.importProtectedPdfBytes(protectedPdfContent);

        expect(pdfBytes.length, greaterThan(100), reason: 'Failed for template $templateId');
        expect(pdfBytes[0], equals(0x25), reason: 'Magic byte 0 failed for template $templateId');
      }
    });

    test('Corrupted encrypted envelope JSON is rejected on import', () async {
      const invalidJson = '{"ciphertext": "invalid_base64_data", "formatVersion": 1, "algorithm": "AES-256-CBC-HMAC-SHA256", "nonce": "abc", "mac": "def"}';

      expect(
        () async => await exportService.importEncryptedJsonString(invalidJson),
        throwsA(isA<EncryptedExportException>()),
      );
    });
  });
}
