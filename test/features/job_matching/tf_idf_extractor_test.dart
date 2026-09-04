import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/job_matching/services/tf_idf_extractor_service.dart';

void main() {
  late TfIdfExtractorService service;

  setUp(() {
    service = TfIdfExtractorService();
  });

  group('TfIdfExtractorService Unit Tests', () {
    test('Tokenization strips stop words and generic job noise', () {
      const text = 'We are looking for a Senior Flutter Developer with strong experience in building apps.';
      final tokens = service.tokenize(text);

      expect(tokens, contains('flutter'));
      expect(tokens, contains('developer'));
      expect(tokens, contains('apps'));
      expect(tokens, isNot(contains('we')));
      expect(tokens, isNot(contains('looking')));
      expect(tokens, isNot(contains('experience')));
    });

    test('TF-IDF scoring produces deterministic ranking', () {
      const text = 'Flutter developer building Flutter applications with Dart and Riverpod. Flutter experience required.';
      final scores = service.extractTfIdfScores(text);

      expect(scores, isNotEmpty);
      expect(scores.containsKey('flutter'), isTrue);
      expect(scores.containsKey('riverpod'), isTrue);

      // 'flutter' occurs multiple times, so it should rank high
      final keys = scores.keys.toList();
      expect(keys.first, equals('flutter'));
    });

    test('Empty text returns empty map', () {
      final scores = service.extractTfIdfScores('');
      expect(scores, isEmpty);
    });

    test('Identical text input returns identical deterministic scores', () {
      const text = 'Python Django REST framework PostgreSQL microservices';
      final scores1 = service.extractTfIdfScores(text);
      final scores2 = service.extractTfIdfScores(text);

      expect(scores1, equals(scores2));
    });
  });
}
