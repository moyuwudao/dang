import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/health_check_result.dart';
import '../../../core/models/throttle_scope.dart';
import 'multi_api_pools_provider.dart';

/// ============================================================================
/// 健康检查 Provider（A2 阶段新增）
///
/// 职责：
///   1. 缓存每个 Key 最近一次健康检查结果
///   2. 跟踪每个 Key 当前是否处于限流状态
///   3. 记录限流事件（用于实时展示限流徽标）
///   4. 持久化最近 N 次检查结果
///
/// 与 HealthCheckService 配合：
///   - Service 负责调用后端 /api-key/admin/:id/test
///   - Provider 负责缓存 + 展示
/// ============================================================================

/// 限流状态（Key 维度）
class KeyThrottleState {
  final String keyId;

  /// 当前是否被限流
  final bool isThrottled;

  /// 限流范围
  final ThrottleScope scope;

  /// 限流到期时间
  final DateTime? until;

  /// 触发限流的消息
  final String? message;

  /// 触发时间
  final DateTime? occurredAt;

  const KeyThrottleState({
    required this.keyId,
    this.isThrottled = false,
    this.scope = ThrottleScope.unknown,
    this.until,
    this.message,
    this.occurredAt,
  });

  bool get isActive {
    if (!isThrottled) return false;
    if (until == null) return true;
    return DateTime.now().isBefore(until!);
  }

  Duration? get remaining {
    if (until == null) return null;
    final diff = until!.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'isThrottled': isThrottled,
      'scope': scope.name,
      'until': until?.toIso8601String(),
      'message': message,
      'occurredAt': occurredAt?.toIso8601String(),
    };
  }

  factory KeyThrottleState.fromJson(Map<String, dynamic> json) {
    return KeyThrottleState(
      keyId: json['keyId'] ?? '',
      isThrottled: json['isThrottled'] ?? false,
      scope: ThrottleScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => ThrottleScope.unknown,
      ),
      until: json['until'] != null ? DateTime.tryParse(json['until']) : null,
      message: json['message'],
      occurredAt:
          json['occurredAt'] != null ? DateTime.tryParse(json['occurredAt']) : null,
    );
  }
}

/// 状态
class HealthCheckState {
  /// 最近一次检查的所有 Key 结果
  final Map<String, HealthCheckResult> latestResults;

  /// 正在检查的 Key IDs
  final Set<String> checking;

  /// 每个 Key 的当前限流状态
  final Map<String, KeyThrottleState> throttles;

  /// 是否全局启用健康检查（手动关闭可停止轮询）
  final bool enabled;

  /// 整体快照
  final HealthCheckSnapshot? snapshot;

  /// 错误信息
  final String? error;

  /// 最后检查时间
  final DateTime? lastCheckedAt;

  const HealthCheckState({
    this.latestResults = const {},
    this.checking = const {},
    this.throttles = const {},
    this.enabled = true,
    this.snapshot,
    this.error,
    this.lastCheckedAt,
  });

