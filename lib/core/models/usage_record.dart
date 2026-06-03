import 'package:flutter/material.dart';

import 'api_key_pool.dart';

/// ============================================================================
/// 用量记录（UsageRecord）
///
/// 记录每日 API Key 的 Token 使用情况：
///   - 每条记录 = 一个 Key 在某一天的使用量
///   - 字段：日期、Key ID、Provider、消耗 Token 数、调用次数
///
/// 用途：
///   1. 展示每日/最近 7 天的用量趋势
///   2. 跨 Provider 对比
///   3. 异常用量检测（突增 3 倍报警）
/// ============================================================================
class UsageRecord {
  /// 唯一 ID（keyId_yyyyMMdd）
  final String id;

  /// 关联的 Key ID
  final String keyId;

  /// 关联的 Pool ID
  final String poolId;

  /// Provider 名称（用于显示）
  final String providerName;

  /// 日期（仅日期部分，HH:MM:SS 为 0）
  final DateTime date;

  /// 今日累计 Token 消耗
  final int tokensConsumed;

  /// 今日累计调用次数
  final int callCount;

  /// 今日成功次数
  final int successCount;

  /// 今日失败次数
  final int errorCount;

  /// 平均响应时间（ms）
  final int avgResponseTimeMs;

  const UsageRecord({
    required this.id,
    required this.keyId,
    required this.poolId,
    required this.providerName,
    required this.date,
    this.tokensConsumed = 0,
    this.callCount = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.avgResponseTimeMs = 0,
  });

  /// 计算成功率
  double get successRate {
    if (callCount == 0) return 1.0;
    return successCount / callCount;
  }

  /// 简化的当日标识（yyyy-MM-dd）
  String get dateLabel {
    final d = date;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  UsageRecord copyWith({
    String? id,
    String? keyId,
    String? poolId,
    String? providerName,
    DateTime? date,
    int? tokensConsumed,
    int? callCount,
    int? successCount,
    int? errorCount,
    int? avgResponseTimeMs,
  }) {
    return UsageRecord(
      id: id ?? this.id,
      keyId: keyId ?? this.keyId,
      poolId: poolId ?? this.poolId,
      providerName: providerName ?? this.providerName,
      date: date ?? this.date,
      tokensConsumed: tokensConsumed ?? this.tokensConsumed,
      callCount: callCount ?? this.callCount,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyId': keyId,
      'poolId': poolId,
      'providerName': providerName,
      'date': date.toIso8601String(),
      'tokensConsumed': tokensConsumed,
      'callCount': callCount,
      'successCount': successCount,
      'errorCount': errorCount,
      'avgResponseTimeMs': avgResponseTimeMs,
    };
  }

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      id: json['id'] ?? '',
      keyId: json['keyId'] ?? '',
      poolId: json['poolId'] ?? '',
      providerName: json['providerName'] ?? '',
      date: DateTime.parse(json['date']),
      tokensConsumed: (json['tokensConsumed'] as num?)?.toInt() ?? 0,
      callCount: (json['callCount'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      avgResponseTimeMs: (json['avgResponseTimeMs'] as num?)?.toInt() ?? 0,
    );
  }

  /// 从 ApiKeyEntry 的当日数据快速构造（用于本地聚合）
  factory UsageRecord.fromKeyEntry(ApiKeyEntry key, ApiKeyPool pool) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return UsageRecord(
      id: '${key.id}_${today.millisecondsSinceEpoch ~/ 86400000}',
      keyId: key.id,
      poolId: pool.id,
      providerName: pool.displayName,
      date: today,
      tokensConsumed: key.dailyUsage,
      callCount: key.successCount + key.errorCount,
      successCount: key.successCount,
      errorCount: key.errorCount,
      avgResponseTimeMs: 0,
    );
  }
}

/// ============================================================================
/// 用量统计聚合（按 Pool 维度）
/// ============================================================================
class PoolUsageSummary {
  final String poolId;
  final String poolName;
  final int totalTokens;
  final int totalCalls;
  final double avgSuccessRate;

  const PoolUsageSummary({
    required this.poolId,
    required this.poolName,
    required this.totalTokens,
    required this.totalCalls,
    required this.avgSuccessRate,
  });
}

/// ============================================================================
/// 趋势图数据点（用于 sparkline）
/// ============================================================================
class UsageTrendPoint {
  final DateTime date;
  final int tokens;

  const UsageTrendPoint({required this.date, required this.tokens});
}

/// 限流状态的颜色 helper
class UsageColors {
  static Color get healthy => Colors.green;
  static Color get warning => Colors.orange;
  static Color get danger => Colors.red;

  /// 根据用量占比返回颜色
  static Color colorForRatio(double ratio) {
    if (ratio >= 0.9) return danger;
    if (ratio >= 0.7) return warning;
    return healthy;
  }
}
