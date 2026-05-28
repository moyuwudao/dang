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
  bool _isConfigured = false;

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
  }) {
    _currentConfig = config;
    _apiKey = apiKey;
    _appId = appId;
    _accessKeySecret = accessKeySecret;
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
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
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
    _dio.options.baseUrl = '';
    _dio.options.headers = {};
  }
}
