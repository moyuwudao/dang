import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_model_config.dart';
import '../models/api_key_pool.dart';
import '../models/health_check_result.dart';
import '../models/throttle_scope.dart';
import 'app_logger.dart';
import 'cloud_api_service.dart';
import 'http_client.dart';

/// ============================================================================
/// HealthCheckService — API Key 健康检查服务（A2 阶段新增）
///
/// 策略：
///   1. 对云端配置的 Key（isCloudConfig=true）调用云端 /api-key/admin/:id/test
///   2. 对本地 Key，调用 /models 进行本地轻量测试
///   3. 解析 429 响应，更新限流状态
///   4. 返回 HealthCheckResult
///
/// 用途：
///   - 用户手动点击"测试连接"
///   - 定时轮询（5 分钟一次，可配置）
///   - 调用 429 后立即触发
/// ============================================================================
class HealthCheckService {
  // HealthCheckService 不需要 ref（通过 Provider 接收外部状态）
  HealthCheckService([_]);

  // 简单的 dio 缓存（避免每次重新创建）
  Dio? _dioCached;

  Dio _getDio() {
    return _dioCached ??= Dio(BaseOptions(
      baseUrl: 'http://101.133.238.249/api/v1',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          await CloudApiService.instance.initialize();
          final token = CloudApiService.instance.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ));
  }

  /// 对单个 Key 执行健康检查
  Future<HealthCheckResult> checkKey({
    required ApiKeyEntry key,
    required ApiKeyPool pool,
  }) async {
    // 云端配置的 Key 走云端测试
    if (pool.isCloudConfig) {
      return _checkViaCloud(key, pool);
    }
    // 本地 Key 走本地测试
    return _checkLocally(key, pool);
  }

  /// 批量健康检查（一个池）
  Future<List<HealthCheckResult>> checkPool(ApiKeyPool pool) async {
    final results = <HealthCheckResult>[];
    for (final key in pool.keys) {
      final result = await checkKey(key: key, pool: pool);
      results.add(result);
    }
    return results;
  }

  /// 检查所有池
  Future<List<HealthCheckResult>> checkAll(List<ApiKeyPool> pools) async {
    final results = <HealthCheckResult>[];
    for (final pool in pools) {
      results.addAll(await checkPool(pool));
    }
    return results;
  }

  // ============================================================================
  // 私有：云端测试
  // ============================================================================