  HealthCheckState copyWith({
    Map<String, HealthCheckResult>? latestResults,
    Set<String>? checking,
    Map<String, KeyThrottleState>? throttles,
    bool? enabled,
    HealthCheckSnapshot? snapshot,
    String? error,
    DateTime? lastCheckedAt,
  }) {
    return HealthCheckState(
      latestResults: latestResults ?? this.latestResults,
      checking: checking ?? this.checking,
      throttles: throttles ?? this.throttles,
      enabled: enabled ?? this.enabled,
      snapshot: snapshot ?? this.snapshot,
      error: error,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  /// 获取 Key 的限流状态
  KeyThrottleState throttleFor(String keyId) {
    return throttles[keyId] ??
        KeyThrottleState(keyId: keyId, isThrottled: false);
  }

  /// 获取所有当前被限流的 Key
  List<KeyThrottleState> get activeThrottles {
    return throttles.values.where((t) => t.isActive).toList();
  }

  /// 是否所有 Key 都被限流
  bool get allThrottled {
    return throttles.isNotEmpty &&
        throttles.values.every((t) => t.isActive);
  }
}

/// ============================================================================
/// Notifier
/// ============================================================================
class HealthCheckNotifier extends StateNotifier<HealthCheckState> {
  static const String _storageKey = 'health_check_cache_v1';

  HealthCheckNotifier() : super(const HealthCheckState());

  /// 加载缓存
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final results = <String, HealthCheckResult>{};
      final r = data['latestResults'] as List<dynamic>? ?? [];
      for (final item in r) {
        final result = HealthCheckResult.fromJson(item as Map<String, dynamic>);
        results[result.keyId] = result;
      }
      final throttles = <String, KeyThrottleState>{};
      final t = data['throttles'] as List<dynamic>? ?? [];
      for (final item in t) {
        final throttle =
            KeyThrottleState.fromJson(item as Map<String, dynamic>);
        throttles[throttle.keyId] = throttle;
      }
      state = state.copyWith(latestResults: results, throttles: throttles);
    } catch (_) {
      // 静默忽略
    }
  }

  /// 更新单个 Key 的检查结果
  void updateResult(HealthCheckResult result) {
    final updated = {...state.latestResults, result.keyId: result};
    final snapshot = HealthCheckSnapshot.fromResults(updated.values.toList());
    state = state.copyWith(
      latestResults: updated,
      snapshot: snapshot,
      lastCheckedAt: DateTime.now(),
    );
    _persistThrottled();
  }

  /// 标记 Key 正在检查
  void setChecking(String keyId, bool isChecking) {
    final updated = {...state.checking};
    if (isChecking) {
      updated.add(keyId);
    } else {
      updated.remove(keyId);
    }
    state = state.copyWith(checking: updated);
  }

  /// 设置 Key 的限流状态
  void setThrottle({
    required String keyId,
    required bool isThrottled,
    ThrottleScope scope = ThrottleScope.unknown,
    DateTime? until,
    String? message,
  }) {
    final throttle = KeyThrottleState(
      keyId: keyId,
      isThrottled: isThrottled,
      scope: scope,
      until: until,
      message: message,
      occurredAt: isThrottled ? DateTime.now() : null,
    );
    final updated = {...state.throttles, keyId: throttle};
    state = state.copyWith(throttles: updated);
    _persistThrottled();
  }

  /// 清除 Key 的限流
  void clearThrottle(String keyId) {
    setThrottle(keyId: keyId, isThrottled: false);
  }

  /// 切换全局启用
  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  /// 持久化
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'latestResults':
          state.latestResults.values.map((r) => r.toJson()).toList(),
      'throttles': state.throttles.values.map((t) => t.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);
  void _persistThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastPersist).inSeconds < 10) return;
    _lastPersist = now;
    _persist();
  }

  Future<void> clear() async {
    state = const HealthCheckState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================
final healthCheckProvider =
    StateNotifierProvider<HealthCheckNotifier, HealthCheckState>(
  (ref) => HealthCheckNotifier(),
);

/// 便捷 Provider：限流中的 Key 数
final activeThrottleCountProvider = Provider<int>((ref) {
  final state = ref.watch(healthCheckProvider);
  return state.activeThrottles.length;
});

/// 便捷 Provider：是否有跨 Provider 降级需求（所有 Pool 的所有 Key 都限流）
final needsCrossProviderFallbackProvider = Provider<bool>((ref) {
  final pools = ref.watch(multiApiPoolsProvider);
  final health = ref.watch(healthCheckProvider);

  if (pools.pools.isEmpty) return false;

  // 检查是否每个池都有可用的 Key
  for (final pool in pools.pools) {
    final hasAvailable = pool.keys.any((key) {
      final throttle = health.throttleFor(key.id);
      if (throttle.isActive) return false;
      return key.isActive;
    });
    if (hasAvailable) return false;
  }
  return true;
});
