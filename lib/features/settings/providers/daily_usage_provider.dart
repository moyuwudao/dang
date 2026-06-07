import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/api_key_pool.dart';
import '../../../core/models/usage_record.dart';
import 'multi_api_pools_provider.dart';

/// ============================================================================
/// 用量统计 Provider（A2 阶段新增）
///
/// 职责：
///   1. 记录每个 Key 每天的 Token 用量
///   2. 计算用量趋势（最近 7 天）
///   3. 聚合 Pool 维度统计
///   4. 持久化到 SharedPreferences
///   5. 跨 Provider 对比
///
/// 与 MultiApiPoolsProvider 的关系：
///   - pools 是数据源（Key 的 dailyUsage）
///   - records 是历史快照（保留过去 7 天的数据）
///   - 当 dailyUsage 归零（隔天 0 点）时，触发 snapshotAndReset
/// ============================================================================

/// 状态
class DailyUsageState {
  /// 当日用量记录（按 keyId 索引）
  final Map<String, UsageRecord> today;

  /// 历史用量记录（按日期 → keyId → record）
  /// 最多保留 7 天
  final List<UsageRecord> history;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 最后同步时间
  final DateTime? lastSyncedAt;

  const DailyUsageState({
    this.today = const {},
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.lastSyncedAt,
  });

  DailyUsageState copyWith({
    Map<String, UsageRecord>? today,
    List<UsageRecord>? history,
    bool? isLoading,
    String? error,
    DateTime? lastSyncedAt,
  }) {
    return DailyUsageState(
      today: today ?? this.today,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      // isLoading 在 reset 时显式置 false
    );
  }

