/// Reusable validation logic and helper functions for Resume fields.
/// Decouples validation business logic from UI widgets.
class ResumeValidators {
  ResumeValidators._();

  /// Regular expression for basic email format validation.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Regular expression for phone number formats (supports international prefixes, dashes, spaces, parentheses).
  static final RegExp phoneRegex = RegExp(
    r'^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]{6,15}$',
  );

  /// Regular expression for GPA numbers (e.g. 3.8, 4.0, 85%, 9.2/10).
  static final RegExp gpaRegex = RegExp(
    r'^([0-9](\.[0-9]{1,2})?(\s*\/\s*[0-9]+(\.[0-9]+)?)?|[0-9]{1,3}\s*%?)$',
  );

  /// Validates a required text field.
  static String? validateRequired(
    String? value,
    String fieldName, {
    int minLength = 2,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates an optional or required text field by length constraints.
  static String? validateOptionalLength(
    String? value,
    String fieldName, {
    int maxLength = 100,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates an email address.
  static String? validateEmail(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'Email address is required';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > 100) {
      return 'Email cannot exceed 100 characters';
    }
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address (e.g. name@domain.com)';
    }
    return null;
  }

  /// Validates a phone number.
  static String? validatePhone(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'Phone number is required';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > 30) {
      return 'Phone number cannot exceed 30 characters';
    }
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Enter a valid phone number (e.g. +1 555-123-4567)';
    }
    return null;
  }

  /// Validates a URL / website link.
  static String? validateUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'URL is required';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > 250) {
      return 'URL cannot exceed 250 characters';
    }
    final uri = Uri.tryParse(trimmed);
    final isHttpOrHttps = uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;

    if (!isHttpOrHttps) {
      return 'Enter a valid web link starting with http:// or https://';
    }
    return null;
  }

  /// Validates a flexible date or year input.
  static String? validateDate(
    String? value,
    String fieldName, {
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return '$fieldName is required';
      return null;
    }
    final parsed = parseDate(value);
    if (parsed == null && value.trim().toLowerCase() != 'present') {
      return 'Enter a valid year or date (e.g. 2023, 05/2023, May 2023)';
    }
    return null;
  }

  /// Validates that an end date does not precede a start date.
  static String? validateDateRange(
    String? startDate,
    String? endDate, {
    bool isCurrent = false,
  }) {
    if (isCurrent) return null;
    if (endDate == null || endDate.trim().isEmpty) return null;
    if (startDate == null || startDate.trim().isEmpty) return null;

    final start = parseDate(startDate);
    final end = parseDate(endDate);

    if (start != null && end != null && end.isBefore(start)) {
      return 'End date cannot be earlier than start date';
    }
    return null;
  }

  /// Validates optional GPA input.
  static String? validateGpa(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.length > 20) {
      return 'GPA format too long';
    }
    if (!gpaRegex.hasMatch(trimmed)) {
      return 'Enter a valid GPA (e.g. 3.8, 3.8/4.0, 90%)';
    }
    return null;
  }

  /// Parses flexible date strings into a `DateTime` instance for comparison.
  static DateTime? parseDate(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty ||
        trimmed == 'present' ||
        trimmed == 'current' ||
        trimmed == 'now' ||
        trimmed == 'ongoing') {
      return null;
    }

    // Format: YYYY (e.g. "2024")
    final yearOnlyRegex = RegExp(r'^(\d{4})$');
    final yearMatch = yearOnlyRegex.firstMatch(trimmed);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(1)!);
      if (year != null) return DateTime(year, 1, 1);
    }

    // Format: MM/YYYY, MM-YYYY, MM.YYYY
    final mmyyyyRegex = RegExp(r'^(\d{1,2})[\/\-\.](\d{4})$');
    final mmyyyyMatch = mmyyyyRegex.firstMatch(trimmed);
    if (mmyyyyMatch != null) {
      final month = int.tryParse(mmyyyyMatch.group(1)!);
      final year = int.tryParse(mmyyyyMatch.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return DateTime(year, month, 1);
      }
    }

    // Format: YYYY/MM, YYYY-MM
    final yyyymmRegex = RegExp(r'^(\d{4})[\/\-\.](\d{1,2})$');
    final yyyymmMatch = yyyymmRegex.firstMatch(trimmed);
    if (yyyymmMatch != null) {
      final year = int.tryParse(yyyymmMatch.group(1)!);
      final month = int.tryParse(yyyymmMatch.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return DateTime(year, month, 1);
      }
    }

    // Format: Month Name + Year (e.g. "Jan 2023", "September 2024")
    const months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9, 'sept': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };

    final monthNameRegex = RegExp(r'^([a-zA-Z]+)[\s,]+(\d{4})$');
    final monthNameMatch = monthNameRegex.firstMatch(trimmed);
    if (monthNameMatch != null) {
      final monthStr = monthNameMatch.group(1)!.toLowerCase();
      final year = int.tryParse(monthNameMatch.group(2)!);
      if (months.containsKey(monthStr) && year != null) {
        return DateTime(year, months[monthStr]!, 1);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  /// Validates a custom section title, with optional duplicate check against existing section titles.
  static String? validateSectionTitle(
    String? value, {
    List<String> existingTitles = const [],
    String? currentTitle,
    int minLength = 2,
    int maxLength = 80,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Section title is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Section title must be at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return 'Section title cannot exceed $maxLength characters';
    }
    final currentNormalized = currentTitle?.trim().toLowerCase();
    final isDuplicate = existingTitles.any((title) {
      final normalized = title.trim().toLowerCase();
      if (currentNormalized != null && normalized == currentNormalized) {
        return false;
      }
      return normalized == trimmed.toLowerCase();
    });
    if (isDuplicate) {
      return 'A section with this title already exists';
    }
    return null;
  }

  /// Validates a single bullet point item.
  static String? validateBulletPoint(
    String? value, {
    int maxLength = 500,
    bool isRequired = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'Bullet point cannot be empty';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > maxLength) {
      return 'Bullet point cannot exceed $maxLength characters';
    }
    return null;
  }
}
