import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pdf_export_config.dart';

class PdfExportCustomizationDialog extends StatefulWidget {
  final PdfExportConfig initialConfig;

  const PdfExportCustomizationDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<PdfExportCustomizationDialog> createState() =>
      _PdfExportCustomizationDialogState();
}

class _PdfExportCustomizationDialogState
    extends State<PdfExportCustomizationDialog> {
  late PdfMarginOption _marginOption;
  late PdfColorPalette _colorPalette;
  late PdfFontFamily _fontFamily;
  late bool _showPageNumbers;
  late PdfContactIconStyle _contactIconStyle;
  late PdfDateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _marginOption = widget.initialConfig.marginOption;
    _colorPalette = widget.initialConfig.colorPalette;
    _fontFamily = widget.initialConfig.fontFamily;
    _showPageNumbers = widget.initialConfig.showPageNumbers;
    _contactIconStyle = widget.initialConfig.contactIconStyle;
    _dateFormat = widget.initialConfig.dateFormat;
  }

  void _resetToDefaults() {
    setState(() {
      _marginOption = PdfMarginOption.normal;
      _colorPalette = PdfColorPalette.templateDefault;
      _fontFamily = PdfFontFamily.helvetica;
      _showPageNumbers = true;
      _contactIconStyle = PdfContactIconStyle.icon;
      _dateFormat = PdfDateFormat.monthYear;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
      ),
      title: Row(
        children: [
          const Icon(Icons.tune_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Customize PDF Export',
              style: AppTypography.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Margin Selection Section
              _buildSectionTitle('Page Margins', Icons.aspect_ratio),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PdfMarginOption.values.map((option) {
                  final isSelected = _marginOption == option;
                  return ChoiceChip(
                    label: Text(option.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _marginOption = option);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Color Palette Section
              _buildSectionTitle('Color Palette / Accent', Icons.palette_outlined),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PdfColorPalette.values.map((palette) {
                  final isSelected = _colorPalette == palette;
                  return InkWell(
                    onTap: () {
                      setState(() => _colorPalette = palette);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.uiColor.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? palette.uiColor : AppColors.surfaceBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: palette.uiColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            palette.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Font Family Section
              _buildSectionTitle('Font Family', Icons.font_download_outlined),
              const SizedBox(height: 8),
              DropdownButtonFormField<PdfFontFamily>(
                initialValue: _fontFamily,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                items: PdfFontFamily.values.map((font) {
                  return DropdownMenuItem<PdfFontFamily>(
                    value: font,
                    child: Text(
                      font.displayName,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (newFont) {
                  if (newFont != null) {
                    setState(() => _fontFamily = newFont);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Page Numbering Section
              _buildSectionTitle('Page Numbering', Icons.format_list_numbered_rounded),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  title: Text(
                    'Page Numbers (e.g. Page 1 of 2)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _showPageNumbers
                        ? 'Display "Page 1 of 2" in document footer'
                        : 'Page numbering disabled in document footer',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _showPageNumbers,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _showPageNumbers = val),
                ),
              ),
              const SizedBox(height: 20),

              // Contact Icon Style Section
              _buildSectionTitle('Contact Icon Style', Icons.contact_mail_outlined),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Contact Display Style',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _contactIconStyle == PdfContactIconStyle.icon
                              ? 'Icons (compact symbol glyphs)'
                              : 'Text labels (e.g. Email:, Phone:)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        value: _contactIconStyle == PdfContactIconStyle.icon,
                        activeTrackColor: AppColors.primary,
                        onChanged: (isIcon) {
                          setState(() {
                            _contactIconStyle =
                                isIcon ? PdfContactIconStyle.icon : PdfContactIconStyle.text;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: PdfContactIconStyle.values.map((style) {
                          final isSelected = _contactIconStyle == style;
                          return ChoiceChip(
                            label: Text(style.displayName),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _contactIconStyle = style);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Format Section
              _buildSectionTitle('Date Format', Icons.calendar_month_outlined),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Numeric Date Format (MM/YYYY)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _dateFormat == PdfDateFormat.numericMonthYear
                              ? 'MM/YYYY (e.g. 05/2023 - Present)'
                              : 'Month YYYY (e.g. May 2023 - Present)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        value: _dateFormat == PdfDateFormat.numericMonthYear,
                        activeTrackColor: AppColors.primary,
                        onChanged: (isNumeric) {
                          setState(() {
                            _dateFormat = isNumeric
                                ? PdfDateFormat.numericMonthYear
                                : PdfDateFormat.monthYear;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: PdfDateFormat.values.map((format) {
                          final isSelected = _dateFormat == format;
                          return ChoiceChip(
                            label: Text(format.displayName),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _dateFormat = format);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('Reset', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final config = PdfExportConfig(
              marginOption: _marginOption,
              colorPalette: _colorPalette,
              fontFamily: _fontFamily,
              showPageNumbers: _showPageNumbers,
              contactIconStyle: _contactIconStyle,
              dateFormat: _dateFormat,
            );
            Navigator.pop(context, config);
          },
          child: const Text('Apply & Export'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
