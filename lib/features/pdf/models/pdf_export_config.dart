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

enum PdfColorPalette {
  templateDefault,
  indigo,
  teal,
  navy,
  emerald,
  charcoal,
  crimson,
  purple;

  String get displayName {
    switch (this) {
      case PdfColorPalette.templateDefault:
        return 'Default';
      case PdfColorPalette.indigo:
        return 'Indigo';
      case PdfColorPalette.teal:
        return 'Teal';
      case PdfColorPalette.navy:
        return 'Navy';
      case PdfColorPalette.emerald:
        return 'Emerald';
      case PdfColorPalette.charcoal:
        return 'Charcoal';
      case PdfColorPalette.crimson:
        return 'Crimson';
      case PdfColorPalette.purple:
        return 'Purple';
    }
  }

  PdfColor? get pdfColor {
    switch (this) {
      case PdfColorPalette.templateDefault:
        return null;
      case PdfColorPalette.indigo:
        return PdfColor.fromHex('#4F46E5');
      case PdfColorPalette.teal:
        return PdfColor.fromHex('#0D9488');
      case PdfColorPalette.navy:
        return PdfColor.fromHex('#1B2A4A');
      case PdfColorPalette.emerald:
        return PdfColor.fromHex('#059669');
      case PdfColorPalette.charcoal:
        return PdfColor.fromHex('#334155');
      case PdfColorPalette.crimson:
        return PdfColor.fromHex('#991B1B');
      case PdfColorPalette.purple:
        return PdfColor.fromHex('#7C3AED');
    }
  }

  Color get uiColor {
    switch (this) {
      case PdfColorPalette.templateDefault:
        return const Color(0xFF64748B);
      case PdfColorPalette.indigo:
        return const Color(0xFF4F46E5);
      case PdfColorPalette.teal:
        return const Color(0xFF0D9488);
      case PdfColorPalette.navy:
        return const Color(0xFF1B2A4A);
      case PdfColorPalette.emerald:
        return const Color(0xFF059669);
      case PdfColorPalette.charcoal:
        return const Color(0xFF334155);
      case PdfColorPalette.crimson:
        return const Color(0xFF991B1B);
      case PdfColorPalette.purple:
        return const Color(0xFF7C3AED);
    }
  }
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

class PdfExportConfig {
  final PdfMarginOption marginOption;
  final PdfColorPalette colorPalette;
  final PdfFontFamily fontFamily;
  final double? customMargin;
  final double lineHeight;
  final Color? customPrimaryColor;

  const PdfExportConfig({
    this.marginOption = PdfMarginOption.normal,
    this.colorPalette = PdfColorPalette.templateDefault,
    this.fontFamily = PdfFontFamily.helvetica,
    this.customMargin,
    this.lineHeight = 1.35,
    this.customPrimaryColor,
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

  PdfExportConfig copyWith({
    PdfMarginOption? marginOption,
    PdfColorPalette? colorPalette,
    PdfFontFamily? fontFamily,
    double? customMargin,
    double? lineHeight,
    Color? customPrimaryColor,
  }) {
    return PdfExportConfig(
      marginOption: marginOption ?? this.marginOption,
      colorPalette: colorPalette ?? this.colorPalette,
      fontFamily: fontFamily ?? this.fontFamily,
      customMargin: customMargin ?? this.customMargin,
      lineHeight: lineHeight ?? this.lineHeight,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
    );
  }

  pw.ThemeData get themeData {
    return pw.ThemeData.withFont(
      base: fontFamily.baseFont,
      bold: fontFamily.boldFont,
    );
  }
}
