import 'package:dio/dio.dart';
import '../../../providers/ai_engine_provider.dart';

class AIChatService {
  AIChatService(this.config);

  final AiEngineConfig config;
  final _dio = Dio();

  Future<List<String>> fetchModels() async {
    switch (config.provider) {
      case AiProvider.openAi:
        return _fetchOpenAIModels();
      case AiProvider.openRouter:
        return _fetchOpenRouterModels();
      case AiProvider.custom:
        return _fetchCustomModels();
      case AiProvider.ollama:
        return _fetchOllamaModels();
      case AiProvider.claude:
        return [];
    }
  }

  Future<String> sendMessage(String message, {List<Map<String, String>> history = const []}) async {
    switch (config.provider) {
      case AiProvider.openAi:
        return _sendOpenAI(message, history);
      case AiProvider.claude:
        return _sendClaude(message, history);
      case AiProvider.openRouter:
        return _sendOpenRouter(message, history);
      case AiProvider.custom:
        return _sendCustom(message, history);
      case AiProvider.ollama:
        return _sendOllama(message, history);
    }
  }

  Future<String> _sendOpenAI(String message, List<Map<String, String>> history) async {
    if (config.openAiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer ${config.openAiKey}',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': config.openAiModel,
        'messages': messages,
        'temperature': 0.7,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _sendClaude(String message, List<Map<String, String>> history) async {
    if (config.claudeKey.isEmpty) {
      throw Exception('Claude API key not configured');
    }
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(headers: {
        'x-api-key': config.claudeKey,
        'anthropic-version': '2023-06-13',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': config.claudeModel,
        'max_tokens': 1024,
        'messages': messages,
      },
    );
    final content = response.data['content'] as List;
    return content[0]['text'] as String;
  }

  Future<String> _sendOpenRouter(String message, List<Map<String, String>> history) async {
    if (config.openRouterKey.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];
    final response = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer ${config.openRouterKey}',
        'HTTP-Referer': 'https://github.com/lemtrackai/lemontrackai',
        'X-Title': 'LemonTrack',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': config.openRouterModel,
        'messages': messages,
        'temperature': 0.7,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _sendCustom(String message, List<Map<String, String>> history) async {
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (config.customApiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.customApiKey}';
    }
    final baseUrl = config.customBaseUrl.endsWith('/')
        ? config.customBaseUrl.substring(0, config.customBaseUrl.length - 1)
        : config.customBaseUrl;
    final response = await _dio.post(
      '$baseUrl/v1/chat/completions',
      options: Options(headers: headers),
      data: {
        'model': config.customModel,
        'messages': messages,
        'temperature': 0.7,
        'stream': false,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<List<String>> _fetchOpenAIModels() async {
    if (config.openAiKey.isEmpty) return [];
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer ${config.openAiKey}'}),
      );
      final data = response.data['data'] as List;
      final models = data.map((e) => e['id'].toString()).toList();
      models.sort();
      return models;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _fetchOpenRouterModels() async {
    try {
      final response = await _dio.get('https://openrouter.ai/api/v1/models');
      final data = response.data['data'] as List;
      final models = data.map((e) => e['id'].toString()).toList();
      models.sort();
      return models;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _fetchCustomModels() async {
    try {
      final baseUrl = config.customBaseUrl.endsWith('/')
          ? config.customBaseUrl.substring(0, config.customBaseUrl.length - 1)
          : config.customBaseUrl;
      final headers = <String, dynamic>{};
      if (config.customApiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.customApiKey}';
      }
      final response = await _dio.get(
        '$baseUrl/v1/models',
        options: Options(headers: headers),
      );
      final data = response.data['data'] as List? ?? [];
      final models = data.map((e) => e['id'].toString()).toList();
      if (models.isEmpty) {
        // some servers just return list
        if (response.data is List) {
          return (response.data as List).map((e) => e.toString()).toList();
        }
      }
      models.sort();
      return models;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _fetchOllamaModels() async {
    try {
      final baseUrl = config.ollamaBaseUrl.endsWith('/')
          ? config.ollamaBaseUrl.substring(0, config.ollamaBaseUrl.length - 1)
          : config.ollamaBaseUrl;
      final response = await _dio.get('$baseUrl/api/tags');
      final models = response.data['models'] as List? ?? [];
      final names = models.map((e) => e['name'].toString()).toList();
      names.sort();
      return names;
    } catch (e) {
      return [];
    }
  }

  Future<String> _sendOllama(String message, List<Map<String, String>> history) async {
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];
    final baseUrl = config.ollamaBaseUrl.endsWith('/')
        ? config.ollamaBaseUrl.substring(0, config.ollamaBaseUrl.length - 1)
        : config.ollamaBaseUrl;
    final response = await _dio.post(
      '$baseUrl/v1/chat/completions',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'model': config.ollamaModel,
        'messages': messages,
        'stream': false,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }
}