  /// 获取最近 N 天的趋势（按日期升序）
  List<UsageTrendPoint> trendForPool(String poolId, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
    final byDate = <DateTime, int>{};
    for (final r in history) {
      if (r.poolId != poolId) continue;
      if (r.date.isBefore(cutoffDate)) continue;
      byDate[r.date] = (byDate[r.date] ?? 0) + r.tokensConsumed;
    }
    final points = byDate.entries
        .map((e) => UsageTrendPoint(date: e.key, tokens: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// 所有 Pool 的当日用量汇总
  List<PoolUsageSummary> poolSummaries() {
    final byPool = <String, List<UsageRecord>>{};
    for (final r in today.values) {
      byPool.putIfAbsent(r.poolId, () => []).add(r);
    }
    return byPool.entries.map((entry) {
      final records = entry.value;
      final totalTokens = records.fold<int>(0, (s, r) => s + r.tokensConsumed);
      final totalCalls = records.fold<int>(0, (s, r) => s + r.callCount);
      final totalSuccess = records.fold<int>(0, (s, r) => s + r.successCount);
      final avgSuccess = totalCalls == 0 ? 1.0 : totalSuccess / totalCalls;
      return PoolUsageSummary(
        poolId: entry.key,
        poolName: records.first.providerName,
        totalTokens: totalTokens,
        totalCalls: totalCalls,
        avgSuccessRate: avgSuccess,
      );
    }).toList();
  }

  /// 全局当日总用量
  int get totalTokensToday =>
      today.values.fold(0, (sum, r) => sum + r.tokensConsumed);

  int get totalCallsToday =>
      today.values.fold(0, (sum, r) => sum + r.callCount);

  /// 跨 Pool 的当日用量对比（按 Token 降序）
  List<PoolUsageSummary> topPoolsByUsage({int limit = 5}) {
    final summaries = poolSummaries()
      ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    if (summaries.length > limit) {
      return summaries.sublist(0, limit);
    }
    return summaries;
  }
}

/// ============================================================================
/// Notifier
/// ============================================================================
class DailyUsageNotifier extends StateNotifier<DailyUsageState> {
  static const String _storageKey = 'daily_usage_v1';
  static const int _maxHistoryDays = 7;

  DailyUsageNotifier() : super(const DailyUsageState());

  /// 加载本地存储的用量历史
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final history = (data['history'] as List<dynamic>?)
              ?.map((e) => UsageRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = state.copyWith(
        history: _pruneHistory(history),
        isLoading: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 从 Pool 列表同步当日数据（合并模式，不覆盖 recordCall 记录的数据）
  void syncFromPools(List<ApiKeyPool> pools) {
    final poolData = <String, UsageRecord>{};
    for (final pool in pools) {
      for (final key in pool.keys) {
        if (key.dailyUsage == 0 && key.successCount == 0 && key.errorCount == 0) {
          continue;
        }
        final record = UsageRecord.fromKeyEntry(key, pool);
        poolData[record.keyId] = record;
      }
    }
    // 合并：poolData 覆盖同 keyId 的旧数据，但保留 recordCall 写入的非 pool 数据
    final merged = <String, UsageRecord>{...state.today, ...poolData};
    state = state.copyWith(
      today: merged,
      lastSyncedAt: DateTime.now(),
    );
  }

  /// 记录一次调用（成功 / 错误 / 消耗 Token）
  void recordCall({
    required String poolId,
    required String keyId,
    required int tokensConsumed,
    required bool isSuccess,
    String providerName = '',
  }) {
    final existing = state.today[keyId];
    final updated = (existing ??
            UsageRecord(
              id: keyId,
              keyId: keyId,
              poolId: poolId,
              providerName: providerName,
              date: _todayDate(),
            ))
        .copyWith(
      tokensConsumed: (existing?.tokensConsumed ?? 0) + tokensConsumed,
      callCount: (existing?.callCount ?? 0) + 1,
      successCount: (existing?.successCount ?? 0) + (isSuccess ? 1 : 0),
      errorCount: (existing?.errorCount ?? 0) + (isSuccess ? 0 : 1),
    );
    state = state.copyWith(today: {...state.today, keyId: updated});
    _persistThrottled();
  }

  /// 隔天 0 点触发：归档今日到历史，清空 today
  Future<void> snapshotAndReset(List<ApiKeyPool> pools) async {
    // 1. 先同步一次（保留今日最后的状态）
    syncFromPools(pools);
    final now = DateTime.now();
    final todayDate = _todayDate();
    // 2. 把 today 合并到 history
    final newHistory = [...state.history];
    for (final record in state.today.values) {
      // 标准化 date 为今日 0 点
      final normalized = record.copyWith(date: todayDate);
      newHistory.removeWhere((r) =>
          r.keyId == normalized.keyId && r.date == todayDate);
      newHistory.add(normalized);
    }
    final pruned = _pruneHistory(newHistory);
    state = state.copyWith(
      today: const {},
      history: pruned,
      lastSyncedAt: now,
    );
    await _persist();
  }

  /// 清理过期历史（保留最近 7 天）
  List<UsageRecord> _pruneHistory(List<UsageRecord> records) {
    final cutoff = DateTime.now().subtract(const Duration(days: _maxHistoryDays));
    final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
    return records.where((r) => !r.date.isBefore(cutoffDate)).toList();
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ============================================================================
  // 持久化
  // ============================================================================

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'history': state.history.map((r) => r.toJson()).toList(),
      'lastSyncedAt': state.lastSyncedAt?.toIso8601String(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);
  void _persistThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastPersist).inSeconds < 30) return;
    _lastPersist = now;
    _persist();
  }

  /// 清空所有数据
  Future<void> clear() async {
    state = const DailyUsageState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================
final dailyUsageProvider =
    StateNotifierProvider<DailyUsageNotifier, DailyUsageState>(
  (ref) => DailyUsageNotifier(),
);

/// 便捷 Provider：自动从 pools 同步到 today
final dailyUsageSyncedProvider = Provider<DailyUsageState>((ref) {
  final pools = ref.watch(multiApiPoolsProvider);
  final usage = ref.watch(dailyUsageProvider);
  // 触发同步（带去抖）
  Future.microtask(() {
    if (pools.pools.isNotEmpty) {
      ref.read(dailyUsageProvider.notifier).syncFromPools(pools.pools);
    }
  });
  return usage;
});
