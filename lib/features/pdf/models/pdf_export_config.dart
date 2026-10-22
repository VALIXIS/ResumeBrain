import 'dart:math' as math;
import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum PdfMarginOption {
  compact,
  normal,
  spacious;

  String get displayName {
    switch (this) {
      case PdfMarginOption.compact:
        return 'Compact (0.25")';
      case PdfMarginOption.normal:
        return 'Normal (0.5")';
      case PdfMarginOption.spacious:
        return 'Spacious (0.75")';
    }
  }

  pw.EdgeInsets get insets {
    switch (this) {
      case PdfMarginOption.compact:
        return const pw.EdgeInsets.all(18);
      case PdfMarginOption.normal:
        return const pw.EdgeInsets.all(36);
      case PdfMarginOption.spacious:
        return const pw.EdgeInsets.all(54);
    }
  }
}

/// Represents an executive-grade color palette specifically engineered to maintain
/// high contrast on standard white paper (WCAG AA/AAA compliance) and crisp legibility
/// on black-and-white office laser printers (halftone/monochrome rasterization).
class ExecutivePalette {
  final String id;
  final String name;
  final PdfColor primary;
  final PdfColor accent;
  final PdfColor secondaryAccent;
  final PdfColor text;
  final PdfColor mutedText;
  final PdfColor divider;
  final PdfColor badgeBackground;
  final PdfColor badgeBorder;
  final PdfColor badgeText;
  final Color uiColor;

