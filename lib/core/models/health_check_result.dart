import 'package:flutter/material.dart';

/// ============================================================================
/// 健康检查结果（HealthCheckResult）
///
/// 对应后端 ApiKeyService.performHealthCheck() 的返回。
/// 包含响应时间、状态、错误详情等。
///
/// 状态分类：
///   - healthy: 200 OK，响应时间 < 阈值
///   - slow: 200 OK，但响应时间过长
///   - throttled: 429
///   - error: 4xx/5xx
///   - timeout: 连接超时
/// ============================================================================
enum HealthStatus {
  /// 健康（200 OK + 响应时间正常）
  healthy,

  /// 响应慢（200 OK，但响应时间超过阈值）
  slow,

  /// 限流（429）
  throttled,

  /// 服务错误（5xx）
  serverError,

  /// 客户端错误（4xx 但非 429）
  clientError,

  /// 超时
  timeout,

  /// 网络错误（DNS、连接拒绝等）
  network,

  /// 未知错误
  unknown,
}

extension HealthStatusX on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.healthy:
        return '健康';
      case HealthStatus.slow:
        return '响应慢';
      case HealthStatus.throttled:
        return '限流';
      case HealthStatus.serverError:
        return '服务错误';
      case HealthStatus.clientError:
        return '参数错误';
      case HealthStatus.timeout:
        return '超时';
      case HealthStatus.network:
        return '网络错误';
      case HealthStatus.unknown:
        return '未知';
    }
  }

  Color get color {
    switch (this) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.slow:
        return Colors.lightGreen;
      case HealthStatus.throttled:
        return Colors.orange;
      case HealthStatus.serverError:
        return Colors.red;
      case HealthStatus.clientError:
        return Colors.deepOrange;
      case HealthStatus.timeout:
        return Colors.amber;
      case HealthStatus.network:
        return Colors.brown;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  /// 是否可用
  bool get isUsable {
    return this == HealthStatus.healthy || this == HealthStatus.slow;
  }

  /// 根据 status code + 响应时间推断状态
  static HealthStatus infer({
    required int? statusCode,
    required int responseTimeMs,
    required Object? error,
    int slowThresholdMs = 5000,
  }) {
    if (error != null) {
      final msg = error.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('超时')) {
        return HealthStatus.timeout;
      }
      if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('dns') ||
          msg.contains('connection')) {
        return HealthStatus.network;
      }
    }
    if (statusCode == null) {
      return HealthStatus.unknown;
    }
    if (statusCode == 429) return HealthStatus.throttled;
    if (statusCode >= 500) return HealthStatus.serverError;
    if (statusCode >= 400) return HealthStatus.clientError;
    if (statusCode >= 200 && statusCode < 300) {
      if (responseTimeMs > slowThresholdMs) return HealthStatus.slow;
      return HealthStatus.healthy;
    }
    return HealthStatus.unknown;
  }
}

/// 单个 Key 的一次健康检查结果
class HealthCheckResult {
  /// Key ID
  final String keyId;

  /// Pool ID
  final String poolId;

  /// 健康状态
  final HealthStatus status;

  /// HTTP 状态码
  final int? httpStatusCode;

  /// 响应时间（毫秒）
  final int responseTimeMs;

  /// 错误信息（如有）
  final String? errorMessage;

  /// 附加详情（来自后端）
  final Map<String, dynamic>? details;

  /// 检查时间
  final DateTime checkedAt;

  const HealthCheckResult({
    required this.keyId,
    required this.poolId,
    required this.status,
    required this.responseTimeMs,
    required this.checkedAt,
    this.httpStatusCode,
    this.errorMessage,
    this.details,
  });

  HealthCheckResult copyWith({
    String? keyId,
    String? poolId,
    HealthStatus? status,
    int? httpStatusCode,
    int? responseTimeMs,
    String? errorMessage,
    Map<String, dynamic>? details,
    DateTime? checkedAt,
  }) {
    return HealthCheckResult(
      keyId: keyId ?? this.keyId,
      poolId: poolId ?? this.poolId,
      status: status ?? this.status,
      httpStatusCode: httpStatusCode ?? this.httpStatusCode,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      details: details ?? this.details,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  /// 简短的展示
  String get displaySummary {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return '${status.label} (${responseTimeMs}ms) - $errorMessage';
    }
    return '${status.label} (${responseTimeMs}ms)';
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'poolId': poolId,
      'status': status.name,
      'httpStatusCode': httpStatusCode,
      'responseTimeMs': responseTimeMs,
      'errorMessage': errorMessage,
      'details': details,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      keyId: json['keyId'] ?? '',
      poolId: json['poolId'] ?? '',
      status: HealthStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => HealthStatus.unknown,
      ),
      httpStatusCode: (json['httpStatusCode'] as num?)?.toInt(),
      responseTimeMs: (json['responseTimeMs'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'],
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'])
          : null,
      checkedAt: DateTime.parse(json['checkedAt']),
    );
  }
}

/// 健康检查快照（用于 UI 批量展示）
class HealthCheckSnapshot {
  final List<HealthCheckResult> results;
  final DateTime generatedAt;
  final int totalKeys;
  final int healthyKeys;
  final int throttledKeys;
  final int errorKeys;

  const HealthCheckSnapshot({
    required this.results,
    required this.generatedAt,
    required this.totalKeys,
    required this.healthyKeys,
    required this.throttledKeys,
    required this.errorKeys,
  });

  factory HealthCheckSnapshot.fromResults(List<HealthCheckResult> results) {
    final healthy = results.where((r) => r.status == HealthStatus.healthy).length;
    final throttled =
        results.where((r) => r.status == HealthStatus.throttled).length;
    final errored = results
        .where((r) =>
            r.status == HealthStatus.serverError ||
            r.status == HealthStatus.clientError ||
            r.status == HealthStatus.timeout ||
            r.status == HealthStatus.network)
        .length;
    return HealthCheckSnapshot(
      results: results,
      generatedAt: DateTime.now(),
      totalKeys: results.length,
      healthyKeys: healthy,
      throttledKeys: throttled,
      errorKeys: errored,
    );
  }

  /// 健康率（0.0-1.0）
  double get healthRatio {
    if (totalKeys == 0) return 0.0;
    return healthyKeys / totalKeys;
  }
}
