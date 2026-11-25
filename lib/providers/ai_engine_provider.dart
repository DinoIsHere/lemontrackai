import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

enum AiProvider { openAi, claude, openRouter, custom, ollama }

class AiEngineConfig {
  const AiEngineConfig({
    this.provider = AiProvider.openAi,
    this.openAiKey = '',
    this.openAiModel = 'gpt-4o-mini',
    this.claudeKey = '',
    this.claudeModel = 'claude-3-5-sonnet-latest',
    this.openRouterKey = '',
    this.openRouterModel = 'google/gemini-2.5-flash',
    this.customBaseUrl = 'http://localhost:8080',
    this.customApiKey = '',
    this.customModel = 'llama-3.1-8b-instruct',
    this.ollamaBaseUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama3.2',
  });

  final AiProvider provider;
  final String openAiKey;
  final String openAiModel;
  final String claudeKey;
  final String claudeModel;
  final String openRouterKey;
  final String openRouterModel;
  final String customBaseUrl;
  final String customApiKey;
  final String customModel;
  final String ollamaBaseUrl;
  final String ollamaModel;

  AiEngineConfig copyWith({
    AiProvider? provider,
    String? openAiKey,
    String? openAiModel,
    String? claudeKey,
    String? claudeModel,
    String? openRouterKey,
    String? openRouterModel,
    String? customBaseUrl,
    String? customApiKey,
    String? customModel,
    String? ollamaBaseUrl,
    String? ollamaModel,
  }) {
    return AiEngineConfig(
      provider: provider ?? this.provider,
      openAiKey: openAiKey ?? this.openAiKey,
      openAiModel: openAiModel ?? this.openAiModel,
      claudeKey: claudeKey ?? this.claudeKey,
      claudeModel: claudeModel ?? this.claudeModel,
      openRouterKey: openRouterKey ?? this.openRouterKey,
      openRouterModel: openRouterModel ?? this.openRouterModel,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      customApiKey: customApiKey ?? this.customApiKey,
      customModel: customModel ?? this.customModel,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
    );
  }
}

class AiEngineNotifier extends StateNotifier<AiEngineConfig> {
  AiEngineNotifier(this._ref) : super(const AiEngineConfig()) {
    _load();
  }

  final Ref _ref;

  static const _providerKey = 'ai_provider';
  static const _openAiKey = 'ai_openai_key';
  static const _openAiModelKey = 'ai_openai_model';
  static const _claudeKey = 'ai_claude_key';
  static const _claudeModelKey = 'ai_claude_model';
  static const _openRouterKey = 'ai_openrouter_key';
  static const _openRouterModelKey = 'ai_openrouter_model';
  static const _customBaseUrlKey = 'ai_custom_base_url';
  static const _customApiKey = 'ai_custom_api_key';
  static const _customModelKey = 'ai_custom_model';
  static const _ollamaUrlKey = 'ai_ollama_url';
  static const _ollamaModelKey = 'ai_ollama_model';

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final providerStr = prefs.getString(_providerKey);
    AiProvider provider = AiProvider.openAi;
    if (providerStr == 'claude') provider = AiProvider.claude;
    if (providerStr == 'openrouter') provider = AiProvider.openRouter;
    if (providerStr == 'custom') provider = AiProvider.custom;
    if (providerStr == 'ollama') provider = AiProvider.ollama;

    state = AiEngineConfig(
      provider: provider,
      openAiKey: prefs.getString(_openAiKey) ?? '',
      openAiModel: prefs.getString(_openAiModelKey) ?? 'gpt-4o-mini',
      claudeKey: prefs.getString(_claudeKey) ?? '',
      claudeModel: prefs.getString(_claudeModelKey) ?? 'claude-3-5-sonnet-latest',
      openRouterKey: prefs.getString(_openRouterKey) ?? '',
      openRouterModel: prefs.getString(_openRouterModelKey) ?? 'google/gemini-2.5-flash',
      customBaseUrl: prefs.getString(_customBaseUrlKey) ?? 'http://localhost:8080',
      customApiKey: prefs.getString(_customApiKey) ?? '',
      customModel: prefs.getString(_customModelKey) ?? 'llama-3.1-8b-instruct',
      ollamaBaseUrl: prefs.getString(_ollamaUrlKey) ?? 'http://localhost:11434',
      ollamaModel: prefs.getString(_ollamaModelKey) ?? 'llama3.2',
    );
  }

  Future<void> _save() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    String providerStr = 'openai';
    if (state.provider == AiProvider.claude) providerStr = 'claude';
    if (state.provider == AiProvider.openRouter) providerStr = 'openrouter';
    if (state.provider == AiProvider.custom) providerStr = 'custom';
    if (state.provider == AiProvider.ollama) providerStr = 'ollama';
    await prefs.setString(_providerKey, providerStr);
    await prefs.setString(_openAiKey, state.openAiKey);
    await prefs.setString(_openAiModelKey, state.openAiModel);
    await prefs.setString(_claudeKey, state.claudeKey);
    await prefs.setString(_claudeModelKey, state.claudeModel);
    await prefs.setString(_openRouterKey, state.openRouterKey);
    await prefs.setString(_openRouterModelKey, state.openRouterModel);
    await prefs.setString(_customBaseUrlKey, state.customBaseUrl);
    await prefs.setString(_customApiKey, state.customApiKey);
    await prefs.setString(_customModelKey, state.customModel);
    await prefs.setString(_ollamaUrlKey, state.ollamaBaseUrl);
    await prefs.setString(_ollamaModelKey, state.ollamaModel);
  }

  void setProvider(AiProvider provider) {
    state = state.copyWith(provider: provider);
    _save();
  }

  void setOpenAiKey(String v) {
    state = state.copyWith(openAiKey: v);
    _save();
  }

  void setOpenAiModel(String v) {
    state = state.copyWith(openAiModel: v);
    _save();
  }

  void setClaudeKey(String v) {
    state = state.copyWith(claudeKey: v);
    _save();
  }

  void setClaudeModel(String v) {
    state = state.copyWith(claudeModel: v);
    _save();
  }

  void setOpenRouterKey(String v) {
    state = state.copyWith(openRouterKey: v);
    _save();
  }

  void setOpenRouterModel(String v) {
    state = state.copyWith(openRouterModel: v);
    _save();
  }

  void setCustomBaseUrl(String v) {
    state = state.copyWith(customBaseUrl: v);
    _save();
  }

  void setCustomApiKey(String v) {
    state = state.copyWith(customApiKey: v);
    _save();
  }

  void setCustomModel(String v) {
    state = state.copyWith(customModel: v);
    _save();
  }

  void setOllamaBaseUrl(String v) {
    state = state.copyWith(ollamaBaseUrl: v);
    _save();
  }

  void setOllamaModel(String v) {
    state = state.copyWith(ollamaModel: v);
    _save();
  }
}

final aiEngineProvider =
    StateNotifierProvider<AiEngineNotifier, AiEngineConfig>((ref) {
  return AiEngineNotifier(ref);
});
