import 'package:flutter/material.dart';

/// ============================================================================
/// 限流范围（Throttle Scope）
///
/// 后端 429 响应中通过 message 区分：
///   - "请求过于频繁" → 速率限制
///   - "并发请求过多" → 并发限制
///   - "日配额已用完" → 日配额限制
///
/// 用于前端：
///   1. 实时展示限流状态徽标
///   2. 决定降级策略：速率限制 → 等待；并发限制 → 换 Key；日配额 → 跨 Provider
/// ============================================================================
enum ThrottleScope {
  /// 速率限制（每分钟过多请求，需等 1 分钟）
  rate,

  /// 并发限制（同时进行的请求过多，换 Key）
  concurrent,

  /// 日配额耗尽（今天用完了，跨 Provider 降级）
  daily,

  /// 未知 / 其他
  unknown,
}

extension ThrottleScopeX on ThrottleScope {
  String get label {
    switch (this) {
      case ThrottleScope.rate:
        return '速率限制';
      case ThrottleScope.concurrent:
        return '并发限制';
      case ThrottleScope.daily:
        return '日配额耗尽';
      case ThrottleScope.unknown:
        return '其他限流';
    }
  }

  /// 用于在 ApiKeyStatus 中转换的提示色
  Color get color {
    switch (this) {
      case ThrottleScope.rate:
        return Colors.orange;
      case ThrottleScope.concurrent:
        return Colors.deepOrange;
      case ThrottleScope.daily:
        return Colors.red;
      case ThrottleScope.unknown:
        return Colors.grey;
    }
  }

  /// 解析后端 message
  static ThrottleScope fromMessage(String? message) {
    if (message == null || message.isEmpty) return ThrottleScope.unknown;
    if (message.contains('请求过于频繁') || message.contains('rate')) {
      return ThrottleScope.rate;
    }
    if (message.contains('并发请求过多') || message.contains('concurrent')) {
      return ThrottleScope.concurrent;
    }
    if (message.contains('日配额已用完') || message.contains('quota')) {
      return ThrottleScope.daily;
    }
    return ThrottleScope.unknown;
  }
}

/// 限流事件（每次 429 响应记录）
class ThrottleEvent {
  final String keyId;
  final ThrottleScope scope;
  final String message;
  final DateTime occurredAt;

  /// 限流到期时间（估算）
  /// - rate: now + 60s
  /// - concurrent: now + 10s
  /// - daily: 隔天 0 点
  final DateTime? until;

  const ThrottleEvent({
    required this.keyId,
    required this.scope,
    required this.message,
    required this.occurredAt,
    this.until,
  });

  bool get isActive {
    if (until == null) return true;
    return DateTime.now().isBefore(until!);
  }

  Duration? get remaining {
    if (until == null) return null;
    final diff = until!.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  ThrottleEvent copyWith({
    String? keyId,
    ThrottleScope? scope,
    String? message,
    DateTime? occurredAt,
    DateTime? until,
  }) {
    return ThrottleEvent(
      keyId: keyId ?? this.keyId,
      scope: scope ?? this.scope,
      message: message ?? this.message,
      occurredAt: occurredAt ?? this.occurredAt,
      until: until ?? this.until,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'scope': scope.name,
      'message': message,
      'occurredAt': occurredAt.toIso8601String(),
      'until': until?.toIso8601String(),
    };
  }

  factory ThrottleEvent.fromJson(Map<String, dynamic> json) {
    return ThrottleEvent(
      keyId: json['keyId'] ?? '',
      scope: ThrottleScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => ThrottleScope.unknown,
      ),
      message: json['message'] ?? '',
      occurredAt: DateTime.parse(json['occurredAt']),
      until: json['until'] != null ? DateTime.tryParse(json['until']) : null,
    );
  }
}
