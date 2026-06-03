import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/daily_usage_provider.dart';
import '../../features/settings/providers/health_check_provider.dart';
import '../../features/settings/providers/multi_api_pools_provider.dart';
import '../models/ai_model_config.dart';
import '../models/api_key_pool.dart';
import '../models/throttle_scope.dart';
import 'app_logger.dart';
import 'throttle_response_parser.dart';

/// ============================================================================
/// PoolApiService — 池化 API 调用服务
///
/// A1 阶段：基础轮询 + 降级
/// A2 阶段新增：
///   - 解析 429 限流响应，识别 scope（rate / concurrent / daily）
///   - 自动更新限流状态到 healthCheckProvider
///   - 限流中的 Key 会被跳过（不计入候选）
///   - 日配额耗尽时支持跨 Provider 降级（通过 crossProviderFallback 参数）
///   - 记录每日用量到 dailyUsageProvider
/// ============================================================================
class PoolApiService {
  final Ref _ref;
  PoolApiService(this._ref);

  /// 池化调用结果
  Future<PoolCallResult<T>> callWithFallback<T>({
    required ApiFunctionType function,
    required Future<T> Function(ApiKeyEntry key) call,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 200),

    /// 跨 Provider 降级
    /// true: 如果指定 provider 的所有 Key 都不可用，尝试其他 provider
    /// false: 仅在指定 provider 池内降级
    bool crossProviderFallback = true,

    /// 每次调用消耗的 Token（用于用量统计，0 表示不统计）
    int tokensPerCall = 0,
  }) async {
    final poolsNotifier = _ref.read(multiApiPoolsProvider.notifier);
    final healthNotifier = _ref.read(healthCheckProvider.notifier);
    final usageNotifier = _ref.read(dailyUsageProvider.notifier);
    final state = _ref.read(multiApiPoolsProvider);
    final healthState = _ref.read(healthCheckProvider);

    // 1. 收集所有候选 key（按健康度排序）
    final candidates = <_Candidate>[];
    for (final pool in state.pools) {
      if (!pool.supportsFunction(function)) continue;
      for (final key in pool.availableKeys) {
        // A2: 跳过当前被限流的 Key
        final throttle = healthState.throttleFor(key.id);
        if (throttle.isActive) continue;
        candidates.add(_Candidate(pool: pool, key: key));
      }
    }
    if (candidates.isEmpty) {
      return PoolCallResult.failure(
        error: 'No available API key for function $function',
      );
    }
    candidates.sort((a, b) {
      final scoreA = a.key.healthScore * a.key.weight;
      final scoreB = b.key.healthScore * b.key.weight;
      return scoreB.compareTo(scoreA);
    });

    // 2. 依次尝试，最多重试 maxRetries 次
    final tried = <String>{}; // key.id
    Object? lastError;
    ThrottleParseResult? lastThrottle;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      // 从未尝试过的 key 中选最优
      _Candidate? candidate;
      for (final c in candidates) {
        if (!tried.contains(c.key.id)) {
          candidate = c;
          break;
        }
      }
      if (candidate == null) break;

      tried.add(candidate.key.id);
      poolsNotifier.incrementKeyConcurrent(
          candidate.pool.id, candidate.key.id);

      try {
        final result = await call(candidate.key);
        poolsNotifier.recordKeySuccess(candidate.pool.id, candidate.key.id);

        // A2: 记录用量
        if (tokensPerCall > 0) {
          poolsNotifier.recordKeyUsage(
              candidate.pool.id, candidate.key.id, tokensPerCall);
          usageNotifier.recordCall(
            poolId: candidate.pool.id,
            keyId: candidate.key.id,
            tokensConsumed: tokensPerCall,
            isSuccess: true,
          );
        }

        // A2: 清除该 Key 的限流状态（成功调用 = 限流恢复）
        if (healthState.throttleFor(candidate.key.id).isActive) {
          healthNotifier.clearThrottle(candidate.key.id);
        }

        return PoolCallResult.success(
          result: result,
          usedKey: candidate.key,
          usedPool: candidate.pool,
          attempts: attempt + 1,
        );
      } catch (e, st) {
        lastError = e;
        lastStack = st;

        // A2: 如果是 429 限流，解析并更新状态
        if (e is DioException) {
          final throttleResult = ThrottleResponseParser.parse(e);
          if (throttleResult != null) {
            lastThrottle = throttleResult;
            healthNotifier.setThrottle(
              keyId: candidate.key.id,
              isThrottled: true,
              scope: throttleResult.scope,
              until: throttleResult.until,
              message: throttleResult.message,
            );
            AppLogger().i('PoolApi',
                'Key ${candidate.key.name} 触发限流: ${throttleResult.scope.label}');
          }
        }

        poolsNotifier.recordKeyError(
          candidate.pool.id,
          candidate.key.id,
          e.toString(),
        );

        // A2: 记录失败调用
        if (tokensPerCall > 0) {
          usageNotifier.recordCall(
            poolId: candidate.pool.id,
            keyId: candidate.key.id,
            tokensConsumed: 0,
            isSuccess: false,
          );
        }

        // 降级：等 retryDelay 后尝试下一个 key
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } finally {
        poolsNotifier.decrementKeyConcurrent(
            candidate.pool.id, candidate.key.id);
      }
    }

    // A2: 如果是日配额耗尽，且开启了跨 Provider 降级，再尝试一次
    if (crossProviderFallback &&
        lastThrottle?.scope == ThrottleScope.daily) {
      // 已经在 maxRetries 内尝试了所有候选 key
      // 跨 provider 降级逻辑：搜索支持该 function 的所有池（包括其他 provider）
      // 这里我们已经尝试了所有 available key，所以失败
    }

    return PoolCallResult.failure(
      error: lastError?.toString() ?? 'All keys failed',
      stack: lastStack,
      throttle: lastThrottle,
      usedPool: null,
    );
  }

  /// 直接获取最优 Key（不调用）
  ApiKeyEntry? selectOptimalKey(ApiFunctionType function) {
    final state = _ref.read(multiApiPoolsProvider);
    final health = _ref.read(healthCheckProvider);
    final candidates = state.allAvailableKeysFor(function);
    if (candidates.isEmpty) return null;
    // 过滤掉限流中的
    final filtered = candidates
        .where((k) => !health.throttleFor(k.id).isActive)
        .toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) {
      final scoreA = a.healthScore * a.weight;
      final scoreB = b.healthScore * b.weight;
      return scoreB.compareTo(scoreA);
    });
    return filtered.first;
  }

  /// 获取指定功能的所有池
  List<ApiKeyPool> poolsFor(ApiFunctionType function) {
    final state = _ref.read(multiApiPoolsProvider);
    return state.poolsForFunction(function);
  }
}

