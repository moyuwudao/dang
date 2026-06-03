import 'package:dio/dio.dart';

import '../models/throttle_scope.dart';
import 'app_logger.dart';

/// ============================================================================
/// 限流响应解析器（A2 阶段新增）
///
/// 职责：
///   1. 拦截 DioException，识别 429 响应
///   2. 解析后端 message → ThrottleScope
///   3. 计算限流到期时间
///   4. 返回结构化的 ThrottleParseResult
///
/// 后端 429 响应格式（来自 cloud_api_service.dart 注释）：
///   {
///     "code": 429,
///     "message": "请求过于频繁" | "并发请求过多" | "日配额已用完",
///     "data": { ... }
///   }
///
/// 一些云端可能返回 Retry-After header，也会一并解析
/// ============================================================================
class ThrottleResponseParser {
  /// 解析 DioException，返回限流信息
  ///
  /// 如果不是 429 限流，返回 null
  static ThrottleParseResult? parse(DioException error) {
    final response = error.response;
    if (response == null) return null;
    if (response.statusCode != 429) return null;

    final now = DateTime.now();
    final data = response.data;
    String? message;
    Map<String, dynamic>? errorData;

    if (data is Map) {
      message = data['message']?.toString();
      if (data['data'] is Map) {
        errorData = Map<String, dynamic>.from(data['data'] as Map);
      }
    }

    // 1. 解析 scope
    final scope = ThrottleScopeX.fromMessage(message);

    // 2. 计算到期时间
    final retryAfter = _parseRetryAfter(response, errorData);
    final until = _computeUntil(now, scope, retryAfter);

    AppLogger().w('ThrottleParser',
        '限流: scope=${scope.name}, until=$until, msg=$message');

    return ThrottleParseResult(
      scope: scope,
      message: message ?? '请求过于频繁',
      occurredAt: now,
      until: until,
      retryAfterSeconds: retryAfter,
      rawData: errorData,
    );
  }

  /// 计算到期时间
  static DateTime? _computeUntil(
    DateTime now,
    ThrottleScope scope,
    int? retryAfter,
  ) {
    // 优先级：retryAfter header > scope 默认
    if (retryAfter != null && retryAfter > 0) {
      return now.add(Duration(seconds: retryAfter));
    }
    switch (scope) {
      case ThrottleScope.rate:
        // 速率限制：等 1 分钟
        return now.add(const Duration(minutes: 1));
      case ThrottleScope.concurrent:
        // 并发限制：等 10 秒（让其他请求完成）
        return now.add(const Duration(seconds: 10));
      case ThrottleScope.daily:
        // 日配额：到隔天 0 点
        return _nextMidnight(now);
      case ThrottleScope.unknown:
        // 未知：默认 30 秒
        return now.add(const Duration(seconds: 30));
    }
  }

  /// 解析 Retry-After header（秒数或日期）
  static int? _parseRetryAfter(
      Response<dynamic> response, Map<String, dynamic>? errorData) {
    // 优先看 header
    final header = response.headers.value('retry-after');
    if (header != null) {
      final n = int.tryParse(header);
      if (n != null) return n;
    }
    // 然后看 data
    if (errorData != null) {
      final v = errorData['retryAfter'] ?? errorData['retry_after'];
      if (v is num) return v.toInt();
    }
    return null;
  }

  /// 计算到下一个午夜的时长
  static DateTime _nextMidnight(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow;
  }
}

/// 限流解析结果
class ThrottleParseResult {
  final ThrottleScope scope;
  final String message;
  final DateTime occurredAt;
  final DateTime? until;
  final int? retryAfterSeconds;
  final Map<String, dynamic>? rawData;

  const ThrottleParseResult({
    required this.scope,
    required this.message,
    required this.occurredAt,
    this.until,
    this.retryAfterSeconds,
    this.rawData,
  });

  /// 是否仍然在限流
  bool get isActive {
    if (until == null) return true;
    return DateTime.now().isBefore(until!);
  }

  /// 剩余时间
  Duration? get remaining {
    if (until == null) return null;
    final diff = until!.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  /// 简短提示文案
  String get shortMessage {
    final remain = remaining;
    if (remain == null) {
      return scope.label;
    }
    if (remain.inSeconds < 60) {
      return '${scope.label}（${remain.inSeconds}秒）';
    }
    if (remain.inMinutes < 60) {
      return '${scope.label}（${remain.inMinutes}分钟）';
    }
    return '${scope.label}（${remain.inHours}小时）';
  }
}
