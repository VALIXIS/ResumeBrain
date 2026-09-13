import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ActiveAIProviderType { hybrid, gemini, groq, openai }

class AIKeyStorageService {
  static const _storage = FlutterSecureStorage();

  static const _geminiKeyName = 'gemini_api_key';
  static const _groqKeyName = 'groq_api_key';
  static const _openaiKeyName = 'openai_api_key';
  static const _activeProviderName = 'active_ai_provider';

  Future<void> saveGeminiKey(String key) async {
    await _storage.write(key: _geminiKeyName, value: key.trim());
  }

  Future<String?> getGeminiKey() async {
    return await _storage.read(key: _geminiKeyName);
  }

  Future<void> saveGroqKey(String key) async {
    await _storage.write(key: _groqKeyName, value: key.trim());
  }

  Future<String?> getGroqKey() async {
    return await _storage.read(key: _groqKeyName);
  }

  Future<void> saveOpenAIKey(String key) async {
    await _storage.write(key: _openaiKeyName, value: key.trim());
  }

  Future<String?> getOpenAIKey() async {
    return await _storage.read(key: _openaiKeyName);
  }

  Future<void> saveActiveProvider(ActiveAIProviderType provider) async {
    await _storage.write(key: _activeProviderName, value: provider.name);
  }

  Future<ActiveAIProviderType> getActiveProvider() async {
    final str = await _storage.read(key: _activeProviderName);
    if (str == null) return ActiveAIProviderType.hybrid;
    return ActiveAIProviderType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => ActiveAIProviderType.hybrid,
    );
  }

  Future<void> clearAllKeys() async {
    await _storage.delete(key: _geminiKeyName);
    await _storage.delete(key: _groqKeyName);
    await _storage.delete(key: _openaiKeyName);
    await _storage.delete(key: _activeProviderName);
  }
}
