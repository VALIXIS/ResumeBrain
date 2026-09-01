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

  @override
  void initState() {
    super.initState();
    _marginOption = widget.initialConfig.marginOption;
    _colorPalette = widget.initialConfig.colorPalette;
    _fontFamily = widget.initialConfig.fontFamily;
  }

  void _resetToDefaults() {
    setState(() {
      _marginOption = PdfMarginOption.normal;
      _colorPalette = PdfColorPalette.templateDefault;
      _fontFamily = PdfFontFamily.helvetica;
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
