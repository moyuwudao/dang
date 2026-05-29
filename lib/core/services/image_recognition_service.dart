import 'dart:convert';
import 'dart:io';
import '../models/ai_model_config.dart';
import 'http_client.dart';
import 'app_logger.dart';
import 'storage_service.dart';
import 'billing_service.dart';

class ImageRecognitionService {
  final HttpClient _httpClient;
  final BillingService? _billingService;

  ImageRecognitionService({HttpClient? httpClient, BillingService? billingService})
      : _httpClient = httpClient ?? HttpClient(),
        _billingService = billingService;

  bool get isConfigured => _httpClient.isConfigured;

  Future<String> recognizeImage(String imagePath, {String? model}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 计费检查
    if (_billingService != null) {
      final canUse = await _billingService!.canUseFeature(
        FeatureType.imageRecognition,
        1,
      );
      if (!canUse) {
        throw Exception('图像识别配额不足，请充值或升级套餐');
      }
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.visionModel;

    if (!config.supportsOCR) {
      throw Exception('${config.displayName} 不支持图像识别');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('图片文件不存在: $imagePath');
    }

    try {
      final imageBytes = await file.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      String result;

      switch (config.provider) {
        case AiProvider.openAI:
        case AiProvider.deepSeek:
        case AiProvider.grok:
        case AiProvider.qwen:
        case AiProvider.zhipu:
        case AiProvider.kimi:
        case AiProvider.spark:
        case AiProvider.custom:
          result = await _openAIStyleRecognizeImage(
            base64Image,
            model: useModel,
          );
          break;
        case AiProvider.claude:
          result = await _claudeRecognizeImage(
            base64Image,
            model: useModel,
          );
          break;
        case AiProvider.gemini:
          result = await _geminiRecognizeImage(
            base64Image,
            model: useModel,
          );
          break;
        case AiProvider.ernie:
          throw Exception('${config.displayName} 暂不支持图像识别');
        case AiProvider.tingwu:
          throw Exception('${config.displayName} 不支持图像识别');
      }

      // 计费扣减
      if (_billingService != null) {
        await _billingService!.consumeFeature(
          FeatureType.imageRecognition,
          1,
          provider: config.provider.name,
          model: useModel,
        );
      }

      await StorageService.incrementUsageStat(
          config.name, 'image_recognition',
          tokens: result.length);
      return result;
    } catch (e) {
      AppLogger().e('ImageRecognition', 'RecognizeImage error: $e');
      rethrow;
    }
  }

  Future<String> _openAIStyleRecognizeImage(
    String base64Image, {
    required String model,
  }) async {
    final response = await _httpClient.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    '请识别这张图片中的文字内容。如果图片中没有文字，请描述图片内容。'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
      },
    );

    return response.data['choices'][0]['message']['content'];
  }

  Future<String> _claudeRecognizeImage(
    String base64Image, {
    required String model,
  }) async {
    final response = await _httpClient.post(
      '/messages',
      data: {
        'model': model,
        'max_tokens': 4096,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text':
                    '请识别这张图片中的文字内容。如果图片中没有文字，请描述图片内容。'
              },
            ],
          },
        ],
      },
    );

    return response.data['content'][0]['text'];
  }

  Future<String> _geminiRecognizeImage(
    String base64Image, {
    required String model,
  }) async {
    final response = await _httpClient.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _httpClient.apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text':
                    '请识别这张图片中的文字内容。如果图片中没有文字，请描述图片内容。'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
      },
    );

    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';
  }
}
