import 'dart:convert';
import '../models/ai_model_config.dart';
import 'app_logger.dart';
import 'http_client.dart';
import 'storage_service.dart';
import 'billing_service.dart';

class TextAnalysisService {
  final HttpClient _httpClient;
  final BillingService? _billingService;

  TextAnalysisService({HttpClient? httpClient, BillingService? billingService})
      : _httpClient = httpClient ?? HttpClient(),
        _billingService = billingService;

  bool get isConfigured => _httpClient.isConfigured;

  Future<String> summarizeText(String text, {String? model}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 计费检查
    if (_billingService != null) {
      final canUse = await _billingService!.canUseFeature(
        FeatureType.textAnalysis,
        text.length / 1000,
      );
      if (!canUse) {
        throw Exception('文本分析配额不足，请充值或升级套餐');
      }
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持文本分析');
    }

    try {
      String result;

      switch (config.provider) {
        case AiProvider.claude:
          result = await _claudeChat(
            model: useModel,
            systemPrompt:
                'Summarize the following content into a todo list. Use the language of the content.',
            userContent: text,
          );
          break;
        case AiProvider.gemini:
          result = await _geminiChat(
            model: useModel,
            prompt:
                'Summarize the following content into a todo list. Use the language of the content.\n\n$text',
          );
          break;
        default:
          result = await _openAIStyleChat(
            model: useModel,
            systemPrompt:
                'Summarize the following content into a todo list. Use the language of the content.',
            userContent: text,
          );
          break;
      }

      // 计费扣减
      if (_billingService != null) {
        await _billingService!.consumeFeature(
          FeatureType.textAnalysis,
          (text.length + result.length) / 1000,
          provider: config.provider.name,
          model: useModel,
        );
      }

      await StorageService.incrementUsageStat(
          config.name, 'text_analysis',
          tokens: result.length);
      return result;
    } catch (e) {
      AppLogger().e('TextAnalysis', 'SummarizeText error: $e');
      rethrow;
    }
  }

  Future<String> generateTitle(String text, {String? model}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 计费检查
    if (_billingService != null) {
      final canUse = await _billingService!.canUseFeature(
        FeatureType.textAnalysis,
        text.length / 1000,
      );
      if (!canUse) {
        throw Exception('文本分析配额不足，请充值或升级套餐');
      }
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持文本分析');
    }

    try {
      String result;

      switch (config.provider) {
        case AiProvider.claude:
          result = await _claudeChat(
            model: useModel,
            systemPrompt:
                'Generate a concise title for the following content. Use the language of the content.',
            userContent: text,
          );
          break;
        case AiProvider.gemini:
          result = await _geminiChat(
            model: useModel,
            prompt:
                'Generate a concise title for the following content. Use the language of the content.\n\n$text',
          );
          break;
        default:
          result = await _openAIStyleChat(
            model: useModel,
            systemPrompt:
                'Generate a concise title for the following content. Use the language of the content.',
            userContent: text,
          );
          break;
      }

      // 计费扣减
      if (_billingService != null) {
        await _billingService!.consumeFeature(
          FeatureType.textAnalysis,
          (text.length + result.length) / 1000,
          provider: config.provider.name,
          model: useModel,
        );
      }

      await StorageService.incrementUsageStat(
          config.name, 'text_analysis',
          tokens: result.length);
      return result;
    } catch (e) {
      AppLogger().e('TextAnalysis', 'GenerateTitle error: $e');
      rethrow;
    }
  }

  Future<String> chatCompletion(String prompt, {String? model}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 计费检查
    if (_billingService != null) {
      final canUse = await _billingService!.canUseFeature(
        FeatureType.aiChat,
        prompt.length / 1000,
      );
      if (!canUse) {
        throw Exception('AI对话配额不足，请充值或升级套餐');
      }
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持对话');
    }

    try {
      String result;

      switch (config.provider) {
        case AiProvider.claude:
          result = await _claudeChat(
            model: useModel,
            userContent: prompt,
          );
          break;
        case AiProvider.gemini:
          result = await _geminiChat(
            model: useModel,
            prompt: prompt,
          );
          break;
        default:
          result = await _openAIStyleChat(
            model: useModel,
            userContent: prompt,
          );
          break;
      }

      // 计费扣减
      if (_billingService != null) {
        await _billingService!.consumeFeature(
          FeatureType.aiChat,
          (prompt.length + result.length) / 1000,
          provider: config.provider.name,
          model: useModel,
        );
      }

      await StorageService.incrementUsageStat(
          config.name, 'chat',
          tokens: result.length);
      return result;
    } catch (e) {
      AppLogger().e('TextAnalysis', 'ChatCompletion error: $e');
      rethrow;
    }
  }

  Future<String> chatCompletionWithSystem(
    String prompt, {
    required String systemPrompt,
    String? model,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 计费检查
    if (_billingService != null) {
      final canUse = await _billingService!.canUseFeature(
        FeatureType.aiChat,
        (prompt.length + systemPrompt.length) / 1000,
      );
      if (!canUse) {
        throw Exception('AI对话配额不足，请充值或升级套餐');
      }
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持对话');
    }

    try {
      String result;

      switch (config.provider) {
        case AiProvider.claude:
          result = await _claudeChat(
            model: useModel,
            systemPrompt: systemPrompt,
            userContent: prompt,
          );
          break;
        case AiProvider.gemini:
          result = await _geminiChat(
            model: useModel,
            prompt: prompt,
            systemPrompt: systemPrompt,
          );
          break;
        default:
          result = await _openAIStyleChat(
            model: useModel,
            systemPrompt: systemPrompt,
            userContent: prompt,
          );
          break;
      }

      // 计费扣减
      if (_billingService != null) {
        await _billingService!.consumeFeature(
          FeatureType.aiChat,
          (prompt.length + systemPrompt.length + result.length) / 1000,
          provider: config.provider.name,
          model: useModel,
        );
      }

      await StorageService.incrementUsageStat(
          config.name, 'chat',
          tokens: result.length);
      return result;
    } catch (e) {
      AppLogger().e('TextAnalysis', 'ChatCompletionWithSystem error: $e');
      rethrow;
    }
  }

  Future<String> _openAIStyleChat({
    required String model,
    String? systemPrompt,
    required String userContent,
  }) async {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    messages.add({'role': 'user', 'content': userContent});

    final response = await _httpClient.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': messages,
      },
    );

    return response.data['choices'][0]['message']['content'];
  }

  Future<String> _claudeChat({
    required String model,
    String? systemPrompt,
    required String userContent,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': userContent},
    ];

    final data = <String, dynamic>{
      'model': model,
      'messages': messages,
      'max_tokens': 4096,
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      data['system'] = systemPrompt;
    }

    final response = await _httpClient.post(
      '/messages',
      data: data,
    );

    return response.data['content'][0]['text'];
  }

  Future<String> _geminiChat({
    required String model,
    required String prompt,
    String? systemPrompt,
  }) async {
    final contents = <Map<String, dynamic>>[
      {
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    final data = <String, dynamic>{
      'contents': contents,
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      data['systemInstruction'] = {
        'parts': [
          {'text': systemPrompt},
        ],
      };
    }

    final response = await _httpClient.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _httpClient.apiKey},
      data: data,
    );

    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';
  }
}
