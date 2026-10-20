import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfService pdfService;
  late Resume testResume;

  setUp(() {
    pdfService = PdfService();
    testResume = Resume(
      id: 'metadata-test-101',
      title: 'Full Stack Engineer Resume',
      templateId: 'modern_classic',
      personalInfo: PersonalInformation(
        fullName: 'Jordan Lee',
        jobTitle: 'Senior Software Engineer',
        email: 'jordan.lee@example.com',
        phone: '+1 555-0100',
        location: 'Seattle, WA',
        website: 'jordanlee.dev',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Experienced developer building scalable cloud software.',
      ),
      experiences: [
        Experience(
          company: 'Tech Horizons',
          position: 'Lead Engineer',
          startDate: '2021',
          endDate: 'Present',
          description: 'Engineered high-scale web and mobile platforms.',
        ),
      ],
      skills: [
        Skill(name: 'Dart & Flutter'),
        Skill(name: 'Cloud Architecture'),
      ],
    );
  });

  group('PdfService UrlLink & Document Metadata Tests', () {
    test('1. buildMailtoLink creates pw.UrlLink with mailto: destination', () {
      final linkWidget = PdfService.buildMailtoLink(
        email: 'jordan.lee@example.com',
      );

      expect(linkWidget, isA<pw.UrlLink>());
      final urlLink = linkWidget as pw.UrlLink;
      // In package:pdf, UrlLink extends Annotation which sets builder to AnnotationUrl
      expect(urlLink.child, isNotNull);

      // Verify already-prefixed mailto string
      final prefixed = PdfService.buildMailtoLink(
        email: 'mailto:jordan.lee@example.com',
      );
      expect(prefixed, isA<pw.UrlLink>());
    });

    test('2. buildProfileLink creates pw.UrlLink with normalized web destination', () {
      final linkWithoutScheme = PdfService.buildProfileLink(
        url: 'linkedin.com/in/jordanlee',
      );
      expect(linkWithoutScheme, isA<pw.UrlLink>());

      final linkWithScheme = PdfService.buildProfileLink(
        url: 'https://github.com/jordanlee',
      );
      expect(linkWithScheme, isA<pw.UrlLink>());
    });

    test('3. sanitizeUrl normalizes profile links and preserves existing schemes', () {
      expect(PdfService.sanitizeUrl('jordanlee.dev'), equals('https://jordanlee.dev'));
      expect(PdfService.sanitizeUrl('https://jordanlee.dev'), equals('https://jordanlee.dev'));
      expect(PdfService.sanitizeUrl('http://insecure.site'), equals('http://insecure.site'));
      expect(PdfService.sanitizeUrl('mailto:test@example.com'), equals('mailto:test@example.com'));
      expect(PdfService.sanitizeUrl('   '), equals(''));
    });

    test('4. Widget extensions withProfileLink and withMailtoLink wrap children in pw.UrlLink', () {
      final textWidget = pw.Text('My Profile');
      final profileLink = textWidget.withProfileLink('github.com/jordanlee');
      expect(profileLink, isA<pw.UrlLink>());

      final mailtoWidget = pw.Text('Contact Me').withMailtoLink('jordan@example.com');
      expect(mailtoWidget, isA<pw.UrlLink>());
    });

    test('5. buildPdfDocument and populateDocumentMetadata correctly inject title, author, subject, and creator', () async {
      final pdfDoc = await pdfService.buildPdfDocument(testResume);

      // Verify PdfInfo exists in the Document objects
      final infoObjects = pdfDoc.document.objects.whereType<PdfInfo>().toList();
      expect(infoObjects, isNotEmpty);

      final pdfInfo = infoObjects.first;
      expect(pdfInfo.title, equals('Jordan Lee'));
      expect(pdfInfo.author, equals('Jordan Lee'));
      expect(pdfInfo.subject, equals('resume'));
      expect(pdfInfo.creator, equals('ResumeBrain'));
    });

    test('6. buildPdfBytes generates PDF containing serialized metadata entries', () async {
      final bytes = await pdfService.buildPdfBytes(testResume);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));

      final pdfAscii = String.fromCharCodes(bytes);
      expect(pdfAscii, contains('/Creator(ResumeBrain)'));
      expect(pdfAscii, contains('/Subject(resume)'));
      expect(pdfAscii, contains('/Title(Jordan Lee)'));
      expect(pdfAscii, contains('/Author(Jordan Lee)'));
    });

    test('7. Empty candidate name falls back gracefully to Resume', () async {
      final anonymousResume = Resume(
        id: 'anon-101',
        title: 'Draft',
        personalInfo: PersonalInformation(fullName: '  '),
      );

      final doc = await pdfService.buildPdfDocument(anonymousResume);
      final pdfInfo = doc.document.objects.whereType<PdfInfo>().first;

      expect(pdfInfo.title, equals('Resume'));
      expect(pdfInfo.author, equals('Resume'));
      expect(pdfInfo.subject, equals('resume'));
      expect(pdfInfo.creator, equals('ResumeBrain'));
    });
  });
}
