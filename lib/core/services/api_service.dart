import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:web_socket_channel/io.dart';
import '../models/ai_model_config.dart';
import '../models/realtime_transcription_result.dart';
import 'http_client.dart';
import 'transcription_service.dart';
import 'realtime_transcription_service.dart';
import 'text_analysis_service.dart';
import 'image_recognition_service.dart';
import 'stats_service.dart';
import 'storage_service.dart';

final sharedHttpClientProvider = Provider<HttpClient>((ref) => HttpClient());

final apiServiceProvider = Provider<ApiService>((ref) {
  final sharedClient = ref.read(sharedHttpClientProvider);
  return ApiService._shared(sharedClient);
});

class ApiService {
  final HttpClient _httpClient;
  final TranscriptionService _transcriptionService;
  final RealtimeTranscriptionService _realtimeTranscriptionService;
  final TextAnalysisService _textAnalysisService;
  final ImageRecognitionService _imageRecognitionService;

  ApiService()
      : _httpClient = HttpClient(),
        _transcriptionService = TranscriptionService(),
        _realtimeTranscriptionService = RealtimeTranscriptionService(),
        _textAnalysisService = TextAnalysisService(),
        _imageRecognitionService = ImageRecognitionService();

  ApiService._shared(HttpClient sharedClient)
      : _httpClient = sharedClient,
        _transcriptionService = TranscriptionService(httpClient: sharedClient),
        _realtimeTranscriptionService = RealtimeTranscriptionService(httpClient: sharedClient),
        _textAnalysisService = TextAnalysisService(httpClient: sharedClient),
        _imageRecognitionService = ImageRecognitionService(httpClient: sharedClient);

  bool get isConfigured => _httpClient.isConfigured;
  AiModelConfig? get currentConfig => _httpClient.currentConfig;
  HttpClient get httpClient => _httpClient;

  void configure({
    required String apiKey,
    required AiModelConfig config,
    String? customBaseUrl,
    String? appId,
    String? accessKeySecret,
  }) {
    _httpClient.configure(
      apiKey: apiKey,
      config: config,
      customBaseUrl: customBaseUrl,
      appId: appId,
      accessKeySecret: accessKeySecret,
    );
  }

  Future<bool> validateApiKey() async {
    return await _httpClient.validateApiKey();
  }

  Future<String> transcribeAudio(
    String audioFilePath, {
    String? model,
    void Function(String step, String detail)? onProgress,
    bool useChunking = true,
  }) async {
    return await _transcriptionService.transcribeAudio(
      audioFilePath,
      model: model,
      onProgress: onProgress,
      useChunking: useChunking,
    );
  }

  Stream<RealtimeTranscriptionResult> transcribeRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) {
    return _realtimeTranscriptionService.transcribeRealtime(
      audioStream: audioStream,
      onStatusChange: onStatusChange,
      language: language,
    );
  }

  Future<String> summarizeText(String text, {String? model}) async {
    return await _textAnalysisService.summarizeText(text, model: model);
  }

  Future<String> generateTitle(String text, {String? model}) async {
    return await _textAnalysisService.generateTitle(text, model: model);
  }

  Future<String> chatCompletion(String prompt, {String? model}) async {
    return await _textAnalysisService.chatCompletion(prompt, model: model);
  }

  Future<String> chatCompletionWithSystem(
    String prompt, {
    required String systemPrompt,
    String? model,
  }) async {
    return await _textAnalysisService.chatCompletionWithSystem(
      prompt,
      systemPrompt: systemPrompt,
      model: model,
    );
  }

  Future<String> recognizeImage(String imagePath, {String? model}) async {
    return await _imageRecognitionService.recognizeImage(imagePath, model: model);
  }

  // Legacy method for backward compatibility
  Future<String> completeChat(List<Map<String, String>> messages, {String? model}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;
    debugPrint('CompleteChat: provider=${config.name}, model=$useModel');

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持对话');
    }

    try {
      String result;

      switch (config.provider) {
        case AiProvider.claude:
          final data = <String, dynamic>{
            'model': useModel,
            'messages': messages.where((m) => m['role'] != 'system').toList(),
            'max_tokens': 4096,
          };
          final systemMsg = messages.firstWhere(
            (m) => m['role'] == 'system',
            orElse: () => {},
          );
          if (systemMsg.isNotEmpty) {
            data['system'] = systemMsg['content'];
          }
          final response = await _httpClient.post('/messages', data: data);
          result = response.data['content'][0]['text'];
          break;
        case AiProvider.gemini:
          final contents = messages
              .where((m) => m['role'] != 'system')
              .map((m) => {
                    'role': m['role'] == 'user' ? 'user' : 'model',
                    'parts': [
                      {'text': m['content']}
                    ],
                  })
              .toList();
          final data = <String, dynamic>{'contents': contents};
          final systemMsg = messages.firstWhere(
            (m) => m['role'] == 'system',
            orElse: () => {},
          );
          if (systemMsg.isNotEmpty) {
            data['systemInstruction'] = {
              'parts': [
                {'text': systemMsg['content']}
              ],
            };
          }
          final response = await _httpClient.post(
            '/models/$useModel:generateContent',
            queryParameters: {'key': _httpClient.apiKey},
            data: data,
          );
          result = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          break;
        default:
          final response = await _httpClient.post(
            '/chat/completions',
            data: {
              'model': useModel,
              'messages': messages,
            },
          );
          result = response.data['choices'][0]['message']['content'];
          break;
      }

      await StorageService.incrementUsageStat(
          config.name, 'chat',
          tokens: result.length);
      return result;
    } catch (e) {
      debugPrint('CompleteChat error: $e');
      rethrow;
    }
  }
}
