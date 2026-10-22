import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:resume_brain/core/theme/app_colors.dart';
import 'package:resume_brain/core/theme/app_theme.dart';
import 'package:resume_brain/core/theme/theme_provider.dart';
import 'package:resume_brain/features/pdf/utils/pdf_text_sanitizer.dart';
import 'package:resume_brain/features/resume/utils/resume_input_scrubber.dart';
import 'package:resume_brain/data/models/resume_models.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('Resume Brain Bug Fix Verification Tests', () {
    test('1. ResumeInputScrubber allows spaces in names and locations', () {
      final nameFormatter = ResumeInputScrubber.nameFormatter();
      const input = 'Subash Annam';
      final formatted = nameFormatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: input,
          selection: TextSelection.collapsed(offset: input.length),
        ),
      );
      expect(formatted.text, equals('Subash Annam'));

      final locationFormatter = ResumeInputScrubber.titleFormatter();
      const locInput = 'Guntur, India';
      final locFormatted = locationFormatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: locInput,
          selection: TextSelection.collapsed(offset: locInput.length),
        ),
      );
      expect(locFormatted.text, equals('Guntur, India'));
    });

    test('2. PdfTextSanitizer removes emojis, normalizes quotes and strips bullets', () {
      const rawText = '• Leading bullet points with emoji 🚀 and smart quotes “hello”';
      final cleanLine = PdfTextSanitizer.cleanBulletLine(rawText);
      expect(cleanLine.contains('🚀'), isFalse);
      expect(cleanLine.contains('“'), isFalse);
      expect(cleanLine.contains('"hello"'), isTrue);
      expect(cleanLine.startsWith('•'), isFalse);

      final bulletLines = PdfTextSanitizer.extractBulletLines(
        '• Experienced developer\n• Led 5 engineers',
      );
      expect(bulletLines, equals(['Experienced developer', 'Led 5 engineers']));

      final resume = Resume(
        title: 'Tech Resume 🔥',
        personalInfo: PersonalInformation(
          fullName: 'Subash Annam 💻',
          location: 'Guntur, India',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Lead software engineer with 5+ years experience.',
        ),
      );
      final sanitizedResume = PdfTextSanitizer.sanitizeResume(resume);
      expect(sanitizedResume.title, equals('Tech Resume'));
      expect(sanitizedResume.personalInfo.fullName, equals('Subash Annam'));
    });

    testWidgets('3. AppTheme provides distinct, consistent light and dark palettes', (tester) async {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));

      expect(lightTheme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppColors.darkBackground));

      expect(lightTheme.colorScheme.surface, equals(AppColors.lightSurface));
      expect(darkTheme.colorScheme.surface, equals(AppColors.darkSurface));
    });

    test('4. ThemeModeNotifier updates AppColors.isDarkMode cleanly', () {
      final notifier = ThemeModeNotifier();
      notifier.setThemeMode(ThemeMode.dark);
      expect(AppColors.isDarkMode, isTrue);

      notifier.setThemeMode(ThemeMode.light);
      expect(AppColors.isDarkMode, isFalse);
    });
  });
}
