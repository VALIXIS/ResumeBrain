import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/ai_key_storage_service.dart';
import '../services/gemini_ai_provider.dart';
import '../services/groq_ai_provider.dart';
import '../services/openai_ai_provider.dart';
import '../services/ai_service.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _keyStorage = AIKeyStorageService();
  final _geminiController = TextEditingController();
  final _groqController = TextEditingController();
  final _openaiController = TextEditingController();

  ActiveAIProviderType _activeProvider = ActiveAIProviderType.hybrid;
  bool _isLoading = true;
  bool _isTestingKey = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  Future<void> _loadSavedKeys() async {
    final geminiKey = await _keyStorage.getGeminiKey();
    final groqKey = await _keyStorage.getGroqKey();
    final openaiKey = await _keyStorage.getOpenAIKey();
    final active = await _keyStorage.getActiveProvider();

    setState(() {
      _geminiController.text = geminiKey ?? '';
      _groqController.text = groqKey ?? '';
      _openaiController.text = openaiKey ?? '';
      _activeProvider = active;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _keyStorage.saveGeminiKey(_geminiController.text);
    await _keyStorage.saveGroqKey(_groqController.text);
    await _keyStorage.saveOpenAIKey(_openaiController.text);
    await _keyStorage.saveActiveProvider(_activeProvider);

    if (mounted) {
      AppSnackBar.showSuccess(context, 'AI Provider configuration saved securely.');
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingKey = true;
      _testResult = null;
    });

    final req = AIRequest(
      taskType: AITaskType.textImprovement,
      inputText: 'Managed cross-functional development team and delivered mobile application.',
    );

    AIResponse response;

    if (_activeProvider == ActiveAIProviderType.gemini) {
      final key = _geminiController.text.trim();
      response = await GeminiAIProvider(apiKey: key).processRequest(req);
    } else if (_activeProvider == ActiveAIProviderType.groq) {
      final key = _groqController.text.trim();
      response = await GroqAIProvider(apiKey: key).processRequest(req);
    } else if (_activeProvider == ActiveAIProviderType.openai) {
      final key = _openaiController.text.trim();
      response = await OpenAIProvider(apiKey: key).processRequest(req);
    } else {
      final geminiKey = _geminiController.text.trim();
      response = await GeminiAIProvider(apiKey: geminiKey).processRequest(req);
    }

    if (mounted) {
      setState(() {
        _isTestingKey = false;
        if (response.isSuccess) {
          _testResult = 'Connection successful! Response: "${response.outputText}"';
        } else {
          _testResult = 'Connection failed: ${response.errorMessage}';
        }
      });
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _groqController.dispose();
    _openaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Engine & Key Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary AI Provider', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Select which AI engine powers live resume analysis, bullet point rewrites, and job tailoring.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildProviderSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('API Keys (Stored Encrypted)', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'API keys are stored securely using hardware-backed encryption on your device.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _geminiController,
                    label: 'Google Gemini API Key',
                    hint: 'AIzaSy...',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _groqController,
                    label: 'Groq Cloud API Key',
                    hint: 'gsk_...',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _openaiController,
                    label: 'OpenAI API Key',
                    hint: 'sk-proj-...',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diagnostic Test', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Test connectivity and verify that your configured API key generates live response data.',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_testResult != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _testResult!.startsWith('Connection successful')
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : AppColors.accentRed.withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              _testResult!,
                              style: AppTypography.bodySmall.copyWith(
                                color: _testResult!.startsWith('Connection successful')
                                    ? Colors.green
                                    : AppColors.accentRed,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppButton(
                          text: _isTestingKey ? 'Testing Connection...' : 'Test Selected AI Provider',
                          isLoading: _isTestingKey,
                          isFullWidth: true,
                          onPressed: _testConnection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Save AI Configuration',
                    isFullWidth: true,
                    onPressed: _saveSettings,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildProviderSelector() {
    return Column(
      children: [
        _buildProviderRadioTile(
          type: ActiveAIProviderType.hybrid,
          title: 'Hybrid Engine (Gemini + Groq Auto-Failover)',
          subtitle: 'Uses Gemini Flash as primary and Groq Llama as fallback.',
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildProviderRadioTile(
          type: ActiveAIProviderType.gemini,
          title: 'Google Gemini 2.5 Flash',
          subtitle: 'High precision structured JSON analysis.',
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildProviderRadioTile(
          type: ActiveAIProviderType.groq,
          title: 'Groq Cloud (Llama 3.3 70B)',
          subtitle: 'Ultra-fast sub-second responses.',
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildProviderRadioTile(
          type: ActiveAIProviderType.openai,
          title: 'OpenAI (GPT-4o mini)',
          subtitle: 'Industry standard for career content tailoring.',
        ),
      ],
    );
  }

  Widget _buildProviderRadioTile({
    required ActiveAIProviderType type,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _activeProvider == type;
    return AppCard(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
      onTap: () {
        setState(() => _activeProvider = type);
      },
      child: Row(
        children: [
          // ignore: deprecated_member_use
          Radio<ActiveAIProviderType>(
            value: type,
            // ignore: deprecated_member_use
            groupValue: _activeProvider,
            activeColor: AppColors.primary,
            // ignore: deprecated_member_use
            onChanged: (val) {
              if (val != null) setState(() => _activeProvider = val);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