  const ExecutivePalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.accent,
    required this.secondaryAccent,
    required this.text,
    required this.mutedText,
    required this.divider,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.badgeText,
    required this.uiColor,
  });

  /// Computes the relative luminance of a [PdfColor] according to WCAG 2.1 specifications.
  static double calculateLuminance(PdfColor color) {
    double transform(double val) {
      return val <= 0.03928
          ? val / 12.92
          : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.red);
    final g = transform(color.green);
    final b = transform(color.blue);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates the contrast ratio against standard white paper (#FFFFFF).
  /// Minimum recommended ratio is 4.5:1 (WCAG AA), optimal is >= 7:1 (WCAG AAA).
  static double calculateContrastRatioOnWhite(PdfColor color) {
    final l = calculateLuminance(color);
    return 1.05 / (l + 0.05);
  }

  /// Estimates the laser printer black toner density (0.0 = white, 1.0 = solid black toner).
  /// Colors with density >= 0.60 render as crisp, solid dark elements on monochrome laser printers.
  static double calculateLaserPrinterDensity(PdfColor color) {
    final gray = 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return (1.0 - gray).clamp(0.0, 1.0);
  }

  /// Accent contrast ratio against standard white paper.
  double get contrastRatioOnWhite => calculateContrastRatioOnWhite(accent);

  /// Accent monochrome laser printer toner density.
  double get laserPrinterDensity => calculateLaserPrinterDensity(accent);

  /// Returns true if this accent color achieves high contrast (>= 4.5:1) on white paper.
  bool get hasHighWhitePaperContrast => contrastRatioOnWhite >= 4.5;

  /// Returns true if this accent color achieves crisp laser print toner density (>= 0.55).
  bool get isLaserPrinterSafe => laserPrinterDensity >= 0.55;

  // ---------------------------------------------------------------------------
  // Predefined Executive Palettes
  // ---------------------------------------------------------------------------

  /// Executive Navy: Oxford/Corporate navy with high contrast and authoritative presence.
  static final ExecutivePalette navy = ExecutivePalette(
    id: 'navy',
    name: 'Executive Navy',
    primary: PdfColor.fromHex('#0F172A'), // Slate 900
    accent: PdfColor.fromHex('#1E3A8A'), // Blue 900 (~10.3:1 contrast)
    secondaryAccent: PdfColor.fromHex('#1E40AF'), // Blue 800
    text: PdfColor.fromHex('#1E293B'), // Slate 800
    mutedText: PdfColor.fromHex('#475569'), // Slate 600 (~7.3:1 contrast)
    divider: PdfColor.fromHex('#CBD5E1'), // Slate 300
    badgeBackground: PdfColor.fromHex('#EFF6FF'),
    badgeBorder: PdfColor.fromHex('#BFDBFE'),
    badgeText: PdfColor.fromHex('#1E3A8A'),
    uiColor: const Color(0xFF1E3A8A),
  );

  /// Slate Charcoal: Timeless, graphite slate engineered for pure neutral elegance.
  static final ExecutivePalette charcoal = ExecutivePalette(
    id: 'charcoal',
    name: 'Slate Charcoal',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#1E293B'), // Slate 800 (~14.4:1 contrast)
    secondaryAccent: PdfColor.fromHex('#334155'), // Slate 700
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#F1F5F9'),
    badgeBorder: PdfColor.fromHex('#CBD5E1'),
    badgeText: PdfColor.fromHex('#1E293B'),
    uiColor: const Color(0xFF1E293B),
  );

  /// Executive Burgundy: Distinguished Bordeaux wine with rich academic/executive tone.
  static final ExecutivePalette burgundy = ExecutivePalette(
    id: 'burgundy',
    name: 'Executive Burgundy',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#701A28'), // Deep Bordeaux (~11.9:1 contrast)
    secondaryAccent: PdfColor.fromHex('#831843'), // Rose 900
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#FFF1F2'),
    badgeBorder: PdfColor.fromHex('#FECDD3'),
    badgeText: PdfColor.fromHex('#701A28'),
    uiColor: const Color(0xFF701A28),
  );

  /// Forest Emerald: British racing green / deep pine with crisp monochrome density.
  static final ExecutivePalette emerald = ExecutivePalette(
    id: 'emerald',
    name: 'Forest Emerald',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#064E3B'), // Emerald 900 (~10.9:1 contrast)
    secondaryAccent: PdfColor.fromHex('#065F46'), // Emerald 800
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#ECFDF5'),
    badgeBorder: PdfColor.fromHex('#A7F3D0'),
    badgeText: PdfColor.fromHex('#064E3B'),
    uiColor: const Color(0xFF064E3B),
  );

  /// Deep Teal: High-density dark cyan-teal providing modern yet reserved contrast.
  static final ExecutivePalette teal = ExecutivePalette(
    id: 'teal',
    name: 'Deep Teal',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#115E59'), // Teal 800 (~7.3:1 contrast)
    secondaryAccent: PdfColor.fromHex('#0F766E'), // Teal 700
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#F0FDFA'),
    badgeBorder: PdfColor.fromHex('#99F6E4'),
    badgeText: PdfColor.fromHex('#115E59'),
    uiColor: const Color(0xFF115E59),
  );

  /// Steel Blue: Professional Nordic slate blue tailored for technology and engineering.
  static final ExecutivePalette steelBlue = ExecutivePalette(
    id: 'steelBlue',
    name: 'Steel Blue',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#1E40AF'), // Blue 800 (~8.9:1 contrast)
    secondaryAccent: PdfColor.fromHex('#1D4ED8'), // Blue 700
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#EFF6FF'),
    badgeBorder: PdfColor.fromHex('#BFDBFE'),
    badgeText: PdfColor.fromHex('#1E40AF'),
    uiColor: const Color(0xFF1E40AF),
  );

  /// Crimson Bordeaux: Deep red with strong visual gravity and laser print darkness.
  static final ExecutivePalette crimson = ExecutivePalette(
    id: 'crimson',
    name: 'Crimson Bordeaux',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#7F1D1D'), // Red 900 (~11.3:1 contrast)
    secondaryAccent: PdfColor.fromHex('#991B1B'), // Red 800
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#FEF2F2'),
    badgeBorder: PdfColor.fromHex('#FECACA'),
    badgeText: PdfColor.fromHex('#7F1D1D'),
    uiColor: const Color(0xFF7F1D1D),
  );

  /// Midnight Indigo: Deep midnight indigo with low luminance and zero print speckling.
  static final ExecutivePalette indigo = ExecutivePalette(
    id: 'indigo',
    name: 'Midnight Indigo',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#312E81'), // Indigo 900 (~12.2:1 contrast)
    secondaryAccent: PdfColor.fromHex('#3730A3'), // Indigo 800
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#EEF2FF'),
    badgeBorder: PdfColor.fromHex('#C7D2FE'),
    badgeText: PdfColor.fromHex('#312E81'),
    uiColor: const Color(0xFF312E81),
  );

  /// Deep Plum: Authoritative royal purple with dark laser toner density.
  static final ExecutivePalette purple = ExecutivePalette(
    id: 'purple',
    name: 'Deep Plum',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#4C1D95'), // Purple 900 (~12.6:1 contrast)
    secondaryAccent: PdfColor.fromHex('#581C87'), // Purple 800
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#FAF5FF'),
    badgeBorder: PdfColor.fromHex('#E9D5FF'),
    badgeText: PdfColor.fromHex('#4C1D95'),
    uiColor: const Color(0xFF4C1D95),
  );

  /// Warm Espresso: Classical dark bronze/espresso tone with rich warmth.
  static final ExecutivePalette espresso = ExecutivePalette(
    id: 'espresso',
    name: 'Warm Espresso',
    primary: PdfColor.fromHex('#0F172A'),
    accent: PdfColor.fromHex('#451A03'), // Amber 950 (~14.8:1 contrast)
    secondaryAccent: PdfColor.fromHex('#78350F'), // Amber 900
    text: PdfColor.fromHex('#1E293B'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#CBD5E1'),
    badgeBackground: PdfColor.fromHex('#FFFBEB'),
    badgeBorder: PdfColor.fromHex('#FDE68A'),
    badgeText: PdfColor.fromHex('#451A03'),
    uiColor: const Color(0xFF451A03),
  );

  /// Monochrome Black: Pure black & dark slate for 100% laser print contrast.
  static final ExecutivePalette monochrome = ExecutivePalette(
    id: 'monochrome',
    name: 'Monochrome Black',
    primary: PdfColor.fromHex('#000000'), // 100% K
    accent: PdfColor.fromHex('#111827'), // Gray 900 (~17.5:1 contrast)
    secondaryAccent: PdfColor.fromHex('#374151'), // Gray 700
    text: PdfColor.fromHex('#111827'),
    mutedText: PdfColor.fromHex('#475569'),
    divider: PdfColor.fromHex('#94A3B8'),
    badgeBackground: PdfColor.fromHex('#F3F4F6'),
    badgeBorder: PdfColor.fromHex('#D1D5DB'),
    badgeText: PdfColor.fromHex('#111827'),
    uiColor: const Color(0xFF111827),
  );
}

enum PdfColorPalette {
  templateDefault,
  navy,
  charcoal,
  burgundy,
  emerald,
  teal,
  steelBlue,
  crimson,
  indigo,
  purple,
  espresso,
  monochrome;

  String get displayName {
    switch (this) {
      case PdfColorPalette.templateDefault:
        return 'Default';
      case PdfColorPalette.navy:
        return 'Executive Navy';
      case PdfColorPalette.charcoal:
        return 'Slate Charcoal';
      case PdfColorPalette.burgundy:
        return 'Executive Burgundy';
      case PdfColorPalette.emerald:
        return 'Forest Emerald';
      case PdfColorPalette.teal:
        return 'Deep Teal';
      case PdfColorPalette.steelBlue:
        return 'Steel Blue';
      case PdfColorPalette.crimson:
        return 'Crimson Bordeaux';
      case PdfColorPalette.indigo:
        return 'Midnight Indigo';
      case PdfColorPalette.purple:
        return 'Deep Plum';
      case PdfColorPalette.espresso:
        return 'Warm Espresso';
      case PdfColorPalette.monochrome:
        return 'Monochrome Black';
    }
  }

  /// Returns the full executive color palette tokens, or null when using template default.
  ExecutivePalette? get executivePalette {
    switch (this) {
      case PdfColorPalette.templateDefault:
        return null;
      case PdfColorPalette.navy:
        return ExecutivePalette.navy;
      case PdfColorPalette.charcoal:
        return ExecutivePalette.charcoal;
      case PdfColorPalette.burgundy:
        return ExecutivePalette.burgundy;
      case PdfColorPalette.emerald:
        return ExecutivePalette.emerald;
      case PdfColorPalette.teal:
        return ExecutivePalette.teal;
      case PdfColorPalette.steelBlue:
        return ExecutivePalette.steelBlue;
      case PdfColorPalette.crimson:
        return ExecutivePalette.crimson;
      case PdfColorPalette.indigo:
        return ExecutivePalette.indigo;
      case PdfColorPalette.purple:
        return ExecutivePalette.purple;
      case PdfColorPalette.espresso:
        return ExecutivePalette.espresso;
      case PdfColorPalette.monochrome:
        return ExecutivePalette.monochrome;
    }
  }

  /// Alias for [executivePalette] to cleanly access color tokens.
  ExecutivePalette? get paletteColors => executivePalette;

  /// Primary accent color for headers and rules.
  PdfColor? get pdfColor => executivePalette?.accent;

  /// Representative UI color for color-picker chips in export modal.
  Color get uiColor => executivePalette?.uiColor ?? const Color(0xFF64748B);
}

enum PdfFontFamily {
  helvetica,
  times,
  courier;

  String get displayName {
    switch (this) {
      case PdfFontFamily.helvetica:
        return 'Helvetica (Sans-Serif)';
      case PdfFontFamily.times:
        return 'Times New Roman (Serif)';
      case PdfFontFamily.courier:
        return 'Courier (Monospace)';
    }
  }

  pw.Font get baseFont {
    switch (this) {
      case PdfFontFamily.helvetica:
        return pw.Font.helvetica();
      case PdfFontFamily.times:
        return pw.Font.times();
      case PdfFontFamily.courier:
        return pw.Font.courier();
    }
  }

  pw.Font get boldFont {
    switch (this) {
      case PdfFontFamily.helvetica:
        return pw.Font.helveticaBold();
      case PdfFontFamily.times:
        return pw.Font.timesBold();
      case PdfFontFamily.courier:
        return pw.Font.courierBold();
    }
  }
}

enum PdfContactIconStyle {
  icon,
  text;

  String get displayName {
    switch (this) {
      case PdfContactIconStyle.icon:
        return 'Icons';
      case PdfContactIconStyle.text:
        return 'Text Labels';
    }
  }

  bool get isIcon => this == PdfContactIconStyle.icon;
  bool get isText => this == PdfContactIconStyle.text;
}

enum PdfDateFormat {
  monthYear,
  numericMonthYear;

  String get displayName {
    switch (this) {
      case PdfDateFormat.monthYear:
        return 'Month YYYY (e.g. Jan 2024)';
      case PdfDateFormat.numericMonthYear:
        return 'MM/YYYY (e.g. 01/2024)';
    }
  }

  bool get isNumeric => this == PdfDateFormat.numericMonthYear;
  bool get isMonthYear => this == PdfDateFormat.monthYear;
}

/// Vector contact icons engineered for PDF export without external font dependencies.
class PdfContactIcons {
  static const emailSvg =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>';
  static const phoneSvg =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>';
  static const locationSvg =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>';
  static const websiteSvg =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1 4-10z"/></svg>';
  static const linkSvg =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';

  static pw.Widget getIcon(String type, {PdfColor color = PdfColors.black, double size = 8.5}) {
    final hex = color.toHex().replaceAll('#', '');
    String svg;
    switch (type.toLowerCase()) {
      case 'email':
      case 'mail':
        svg = emailSvg.replaceAll('#COLOR', '#$hex');
        break;
      case 'phone':
      case 'tel':
      case 'mobile':
        svg = phoneSvg.replaceAll('#COLOR', '#$hex');
        break;
      case 'location':
      case 'address':
      case 'city':
        svg = locationSvg.replaceAll('#COLOR', '#$hex');
        break;
      case 'website':
      case 'web':
      case 'portfolio':
        svg = websiteSvg.replaceAll('#COLOR', '#$hex');
        break;
      default:
        svg = linkSvg.replaceAll('#COLOR', '#$hex');
        break;
    }
    return pw.SvgImage(
      svg: svg,
      width: size,
      height: size,
    );
  }
}

class PdfExportConfig {
  final PdfMarginOption marginOption;
  final PdfColorPalette colorPalette;
  final PdfFontFamily fontFamily;
  final double? customMargin;
  final double lineHeight;
  final Color? customPrimaryColor;
  final bool showPageNumbers;
  final PdfContactIconStyle contactIconStyle;
  final PdfDateFormat dateFormat;

  const PdfExportConfig({
    this.marginOption = PdfMarginOption.normal,
    this.colorPalette = PdfColorPalette.templateDefault,
    this.fontFamily = PdfFontFamily.helvetica,
    this.customMargin,
    this.lineHeight = 1.35,
    this.customPrimaryColor,
    this.showPageNumbers = true,
    this.contactIconStyle = PdfContactIconStyle.icon,
    this.dateFormat = PdfDateFormat.monthYear,
  });

  pw.EdgeInsets get insets {
    if (customMargin != null) {
      return pw.EdgeInsets.all(customMargin!);
    }
    return marginOption.insets;
  }

  PdfColor? get resolvedPdfColor {
    if (customPrimaryColor != null) {
      final c = customPrimaryColor!;
      return PdfColor(c.r, c.g, c.b, c.a);
    }
    return colorPalette.pdfColor;
  }

  /// Formats a raw date string according to [PdfDateFormat]:
  /// - [PdfDateFormat.monthYear]: e.g., 'Jan 2024', 'May 2022'
  /// - [PdfDateFormat.numericMonthYear]: e.g., '01/2024', '05/2022'
  /// Gracefully handles 'Present', 'Current', empty strings, 4-digit years ('2021'),
  /// full/abbreviated month names ('January 2021', 'Jan 2021'),
  /// and ISO or slash dates ('2021-01', '01/2021').
  static String formatDate(String rawDate, [PdfDateFormat format = PdfDateFormat.monthYear]) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase() == 'present' || trimmed.toLowerCase() == 'current') {
      return 'Present';
    }

    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // 1. Check if it's only a 4-digit year e.g. "2021"
    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return trimmed;
    }

    int? month;
    int? year;

    // 2. Match MM/YYYY or MM-YYYY e.g. "01/2021" or "1/2021"
    final mYearMatch = RegExp(r'^(\d{1,2})[/-](\d{4})$').firstMatch(trimmed);
    if (mYearMatch != null) {
      month = int.tryParse(mYearMatch.group(1)!);
      year = int.tryParse(mYearMatch.group(2)!);
    }

    // 3. Match YYYY/MM or YYYY-MM e.g. "2021-01" or "2021/1"
    if (month == null) {
      final yMonthMatch = RegExp(r'^(\d{4})[/-](\d{1,2})$').firstMatch(trimmed);
      if (yMonthMatch != null) {
        year = int.tryParse(yMonthMatch.group(1)!);
        month = int.tryParse(yMonthMatch.group(2)!);
      }
    }

    // 4. Match Month Name + Year e.g. "Jan 2021", "January 2021", "Jan. 2021"
    if (month == null) {
      final nameYearMatch = RegExp(r'^([A-Za-z]+)\.?\s+(\d{4})$').firstMatch(trimmed);
      if (nameYearMatch != null) {
        final namePart = nameYearMatch.group(1)!.toLowerCase();
        year = int.tryParse(nameYearMatch.group(2)!);
        for (int i = 0; i < shortMonths.length; i++) {
          if (namePart.startsWith(shortMonths[i].toLowerCase())) {
            month = i + 1;
            break;
          }
        }
      }
    }

    // 5. Try standard DateTime parse
    if (month == null) {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        month = dt.month;
        year = dt.year;
      }
    }

    // If successfully parsed month and year:
    if (month != null && year != null && month >= 1 && month <= 12) {
      if (format == PdfDateFormat.numericMonthYear) {
        return '${month.toString().padLeft(2, '0')}/$year';
      } else {
        return '${shortMonths[month - 1]} $year';
      }
    }

    // Fallback: return trimmed original string
    return trimmed;
  }

  /// Formats a date range e.g. '01/2021 - Present' or 'Jan 2021 - May 2023'
  static String formatDateRange({
    String? startDate,
    String? endDate,
    bool isCurrent = false,
    PdfDateFormat format = PdfDateFormat.monthYear,
  }) {
    final start = (startDate != null && startDate.trim().isNotEmpty)
        ? formatDate(startDate, format)
        : '';
    final end = isCurrent
        ? 'Present'
        : (endDate != null && endDate.trim().isNotEmpty)
            ? formatDate(endDate, format)
            : '';

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    } else if (start.isNotEmpty) {
      return start;
    } else {
      return end;
    }
  }

  PdfExportConfig copyWith({
    PdfMarginOption? marginOption,
    PdfColorPalette? colorPalette,
    PdfFontFamily? fontFamily,
    double? customMargin,
    double? lineHeight,
    Color? customPrimaryColor,
    bool? showPageNumbers,
    PdfContactIconStyle? contactIconStyle,
    PdfDateFormat? dateFormat,
  }) {
    return PdfExportConfig(
      marginOption: marginOption ?? this.marginOption,
      colorPalette: colorPalette ?? this.colorPalette,
      fontFamily: fontFamily ?? this.fontFamily,
      customMargin: customMargin ?? this.customMargin,
      lineHeight: lineHeight ?? this.lineHeight,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      contactIconStyle: contactIconStyle ?? this.contactIconStyle,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }

  pw.ThemeData get themeData {
    return pw.ThemeData.withFont(
      base: fontFamily.baseFont,
      bold: fontFamily.boldFont,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfExportConfig &&
          runtimeType == other.runtimeType &&
          marginOption == other.marginOption &&
          colorPalette == other.colorPalette &&
          fontFamily == other.fontFamily &&
          customMargin == other.customMargin &&
          lineHeight == other.lineHeight &&
          customPrimaryColor == other.customPrimaryColor &&
          showPageNumbers == other.showPageNumbers &&
          contactIconStyle == other.contactIconStyle &&
          dateFormat == other.dateFormat;

  @override
  int get hashCode => Object.hash(
        marginOption,
        colorPalette,
        fontFamily,
        customMargin,
        lineHeight,
        customPrimaryColor,
        showPageNumbers,
        contactIconStyle,
        dateFormat,
      );

  @override
  String toString() =>
      'PdfExportConfig(margin: $marginOption, palette: $colorPalette, '
      'font: $fontFamily, customMargin: $customMargin, lineHeight: $lineHeight, '
      'customColor: $customPrimaryColor, pageNumbers: $showPageNumbers, '
      'contactIcons: $contactIconStyle, dateFormat: $dateFormat)';
}