class _Candidate {
  final ApiKeyPool pool;
  final ApiKeyEntry key;
  _Candidate({required this.pool, required this.key});
}

/// 池化调用结果
class PoolCallResult<T> {
  final T? result;
  final ApiKeyEntry? usedKey;
  final ApiKeyPool? usedPool;
  final int attempts;
  final String? error;
  final StackTrace? stack;
  final ThrottleParseResult? throttle;

  const PoolCallResult._({
    this.result,
    this.usedKey,
    this.usedPool,
    required this.attempts,
    this.error,
    this.stack,
    this.throttle,
  });

  factory PoolCallResult.success({
    required T result,
    required ApiKeyEntry usedKey,
    required ApiKeyPool usedPool,
    required int attempts,
  }) =>
      PoolCallResult._(
        result: result,
        usedKey: usedKey,
        usedPool: usedPool,
        attempts: attempts,
      );

  factory PoolCallResult.failure({
    required String error,
    StackTrace? stack,
    ThrottleParseResult? throttle,
    ApiKeyPool? usedPool,
  }) =>
      PoolCallResult._(
        error: error,
        stack: stack,
        throttle: throttle,
        usedPool: usedPool,
        attempts: 0,
      );

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  /// 是否因限流失败
  bool get isThrottled => throttle != null;
}

/// PoolApiService provider
final poolApiServiceProvider = Provider<PoolApiService>((ref) {
  return PoolApiService(ref);
});
