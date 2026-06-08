import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/app_logger.dart';
import '../../auth/providers/auth_provider.dart';

/// ============================================================================
/// 云端用量统计 Provider
///
/// 职责：
///   1. 从服务端 GET /ai/usage 获取计费用量数据
///   2. 本地缓存，5分钟内不重复请求
///   3. 手动刷新
///   4. 未登录时返回空数据
/// ============================================================================

/// 单条云端用量记录
class CloudUsageRecord {
  final String id;
  final String provider;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int tokenConsumed; // 计费消耗量（已乘系数）
  final double apiCoefficient;
  final double? costYuan;
  final DateTime createdAt;

  const CloudUsageRecord({
    required this.id,
    required this.provider,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.tokenConsumed,
    required this.apiCoefficient,
    this.costYuan,
    required this.createdAt,
  });

  /// 防御性解析 num：PostgreSQL numeric 类型序列化为字符串（如 "1298.0000"）
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.split('.').first) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory CloudUsageRecord.fromJson(Map<String, dynamic> json) {
    return CloudUsageRecord(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      model: json['model'] as String? ?? '',
      promptTokens: _parseInt(json['promptTokens']),
      completionTokens: _parseInt(json['completionTokens']),
      tokenConsumed: _parseInt(json['tokenConsumed']),
      apiCoefficient: _parseDouble(json['apiCoefficient']),
      costYuan: json['costYuan'] != null ? _parseDouble(json['costYuan']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 原始 Token 数（不含系数）
  int get rawTokens => promptTokens + completionTokens;
}

/// 云端用量汇总
class CloudUsageSummary {
  final int totalCalls;
  final int totalTokens; // 原始 Token
  final int totalQuotaConsumed; // 计费 Token（含系数）
  final List<CloudUsageRecord> logs;
  final DateTime? fetchedAt;

  const CloudUsageSummary({
    this.totalCalls = 0,
    this.totalTokens = 0,
    this.totalQuotaConsumed = 0,
    this.logs = const [],
    this.fetchedAt,
  });

  /// 按 Provider 聚合
  Map<String, ProviderCloudStats> byProvider() {
    final map = <String, ProviderCloudStats>{};
    for (final log in logs) {
      final stats = map.putIfAbsent(log.provider,
          () => ProviderCloudStats(provider: log.provider));
      stats.calls++;
      stats.rawTokens += log.rawTokens;
      stats.billedTokens += log.tokenConsumed;
      stats.totalCost = (stats.totalCost ?? 0) + (log.costYuan ?? 0);
    }
    return map;
  }

  /// 按日期聚合（最近7天）
  Map<DateTime, int> dailyBilledTokens() {
    final map = <DateTime, int>{};
    for (final log in logs) {
      final date = DateTime(
          log.createdAt.year, log.createdAt.month, log.createdAt.day);
      map[date] = (map[date] ?? 0) + log.tokenConsumed;
    }
    return map;
  }
}

/// 云端 Provider 统计
class ProviderCloudStats {
  final String provider;
  int calls = 0;
  int rawTokens = 0;
  int billedTokens = 0;
  double? totalCost;

  ProviderCloudStats({required this.provider});
}

/// 云端用量状态
class CloudUsageState {
  final CloudUsageSummary summary;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchedAt;
  final DateTime? lastFailedAt; // 上次失败时间（用于节流防循环重试）

  const CloudUsageState({
    this.summary = const CloudUsageSummary(),
    this.isLoading = false,
    this.error,
    this.lastFetchedAt,
    this.lastFailedAt,
  });

  CloudUsageState copyWith({
    CloudUsageSummary? summary,
    bool? isLoading,
    String? error,
    DateTime? lastFetchedAt,
    DateTime? lastFailedAt,
  }) {
    return CloudUsageState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
    );
  }

  /// 是否需要刷新（5分钟缓存）
  bool get needsRefresh {
    if (lastFetchedAt == null) return true;
    return DateTime.now().difference(lastFetchedAt!).inMinutes >= 5;
  }
}

/// ============================================================================
/// Notifier
/// ============================================================================
class CloudUsageNotifier extends StateNotifier<CloudUsageState> {
  static const String _cacheKey = 'cloud_usage_cache_v1';
  static const Duration _cacheDuration = Duration(minutes: 5);

  CloudUsageNotifier() : super(const CloudUsageState());

  /// 获取云端用量（自动判断是否需要刷新）
  Future<void> fetchIfNeeded() async {
    if (!state.needsRefresh && state.summary.logs.isNotEmpty) return;
    await fetch(force: false);
  }

  /// 强制刷新
  Future<void> fetch({bool force = true}) async {
    if (state.isLoading) return;

    // 非强制模式下，5分钟内不重复请求
    if (!force && !state.needsRefresh && state.summary.logs.isNotEmpty) return;

    // 防循环节流：60 秒内失败过则不重试（除非 force）
    if (!force && state.lastFailedAt != null) {
      final sinceFail = DateTime.now().difference(state.lastFailedAt!);
      if (sinceFail.inSeconds < 60) {
        AppLogger().w('CloudUsage', '60秒内已失败，跳过重试 (距上次失败 ${sinceFail.inSeconds}s)');
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7)).toIso8601String();

      final response = await CloudApiService.instance.get(
        '/ai/usage',
        queryParameters: {'startDate': startDate},
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        state = state.copyWith(
          isLoading: false,
          error: '响应数据为空',
          lastFailedAt: DateTime.now(),
        );
        return;
      }

      final logs = (data['logs'] as List<dynamic>?)
              ?.map((e) =>
                  CloudUsageRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final summary = CloudUsageSummary(
        totalCalls: CloudUsageRecord._parseInt(data['totalCalls']),
        totalTokens: CloudUsageRecord._parseInt(data['totalTokens']),
        totalQuotaConsumed: CloudUsageRecord._parseInt(data['totalQuotaConsumed']),
        logs: logs,
        fetchedAt: now,
      );

      state = state.copyWith(
        summary: summary,
        isLoading: false,
        lastFetchedAt: now,
        // 成功时清除 lastFailedAt
        lastFailedAt: null,
      );

      // 缓存到本地
      await _cacheSummary(summary);
    } catch (e) {
      AppLogger().w('CloudUsage', '获取云端用量失败: $e');
      final errStr = e.toString();
      final isUnauthorized = errStr.contains('401') || errStr.contains('Unauthorized');

      // 401 或网络错误时，优先使用本地缓存，避免 UI 清空
      if (isUnauthorized || errStr.contains('SocketException') || errStr.contains('Network')) {
        final hasCache = await _tryLoadCache();
        if (hasCache) {
          AppLogger().i('CloudUsage', '请求失败，已回退到本地缓存');
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastFailedAt: DateTime.now(),
      );
    }
  }

  /// 尝试从本地缓存加载，返回是否成功
  Future<bool> _tryLoadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return false;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final logs = (data['logs'] as List<dynamic>?)
              ?.map((e) =>
                  CloudUsageRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final cachedAt = data['cachedAt'] != null
          ? DateTime.parse(data['cachedAt'] as String)
          : null;

      final summary = CloudUsageSummary(
        totalCalls: CloudUsageRecord._parseInt(data['totalCalls']),
        totalTokens: CloudUsageRecord._parseInt(data['totalTokens']),
        totalQuotaConsumed: CloudUsageRecord._parseInt(data['totalQuotaConsumed']),
        logs: logs,
      );

      state = state.copyWith(
        summary: summary,
        lastFetchedAt: cachedAt,
      );
      return true;
    } catch (e) {
      AppLogger().w('CloudUsage', '加载缓存失败: $e');
      return false;
    }
  }

  /// 从本地缓存加载（公开方法，供初始化调用）
  Future<void> loadCache() async {
    await _tryLoadCache();
  }

  Future<void> _cacheSummary(CloudUsageSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'totalCalls': summary.totalCalls,
        'totalTokens': summary.totalTokens,
        'totalQuotaConsumed': summary.totalQuotaConsumed,
        'logs': summary.logs.map((e) => {
          'id': e.id,
          'provider': e.provider,
          'model': e.model,
          'promptTokens': e.promptTokens,
          'completionTokens': e.completionTokens,
          'tokenConsumed': e.tokenConsumed,
          'apiCoefficient': e.apiCoefficient,
          'costYuan': e.costYuan,
          'createdAt': e.createdAt.toIso8601String(),
        }).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      AppLogger().w('CloudUsage', '缓存失败: $e');
    }
  }

  /// 清除数据（退出登录时调用）
  Future<void> clear() async {
    state = const CloudUsageState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================

/// 云端用量 Provider（仅登录后可用）
final cloudUsageProvider =
    StateNotifierProvider<CloudUsageNotifier, CloudUsageState>(
  (ref) => CloudUsageNotifier(),
);

/// 云端用量 Provider（仅登录后可用）
///
/// 【重要】不再自动刷新！
/// 原因：用量统计以本地为主，云端仅作参考。
/// 频繁请求服务端会造成不必要的负载。
/// 刷新方式：
///   1. 用户进入用量页面时手动加载缓存
///   2. 用户点击"刷新"按钮时手动请求服务端
///   3. 每次录音/AI调用后，本地统计实时更新（不走服务端）
final cloudUsageAutoProvider = Provider<CloudUsageState>((ref) {
  // 仅透传状态，不再自动触发任何请求
  return ref.watch(cloudUsageProvider);
});
