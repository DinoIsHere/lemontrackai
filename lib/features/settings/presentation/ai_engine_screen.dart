import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/chat/data/ai_chat_service.dart';
import '../../../providers/ai_engine_provider.dart';

class AiEngineScreen extends ConsumerStatefulWidget {
  const AiEngineScreen({super.key});

  @override
  ConsumerState<AiEngineScreen> createState() => _AiEngineScreenState();
}

class _AiEngineScreenState extends ConsumerState<AiEngineScreen> {
  final _openAiKey = TextEditingController();
  final _claudeKey = TextEditingController();
  final _openRouterKey = TextEditingController();
  final _customBaseUrl = TextEditingController();
  final _customApiKey = TextEditingController();
  final _ollamaUrl = TextEditingController();
  List<String> _models = [];
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiEngineProvider);
    _openAiKey.text = config.openAiKey;
    _claudeKey.text = config.claudeKey;
    _openRouterKey.text = config.openRouterKey;
    _customBaseUrl.text = config.customBaseUrl;
    _customApiKey.text = config.customApiKey;
    _ollamaUrl.text = config.ollamaBaseUrl;
  }

  @override
  void dispose() {
    _openAiKey.dispose();
    _claudeKey.dispose();
    _openRouterKey.dispose();
    _customBaseUrl.dispose();
    _customApiKey.dispose();
    _ollamaUrl.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    setState(() => _loadingModels = true);
    final service = AIChatService(ref.read(aiEngineProvider));
    final models = await service.fetchModels();
    if (!mounted) return;
    setState(() {
      _models = models;
      _loadingModels = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiEngineProvider);
    final notifier = ref.read(aiEngineProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Engine'),
        actions: [
          if (config.provider != AiProvider.claude)
            IconButton(
              icon: _loadingModels
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _loadingModels ? null : _fetchModels,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Provider', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<AiProvider>(
            initialValue: config.provider,
            items: const [
              DropdownMenuItem(value: AiProvider.openAi, child: Text('OpenAI')),
              DropdownMenuItem(value: AiProvider.claude, child: Text('Claude')),
              DropdownMenuItem(value: AiProvider.openRouter, child: Text('OpenRouter')),
              DropdownMenuItem(value: AiProvider.custom, child: Text('Custom (OpenAI-compatible)')),
              DropdownMenuItem(value: AiProvider.ollama, child: Text('Ollama (Local)')),
            ],
            onChanged: (v) {
              if (v != null) {
                notifier.setProvider(v);
                setState(() => _models = []);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (config.provider == AiProvider.openAi) ...[
            Text('OpenAI API Key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _openAiKey,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: notifier.setOpenAiKey,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _models.contains(config.openAiModel) ? config.openAiModel : (config.openAiModel.isNotEmpty ? config.openAiModel : null),
              items: [
                if (config.openAiModel.isNotEmpty && !_models.contains(config.openAiModel))
                  DropdownMenuItem(value: config.openAiModel, child: Text(config.openAiModel)),
                ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) {
                if (v != null) notifier.setOpenAiModel(v);
              },
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (config.provider == AiProvider.claude) ...[
            Text('Claude API Key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _claudeKey,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: notifier.setClaudeKey,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: config.claudeModel),
              onChanged: notifier.setClaudeModel,
            ),
          ],
          if (config.provider == AiProvider.openRouter) ...[
            Text('OpenRouter API Key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _openRouterKey,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: notifier.setOpenRouterKey,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _models.contains(config.openRouterModel) ? config.openRouterModel : (config.openRouterModel.isNotEmpty ? config.openRouterModel : null),
              items: [
                if (config.openRouterModel.isNotEmpty && !_models.contains(config.openRouterModel))
                  DropdownMenuItem(value: config.openRouterModel, child: Text(config.openRouterModel)),
                ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) {
                if (v != null) notifier.setOpenRouterModel(v);
              },
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (config.provider == AiProvider.custom) ...[
            Text('Base URL', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _customBaseUrl,
              decoration: const InputDecoration(
                hintText: 'http://localhost:8080',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setCustomBaseUrl,
            ),
            const SizedBox(height: 12),
            Text('API Key (optional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _customApiKey,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: notifier.setCustomApiKey,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _models.contains(config.customModel) ? config.customModel : (config.customModel.isNotEmpty ? config.customModel : null),
              items: [
                if (config.customModel.isNotEmpty && !_models.contains(config.customModel))
                  DropdownMenuItem(value: config.customModel, child: Text(config.customModel)),
                ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) {
                if (v != null) notifier.setCustomModel(v);
              },
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (config.provider == AiProvider.ollama) ...[
            Text('Ollama Base URL', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _ollamaUrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: notifier.setOllamaBaseUrl,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _models.contains(config.ollamaModel) ? config.ollamaModel : (config.ollamaModel.isNotEmpty ? config.ollamaModel : null),
              items: [
                if (config.ollamaModel.isNotEmpty && !_models.contains(config.ollamaModel))
                  DropdownMenuItem(value: config.ollamaModel, child: Text(config.ollamaModel)),
                ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) {
                if (v != null) notifier.setOllamaModel(v);
              },
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
