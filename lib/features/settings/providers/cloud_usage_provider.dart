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

  factory CloudUsageRecord.fromJson(Map<String, dynamic> json) {
    return CloudUsageRecord(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      model: json['model'] as String? ?? '',
      promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
      tokenConsumed: (json['tokenConsumed'] as num?)?.toInt() ?? 0,
      apiCoefficient: (json['apiCoefficient'] as num?)?.toDouble() ?? 1.0,
      costYuan: (json['costYuan'] as num?)?.toDouble(),
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

  const CloudUsageState({
    this.summary = const CloudUsageSummary(),
    this.isLoading = false,
    this.error,
    this.lastFetchedAt,
  });

  CloudUsageState copyWith({
    CloudUsageSummary? summary,
    bool? isLoading,
    String? error,
    DateTime? lastFetchedAt,
  }) {
    return CloudUsageState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
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
        state = state.copyWith(isLoading: false, error: '响应数据为空');
        return;
      }

      final logs = (data['logs'] as List<dynamic>?)
              ?.map((e) =>
                  CloudUsageRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final summary = CloudUsageSummary(
        totalCalls: (data['totalCalls'] as num?)?.toInt() ?? 0,
        totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
        totalQuotaConsumed:
            (data['totalQuotaConsumed'] as num?)?.toInt() ?? 0,
        logs: logs,
        fetchedAt: now,
      );

      state = state.copyWith(
        summary: summary,
        isLoading: false,
        lastFetchedAt: now,
      );

      // 缓存到本地
      await _cacheSummary(summary);
    } catch (e) {
      AppLogger().w('CloudUsage', '获取云端用量失败: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 从本地缓存加载
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return;

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
        totalCalls: (data['totalCalls'] as num?)?.toInt() ?? 0,
        totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
        totalQuotaConsumed:
            (data['totalQuotaConsumed'] as num?)?.toInt() ?? 0,
        logs: logs,
      );

      state = state.copyWith(
        summary: summary,
        lastFetchedAt: cachedAt,
      );
    } catch (e) {
      AppLogger().w('CloudUsage', '加载缓存失败: $e');
    }
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

/// 自动初始化：登录后自动加载缓存 + 按需刷新
final cloudUsageAutoProvider = Provider<CloudUsageState>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  final cloudUsage = ref.watch(cloudUsageProvider);

  // 登录后自动初始化
  if (authState?.isLoggedIn == true) {
    Future.microtask(() {
      final notifier = ref.read(cloudUsageProvider.notifier);
      if (cloudUsage.lastFetchedAt == null) {
        notifier.loadCache().then((_) => notifier.fetchIfNeeded());
      } else if (cloudUsage.needsRefresh) {
        notifier.fetchIfNeeded();
      }
    });
  }

  return cloudUsage;
});
