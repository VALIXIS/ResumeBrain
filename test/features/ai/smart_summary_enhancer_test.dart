import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/ai/services/smart_summary_enhancer.dart';

void main() {
  group('SmartSummaryEnhancer Unit Tests', () {
    test('handles empty input gracefully with provided target role', () {
      final res = SmartSummaryEnhancer.enhance('', targetRole: 'Cloud Architect');
      expect(res.text, contains('Cloud Architect'));
      expect(res.suggestions, isNotEmpty);
      expect(res.powerVerbs, contains('Spearheaded'));
    });

    test('enhances user screenshot text with AI and management keywords', () {
      const userRawText =
          'management, and AI-based solutions with active involvement in student council. Good communication and teamwork skills.';
      final res = SmartSummaryEnhancer.enhance(userRawText);

      // Part 1: Domain
      expect(res.text, contains('AI-based solutions'));
      expect(res.text, contains('technical project management'));

      // Part 2: Leadership & soft skills
      expect(res.text, contains('student council'));
      expect(res.text, contains('cross-functional collaboration'));

      // Part 3: Value proposition
      expect(res.text, isNotEmpty);
      expect(res.suggestions.length, greaterThanOrEqualTo(2));
      expect(res.powerVerbs.length, greaterThanOrEqualTo(3));
    });

    test('enhances mobile engineering profile accurately', () {
      const mobileRaw = 'Flutter developer building Android and iOS cross platform apps.';
      final res = SmartSummaryEnhancer.enhance(mobileRaw);
      expect(res.text, contains('Mobile Application Engineer'));
      expect(res.text, contains('cross-platform architecture'));
    });

    test('enhances web development profile accurately', () {
      const webRaw = 'Frontend and backend full stack node and react developer.';
      final res = SmartSummaryEnhancer.enhance(webRaw);
      expect(res.text, contains('Full-Stack Developer'));
      expect(res.text, contains('modern web frameworks'));
    });
  });
}
