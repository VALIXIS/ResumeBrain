import 'dart:math' as math;
import 'package:flutter/services.dart';

/// ResumeInputScrubber provides field-specific input sanitization rules and
/// safe [TextInputFormatter] implementations that eliminate unsafe/invalid characters
/// while preserving legitimate punctuation, international unicode characters,
/// and cursor stability.
class ResumeInputScrubber {
  ResumeInputScrubber._();

  // ---------------------------------------------------------------------------
  // Regex Character Class Patterns
  // ---------------------------------------------------------------------------

  /// Disallowed control characters and invisible zero-width unicode characters.
  static final RegExp _controlAndZeroWidthRegex = RegExp(
    r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F\u200B-\u200D\uFEFF]',
  );

  /// Allowed characters for personal full names (letters, accented unicode, spaces, hyphens, apostrophes, periods, commas).
  static final RegExp _nameDisallowedRegex = RegExp(
    r'[^\p{L}\p{M}\s\-\x27\x22.,]',
    unicode: true,
  );

  /// Allowed characters for titles, institutions, companies, and degrees.
  static final RegExp _titleDisallowedRegex = RegExp(
    r'[^\p{L}\p{M}\p{N}\s\-\x27\x22.,&/()#+_:;]',
    unicode: true,
  );

  /// Allowed characters for phone numbers (digits, spaces, +, -, (, ), ., ext, x).
  static final RegExp _phoneDisallowedRegex = RegExp(
    r'[^0-9+\-().\s/extEXTxX]',
  );

  /// Characters forbidden in email addresses.
  static final RegExp _emailDisallowedRegex = RegExp(
    r'[^a-zA-Z0-9._%+\-@]',
  );

  /// Disallowed characters for URLs (whitespace, newlines, control characters, quotes, angle brackets).
  static final RegExp _urlDisallowedRegex = RegExp(
    r'[\s\x00-\x1F\x7F\x22\x3C\x3E\x60]',
  );

  /// Allowed characters for dates (digits, letters for month names / "Present", spaces, /, -, ., parentheses).
  static final RegExp _dateDisallowedRegex = RegExp(
    r'[^\p{L}\p{M}0-9\s/\-.,()]',
    unicode: true,
  );

  /// Allowed characters for GPA and honors (digits, letters for honors / Magna Cum Laude, ., /, %, +, -, (), spaces).
  static final RegExp _gpaDisallowedRegex = RegExp(
    r'[^\p{L}\p{M}0-9./%\s+()\-]',
    unicode: true,
  );

  // ---------------------------------------------------------------------------
  // Sanitization Methods (Pure Functions)
  // ---------------------------------------------------------------------------

  /// Strips ASCII control codes and zero-width characters while preserving valid whitespace.
  static String scrubControlCharacters(String input) => scrubTextBlock(input);

  /// Cleans name strings by removing invalid symbols and control characters.
  static String scrubName(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_nameDisallowedRegex, '');
  }

  /// Cleans title, company, degree, and section title strings.
  static String scrubTitle(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_titleDisallowedRegex, '');
  }

  /// Cleans email addresses by stripping whitespace and invalid characters.
  static String scrubEmail(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_emailDisallowedRegex, '')
        .trim();
  }

  /// Cleans phone numbers.
  static String scrubPhone(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_phoneDisallowedRegex, '');
  }

  /// Cleans URLs by removing whitespace and forbidden characters.
  static String scrubUrl(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_urlDisallowedRegex, '')
        .trim();
  }

  /// Cleans date and year inputs.
  static String scrubDate(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_dateDisallowedRegex, '');
  }

  /// Cleans GPA strings.
  static String scrubGpa(String input) {
    return input
        .replaceAll(_controlAndZeroWidthRegex, '')
        .replaceAll(_gpaDisallowedRegex, '');
  }

  /// Cleans general text blocks, descriptions, summaries, and bullet points.
  /// Preserves all normal punctuation, currency symbols, and bullet marks while
  /// stripping zero-width and invisible control characters.
  static String scrubTextBlock(String input) {
    return input.replaceAll(_controlAndZeroWidthRegex, '');
  }

  // ---------------------------------------------------------------------------
  // TextInputFormatter Factories with Safe Cursor Preservation
  // ---------------------------------------------------------------------------

  /// Creates a formatter for name fields.
  static TextInputFormatter nameFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _nameDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for title, company, institution, degree, and header fields.
  static TextInputFormatter titleFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _titleDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for email fields.
  static TextInputFormatter emailFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _emailDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for phone number fields.
  static TextInputFormatter phoneFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _phoneDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for URL fields.
  static TextInputFormatter urlFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _urlDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for date fields.
  static TextInputFormatter dateFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _dateDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for GPA fields.
  static TextInputFormatter gpaFormatter() {
    return SafePatternFormatter(
      disallowedPattern: _gpaDisallowedRegex,
      stripControlChars: true,
    );
  }

  /// Creates a formatter for multi-line description, summary, and bullet fields.
  static TextInputFormatter textBlockFormatter() {
    return const SafeControlCharacterFormatter();
  }
}

/// A [TextInputFormatter] that scrubs disallowed patterns while safely computing
/// the updated cursor position without jumping to the end or breaking text selection.
class SafePatternFormatter extends TextInputFormatter {
  final RegExp disallowedPattern;
  final bool stripControlChars;

  const SafePatternFormatter({
    required this.disallowedPattern,
    this.stripControlChars = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleanedText = newValue.text;
    if (stripControlChars) {
      cleanedText = cleanedText.replaceAll(
        ResumeInputScrubber._controlAndZeroWidthRegex,
        '',
      );
    }
    cleanedText = cleanedText.replaceAll(disallowedPattern, '');

    if (cleanedText == newValue.text) {
      return newValue;
    }

    // Calculate cursor position by counting how many characters before the cursor were stripped
    final cursorIndex = newValue.selection.baseOffset;
    if (cursorIndex <= 0) {
      return TextEditingValue(
        text: cleanedText,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final textBeforeCursor = newValue.text.substring(0, math.min(cursorIndex, newValue.text.length));
    String cleanedBeforeCursor = textBeforeCursor;
    if (stripControlChars) {
      cleanedBeforeCursor = cleanedBeforeCursor.replaceAll(
        ResumeInputScrubber._controlAndZeroWidthRegex,
        '',
      );
    }
    cleanedBeforeCursor = cleanedBeforeCursor.replaceAll(disallowedPattern, '');

    final newCursorOffset = math.min(cleanedBeforeCursor.length, cleanedText.length);

    return TextEditingValue(
      text: cleanedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

/// A [TextInputFormatter] dedicated to scrubbing control characters and zero-width artifacts.
class SafeControlCharacterFormatter extends TextInputFormatter {
  const SafeControlCharacterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanedText = newValue.text.replaceAll(
      ResumeInputScrubber._controlAndZeroWidthRegex,
      '',
    );

    if (cleanedText == newValue.text) {
      return newValue;
    }

    final cursorIndex = newValue.selection.baseOffset;
    if (cursorIndex <= 0) {
      return TextEditingValue(
        text: cleanedText,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final textBeforeCursor = newValue.text.substring(0, math.min(cursorIndex, newValue.text.length));
    final cleanedBeforeCursor = textBeforeCursor.replaceAll(
      ResumeInputScrubber._controlAndZeroWidthRegex,
      '',
    );

    final newCursorOffset = math.min(cleanedBeforeCursor.length, cleanedText.length);

    return TextEditingValue(
      text: cleanedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}
