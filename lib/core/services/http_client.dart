import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_model_config.dart';
import '../utils/aliyun_signer.dart';
import 'app_logger.dart';

class HttpClient {
  late Dio _dio;
  AiModelConfig? _currentConfig;
  String? _apiKey;
  String? _appId;
  String? _accessKeySecret;
  // 修复 Issue 2：记录当前模型的 multiplier（来自云端 apiPolicies 或本地 baseCoefficient）
  // 用于 TextAnalysisService 等计费检查时按真实系数预估消耗
  double _currentMultiplier = 1.0;
  bool _isConfigured = false;
  bool _isCloudConfig = false;
  // 使用量报告回调（由外部设置，避免循环依赖）
  void Function({required String provider, required String model,
    required int promptTokens, required int completionTokens})? onUsageReport;

  HttpClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 300),
        sendTimeout: const Duration(seconds: 180),
      ),
    );
  }

  bool get isConfigured =>
      _isConfigured && _currentConfig != null && _apiKey != null;

  AiModelConfig? get currentConfig => _currentConfig;
  String? get apiKey => _apiKey;
  String? get appId => _appId;
  String? get accessKeySecret => _accessKeySecret;
  /// 修复 Issue 2：当前模型的计费系数（DEEPSEEK 0.5x、QWEN-Max 3x 等）
  double get currentMultiplier => _currentMultiplier;
  bool get isCloudConfig => _isCloudConfig;
  Dio get dio => _dio;

  String get configInfo {
    if (_currentConfig == null) return 'Not configured';
    return 'provider=${_currentConfig!.name}, baseUrl=${_dio.options.baseUrl}, model=${_currentConfig!.defaultModel}';
  }

  void configure({
    required String apiKey,
    required AiModelConfig config,
    String? customBaseUrl,
    String? appId,
    String? accessKeySecret,
    double multiplier = 1.0,
    bool isCloudConfig = true,
  }) {
    _currentConfig = config;
    _apiKey = apiKey;
    _appId = appId;
    _accessKeySecret = accessKeySecret;
    _currentMultiplier = multiplier;
    _isCloudConfig = isCloudConfig;
    _isConfigured = true;
    final baseUrl = customBaseUrl ?? config.baseUrl;

    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = _buildHeaders(config, apiKey);
  }

  Map<String, String> _buildHeaders(AiModelConfig config, String apiKey) {
    switch (config.provider) {
      case AiProvider.openAI:
      case AiProvider.deepSeek:
      case AiProvider.grok:
      case AiProvider.qwen:
      case AiProvider.zhipu:
      case AiProvider.kimi:
      case AiProvider.spark:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case AiProvider.claude:
        return {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
      case AiProvider.gemini:
        return {
          'Content-Type': 'application/json',
        };
      case AiProvider.ernie:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case AiProvider.custom:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case AiProvider.tingwu:
        // 通义听悟使用阿里云签名，不在 header 中使用 Bearer token
        return {
          'Content-Type': 'application/json',
        };
    }
  }

  String extractDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      if (response.data != null) {
        try {
          if (response.data is Map) {
            final error = response.data['error'];
            if (error is Map) {
              return error['message'] ??
                  error['code']?.toString() ??
                  response.data.toString();
            }
            return response.data['message'] ?? response.data.toString();
          }
          return response.data.toString();
        } catch (_) {
          return response.statusMessage ?? e.message ?? 'Unknown error';
        }
      }
    }
    return e.message ?? 'Network error';
  }

  Future<bool> validateApiKey() async {
    if (!isConfigured) {
      return false;
    }

    try {
      Response response;
      switch (_currentConfig!.provider) {
        case AiProvider.gemini:
          response = await _dio.get(
            '/models',
            queryParameters: {'key': _apiKey},
          );
          break;
        case AiProvider.tingwu:
          // 通义听悟没有 /models 端点，使用签名调用 /openapi/tingwu/v2/tasks 验证凭证
          response = await _validateTingwuApiKey();
          break;
        default:
          response = await _dio.get('/models');
          break;
      }
      // 通义听悟返回 400 表示签名正确（缺少 FileUrl），也视为验证成功
      return response.statusCode == 200 ||
          (_currentConfig!.provider == AiProvider.tingwu &&
              response.statusCode == 400);
    } on DioException catch (e) {
      AppLogger().e('HttpClient', 'API validation error: ${extractDioError(e)}');
      return false;
    } catch (e) {
      AppLogger().e('HttpClient', 'API validation error: $e');
      return false;
    }
  }

  /// 验证通义听悟 API 凭证
  ///
  /// 使用 V2 ROA 签名机制调用通义听悟 API 验证凭证
  /// 返回 200/400 表示签名正确、凭证有效
  /// 返回 403/401 表示签名错误或凭证无效
  Future<Response> _validateTingwuApiKey() async {
    if (_accessKeySecret == null || _accessKeySecret!.isEmpty) {
      throw Exception('通义听悟需要 AccessKey Secret');
    }
    if (_appId == null || _appId!.isEmpty) {
      throw Exception('通义听悟需要 AppKey');
    }

    final signer = AliyunSigner(
      accessKeyId: _apiKey!,
      accessKeySecret: _accessKeySecret!,
    );

    final path = '/openapi/tingwu/v2/tasks';
    final queryParams = {'type': 'offline'};

    final testBody = jsonEncode({
      'AppKey': _appId!,
      'Input': {
        'SourceLanguage': 'cn',
        'TaskKey': 'test_${DateTime.now().millisecondsSinceEpoch}',
      },
    });

    final signedHeaders = signer.signRoaRequest(
      method: 'PUT',
      path: path,
      queryParams: queryParams,
      body: testBody,
    );

    try {
      final dio = Dio();
      final url = '${_dio.options.baseUrl}$path';
      return await dio.put(
        url,
        data: testBody,
        queryParameters: queryParams,
        options: Options(headers: signedHeaders),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return e.response!;
      }
      rethrow;
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );

    // 自动从 /chat/completions 响应中提取 usage 并报告计费
    _tryReportUsage(path, response.data, data);

    return response;
  }

  /// 从 API 响应中提取 usage 并触发计费报告回调
  ///
  /// 支持的路径：
  ///   /chat/completions  → OpenAI/DeepSeek/Qwen 等，响应含 usage 字段
  ///   /messages          → Claude，响应无 usage，需估算
  ///   :generateContent   → Gemini，响应无 usage，需估算
  ///   /audio/transcriptions → Whisper，响应无 usage，需估算
  void _tryReportUsage(String path, dynamic responseData, dynamic requestData) {
    if (!_isCloudConfig || onUsageReport == null) return;
    try {
      // 匹配所有 AI API 路径
      final isAiPath = path.contains('/chat/completions') ||
          path.contains('/messages') ||
          path.contains(':generateContent') ||
          path.contains('/audio/transcriptions');
      if (!isAiPath) return;
      if (responseData is! Map) return;

      int promptTokens = 0;
      int completionTokens = 0;

      // 优先从响应中提取实际 usage（OpenAI/DeepSeek/Qwen chat）
      final usage = responseData['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        promptTokens = (usage['prompt_tokens'] as num?)?.toInt() ?? 0;
        completionTokens = (usage['completion_tokens'] as num?)?.toInt() ?? 0;
      }

      // 无 usage 字段时，从响应内容估算 Token（~4 字符/Token）
      if (promptTokens + completionTokens <= 0) {
        completionTokens = _estimateTokensFromResponse(responseData);
        promptTokens = _estimateTokensFromRequest(requestData);
      }

      if (promptTokens + completionTokens <= 0) return;

      // 从请求中提取 model
      String model = '';
      if (requestData is Map<String, dynamic>) {
        model = requestData['model'] as String? ?? '';
      }
      // 从响应中提取 model（更准确）
      model = (responseData['model'] as String?) ?? model;

      final provider = _currentConfig?.name ?? 'unknown';
      onUsageReport!(
        provider: provider,
        model: model,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
      );
    } catch (e) {
      AppLogger().w('HttpClient', '提取usage失败: $e');
    }
  }

  /// 从响应内容估算 Token 数（~4 字符/Token）
  int _estimateTokensFromResponse(Map responseData) {
    String text = '';

    // OpenAI 格式: choices[0].message.content
    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final message = (choices[0] as Map?)?['message'] as Map?;
      text = message?['content'] as String? ?? '';
    }

    // Claude 格式: content[0].text
    if (text.isEmpty) {
      final content = responseData['content'] as List?;
      if (content != null && content.isNotEmpty) {
        text = (content[0] as Map?)?['text'] as String? ?? '';
      }
    }

    // Gemini 格式: candidates[0].content.parts[0].text
    if (text.isEmpty) {
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = ((candidates[0] as Map?)?['content'] as Map?)?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          text = (parts[0] as Map?)?['text'] as String? ?? '';
        }
      }
    }

    // Whisper 格式: text
    if (text.isEmpty) {
      text = responseData['text'] as String? ?? '';
    }

    return (text.length / 4).ceil();
  }

  /// 从请求内容估算 prompt Token 数（~4 字符/Token）
  int _estimateTokensFromRequest(dynamic requestData) {
    if (requestData is! Map<String, dynamic>) return 0;

    // chat/completions 格式: messages[].content
    final messages = requestData['messages'] as List?;
    if (messages != null) {
      int totalChars = 0;
      for (final msg in messages) {
        if (msg is Map) {
          final content = msg['content'];
          if (content is String) {
            totalChars += content.length;
          } else if (content is List) {
            // 多模态消息（如图片识别）
            for (final part in content) {
              if (part is Map) {
                final text = part['text'];
                if (text is String) totalChars += text.length;
              }
            }
          }
        }
      }
      return (totalChars / 4).ceil();
    }

    // Claude /messages 格式: 同上
    // Gemini :generateContent 格式: contents[].parts[].text
    final contents = requestData['contents'] as List?;
    if (contents != null) {
      int totalChars = 0;
      for (final content in contents) {
        if (content is Map) {
          final parts = content['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map) {
                final text = part['text'];
                if (text is String) totalChars += text.length;
              }
            }
          }
        }
      }
      return (totalChars / 4).ceil();
    }

    return 0;
  }

  Future<Response<T>> postStream<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  void clear() {
    _currentConfig = null;
    _apiKey = null;
    _appId = null;
    _accessKeySecret = null;
    _isConfigured = false;
    _isCloudConfig = false;
    _dio.options.baseUrl = '';
    _dio.options.headers = {};
  }
}