  Future<HealthCheckResult> _checkViaCloud(
      ApiKeyEntry key, ApiKeyPool pool) async {
    final start = DateTime.now();
    try {
      await CloudApiService.instance.initialize();
      final response = await _getDio().post('/api-key/admin/${key.id}/test');
      final responseTime = _elapsedMs(start);
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        return HealthCheckResult(
          keyId: key.id,
          poolId: pool.id,
          status: HealthStatus.healthy,
          httpStatusCode: 200,
          responseTimeMs: responseTime,
          details: Map<String, dynamic>.from(data),
          checkedAt: DateTime.now(),
        );
      }
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatusX.infer(
          statusCode: response.statusCode,
          responseTimeMs: responseTime,
          error: null,
        ),
        httpStatusCode: response.statusCode,
        responseTimeMs: responseTime,
        errorMessage: data is Map ? data['message']?.toString() : null,
        checkedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final responseTime = _elapsedMs(start);
      if (code == 429) {
        final msg = _extractMessage(e.response?.data);
        return HealthCheckResult(
          keyId: key.id,
          poolId: pool.id,
          status: HealthStatus.throttled,
          httpStatusCode: 429,
          responseTimeMs: responseTime,
          errorMessage: msg,
          details: {
            'scope': ThrottleScopeX.fromMessage(msg).name,
            'message': msg,
          },
          checkedAt: DateTime.now(),
        );
      }
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatusX.infer(
          statusCode: code,
          responseTimeMs: responseTime,
          error: e,
        ),
        httpStatusCode: code,
        responseTimeMs: responseTime,
        errorMessage: e.message,
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger().w('HealthCheck', '云端测试异常: $e');
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatus.unknown,
        responseTimeMs: _elapsedMs(start),
        errorMessage: e.toString(),
        checkedAt: DateTime.now(),
      );
    }
  }

  // ============================================================================
  // 私有：本地回退测试
  // ============================================================================

  Future<HealthCheckResult> _checkLocally(
    ApiKeyEntry key,
    ApiKeyPool pool,
  ) async {
    final start = DateTime.now();
    final baseUrl = _baseUrlForProvider(pool);
    if (baseUrl == null) {
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatus.unknown,
        httpStatusCode: null,
        responseTimeMs: 0,
        errorMessage: '该 Provider 不支持本地测试',
        checkedAt: DateTime.now(),
      );
    }

    final client = HttpClient();
    client.configure(
      apiKey: key.apiKey,
      config: _configForProvider(pool.provider),
      customBaseUrl: key.baseUrl ?? baseUrl,
      appId: key.appId,
      accessKeySecret: key.accessKeySecret,
    );

    try {
      final response = await client.dio.get('/models');
      final responseTime = _elapsedMs(start);
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatusX.infer(
          statusCode: response.statusCode,
          responseTimeMs: responseTime,
          error: null,
        ),
        httpStatusCode: response.statusCode,
        responseTimeMs: responseTime,
        details: response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : null,
        checkedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      final responseTime = _elapsedMs(start);
      final code = e.response?.statusCode;
      final message = e.message;
      if (code == 429) {
        final msg = _extractMessage(e.response?.data) ?? message;
        return HealthCheckResult(
          keyId: key.id,
          poolId: pool.id,
          status: HealthStatus.throttled,
          httpStatusCode: 429,
          responseTimeMs: responseTime,
          errorMessage: msg,
          details: {
            'scope': ThrottleScopeX.fromMessage(msg).name,
            'message': msg,
          },
          checkedAt: DateTime.now(),
        );
      }
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatusX.infer(
          statusCode: code,
          responseTimeMs: responseTime,
          error: e,
        ),
        httpStatusCode: code,
        responseTimeMs: responseTime,
        errorMessage: message,
        checkedAt: DateTime.now(),
      );
    } on SocketException catch (e) {
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatus.network,
        responseTimeMs: _elapsedMs(start),
        errorMessage: e.message,
        checkedAt: DateTime.now(),
      );
    } on TimeoutException catch (e) {
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatus.timeout,
        responseTimeMs: _elapsedMs(start),
        errorMessage: e.message ?? 'Timeout',
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      return HealthCheckResult(
        keyId: key.id,
        poolId: pool.id,
        status: HealthStatus.unknown,
        responseTimeMs: _elapsedMs(start),
        errorMessage: e.toString(),
        checkedAt: DateTime.now(),
      );
    }
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  int _elapsedMs(DateTime start) {
    return DateTime.now().difference(start).inMilliseconds;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'];
      if (msg is String) return msg;
    }
    return null;
  }

  String? _baseUrlForProvider(ApiKeyPool pool) {
    // 通义听悟、ernie 等不一定有 /models
    switch (pool.provider) {
      case AiProvider.tingwu:
        return null;
      case AiProvider.openAI:
        return 'https://api.openai.com/v1';
      case AiProvider.deepSeek:
        return 'https://api.deepseek.com/v1';
      case AiProvider.grok:
        return 'https://api.x.ai/v1';
      case AiProvider.qwen:
        return 'https://dashscope.aliyuncs.com/compatible-mode/v1';
      case AiProvider.claude:
        return 'https://api.anthropic.com/v1';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AiProvider.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4';
      case AiProvider.kimi:
        return 'https://api.moonshot.cn/v1';
      case AiProvider.spark:
        return 'https://spark-api-open.xf-yun.com/v1';
      case AiProvider.ernie:
        return 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1';
      case AiProvider.custom:
        return AiModelConfig.getConfig(pool.provider).baseUrl;
    }
  }

  AiModelConfig _configForProvider(AiProvider provider) {
    // 简化：使用默认 model
    return AiModelConfig.getConfig(provider);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  return HealthCheckService();
});
