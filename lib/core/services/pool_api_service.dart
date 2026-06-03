import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/multi_api_pools_provider.dart';
import '../models/ai_model_config.dart';
import '../models/api_key_pool.dart';

/// ============================================================================
/// PoolApiService — 池化 API 调用服务（A1 阶段新增）
///
/// 相比 ApiService 的区别：
/// - 选择 Key 时使用池内 selectOptimalKey（基于 healthScore × weight）
/// - 调用失败时自动降级到池内其他 Key
/// - 每次调用后自动记录成功/错误到 MultiApiPoolsNotifier
/// - 跟踪 currentConcurrent 实现并发限制
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
  }) async {
    final poolsNotifier = _ref.read(multiApiPoolsProvider.notifier);
    final state = _ref.read(multiApiPoolsProvider);

    // 1. 收集所有候选 key（按健康度排序）
    final candidates = <_Candidate>[];
    for (final pool in state.pools) {
      if (!pool.supportsFunction(function)) continue;
      for (final key in pool.availableKeys) {
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
        return PoolCallResult.success(
          result: result,
          usedKey: candidate.key,
          attempts: attempt + 1,
        );
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        poolsNotifier.recordKeyError(
          candidate.pool.id,
          candidate.key.id,
          e.toString(),
        );
        // 降级：等 retryDelay 后尝试下一个 key
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } finally {
        poolsNotifier.decrementKeyConcurrent(
            candidate.pool.id, candidate.key.id);
      }
    }

    return PoolCallResult.failure(
      error: lastError?.toString() ?? 'All keys failed',
      stack: lastStack,
    );
  }

  /// 直接获取最优 Key（不调用）
  ApiKeyEntry? selectOptimalKey(ApiFunctionType function) {
    final state = _ref.read(multiApiPoolsProvider);
    return state.selectOptimalKeyFor(function);
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
  final int attempts;
  final String? error;
  final StackTrace? stack;

  const PoolCallResult._({
    this.result,
    this.usedKey,
    required this.attempts,
    this.error,
    this.stack,
  });

  factory PoolCallResult.success({
    required T result,
    required ApiKeyEntry usedKey,
    required int attempts,
  }) =>
      PoolCallResult._(result: result, usedKey: usedKey, attempts: attempts);

  factory PoolCallResult.failure({
    required String error,
    StackTrace? stack,
  }) =>
      PoolCallResult._(error: error, stack: stack, attempts: 0);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// PoolApiService provider
final poolApiServiceProvider = Provider<PoolApiService>((ref) {
  return PoolApiService(ref);
});
