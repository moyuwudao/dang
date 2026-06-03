import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/models/api_key_pool.dart';

/// ============================================================================
/// Multi API Pools 状态（API Key 池化管理）
/// ============================================================================
class MultiApiPoolsState {
  /// 所有 Key 池
  final List<ApiKeyPool> pools;

  /// 是否正在加载
  final bool isLoading;

  /// 加载/保存错误
  final String? error;

  /// 当前版本号（用于数据迁移）
  final int version;

  const MultiApiPoolsState({
    this.pools = const [],
    this.isLoading = false,
    this.error,
    this.version = 1,
  });

  MultiApiPoolsState copyWith({
    List<ApiKeyPool>? pools,
    bool? isLoading,
    String? error,
    int? version,
  }) {
    return MultiApiPoolsState(
      pools: pools ?? this.pools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      version: version ?? this.version,
    );
  }

  /// 获取指定 provider 的池
  ApiKeyPool? poolByProvider(AiProvider provider) {
    for (final p in pools) {
      if (p.provider == provider) return p;
    }
    return null;
  }

  /// 获取指定 ID 的池
  ApiKeyPool? poolById(String id) {
    for (final p in pools) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 获取支持指定功能的所有池
  List<ApiKeyPool> poolsForFunction(ApiFunctionType function) {
    return pools.where((p) => p.supportsFunction(function)).toList();
  }

  /// 获取支持指定功能的池中所有可用 Key
  List<ApiKeyEntry> allAvailableKeysFor(ApiFunctionType function) {
    final result = <ApiKeyEntry>[];
    for (final pool in poolsForFunction(function)) {
      result.addAll(pool.availableKeys);
    }
    return result;
  }

  /// 为指定功能选择最优 Key（跨池）
  ApiKeyEntry? selectOptimalKeyFor(ApiFunctionType function) {
    final candidates = allAvailableKeysFor(function);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final scoreA = a.healthScore * a.weight;
      final scoreB = b.healthScore * b.weight;
      return scoreB.compareTo(scoreA);
    });
    return candidates.first;
  }

  /// 全局统计
  int get totalKeys => pools.fold(0, (sum, p) => sum + p.keys.length);
  int get activeKeys => pools.fold(0, (sum, p) => sum + p.availableKeys.length);
  int get totalDailyUsage =>
      pools.fold(0, (sum, p) => sum + p.totalDailyUsage);
  int get totalDailyQuota =>
      pools.fold(0, (sum, p) => sum + p.totalDailyQuota);

  /// 转换为旧版 MultiApiConfig（向后兼容）
  MultiApiConfig toLegacyConfig() {
    final entries = <ApiConfigEntry>[];
    for (final pool in pools) {
      if (pool.keys.isEmpty) continue;
      // 池内的第一个 Key 作为主 entry
      final mainKey = pool.keys.first;
      entries.add(ApiConfigEntry(
        id: pool.id,
        name: pool.displayName,
        provider: pool.provider,
        apiKey: mainKey.apiKey,
        appId: mainKey.appId,
        accessKeySecret: mainKey.accessKeySecret,
        baseUrl: mainKey.baseUrl ?? pool.id,
        model: mainKey.model ?? pool.model,
        functions: pool.functions,
        isActive: pool.isEnabled,
        isCustomProvider: pool.isCustomProvider,
        customProviderName: pool.customProviderName,
        isCloudConfig: pool.isCloudConfig,
        cloudMultiplier: pool.cloudMultiplier,
        createdAt: pool.createdAt,
        updatedAt: pool.updatedAt,
      ));
    }
    return MultiApiConfig(configs: entries);
  }
}

/// ============================================================================
/// MultiApiPoolsNotifier — 池化配置管理
/// ============================================================================
class MultiApiPoolsNotifier extends StateNotifier<MultiApiPoolsState> {
  static const String _storageKey = 'multi_api_pools_v1';
  static const String _legacyStorageKey = 'multi_api_config';

  MultiApiPoolsNotifier() : super(const MultiApiPoolsState());

  /// 加载（首次自动从旧格式迁移）
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 尝试读取新格式
      final newJson = prefs.getString(_storageKey);
      if (newJson != null && newJson.isNotEmpty) {
        final pools = _decodePools(newJson);
        state = state.copyWith(
          pools: pools,
          isLoading: false,
          version: 1,
        );
        return;
      }

      // 2. 没有新格式，尝试从旧格式迁移
      final legacyJson = prefs.getString(_legacyStorageKey);
      if (legacyJson != null && legacyJson.isNotEmpty) {
        final pools = _migrateFromLegacy(legacyJson);
        // 保存到新格式
        await _savePools(prefs, pools);
        state = state.copyWith(
          pools: pools,
          isLoading: false,
          version: 1,
        );
        return;
      }

      // 3. 都没有，空状态
      state = state.copyWith(pools: const [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 从旧格式迁移
  List<ApiKeyPool> _migrateFromLegacy(String legacyJson) {
    try {
      final legacy = MultiApiConfig.fromJson(jsonDecode(legacyJson));
      final pools = <ApiKeyPool>[];
      for (final entry in legacy.configs) {
        final key = ApiKeyEntry(
          id: '${entry.id}_key_0',
          name: '主 Key',
          apiKey: entry.apiKey,
          appId: entry.appId,
          accessKeySecret: entry.accessKeySecret,
          baseUrl: (entry.baseUrl != null && entry.baseUrl!.isNotEmpty)
              ? entry.baseUrl
              : null,
          model: (entry.model.isNotEmpty) ? entry.model : null,
          isActive: entry.isActive,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        );
        final pool = ApiKeyPool(
          id: entry.id,
          provider: entry.provider,
          isCustomProvider: entry.isCustomProvider,
          customProviderName: entry.customProviderName,
          model: entry.model,
          keys: [key],
          functions: entry.functions,
          name: entry.name,
          isCloudConfig: entry.isCloudConfig,
          cloudMultiplier: entry.cloudMultiplier,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        );
        pools.add(pool);
      }
      return pools;
    } catch (_) {
      return [];
    }
  }

  /// 反序列化
  List<ApiKeyPool> _decodePools(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => ApiKeyPool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 持久化
  Future<void> _savePools(
      SharedPreferences prefs, List<ApiKeyPool> pools) async {
    final json = jsonEncode(pools.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await _savePools(prefs, state.pools);
  }

  // ============================================================================
  // 池管理
  // ============================================================================

  Future<void> addPool(ApiKeyPool pool) async {
    state = state.copyWith(
      pools: [...state.pools, pool],
    );
    await _persist();
  }

  Future<void> updatePool(ApiKeyPool pool) async {
    final updated = state.pools
        .map((p) => p.id == pool.id ? pool : p)
        .toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  Future<void> removePool(String poolId) async {
    final updated =
        state.pools.where((p) => p.id != poolId).toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  // ============================================================================
  // Key 管理
  // ============================================================================

  Future<void> addKeyToPool(String poolId, ApiKeyEntry key) async {
    final updated = state.pools.map((p) {
      if (p.id == poolId) {
        return p.copyWith(
          keys: [...p.keys, key],
          updatedAt: DateTime.now(),
        );
      }
      return p;
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  Future<void> updateKey(ApiKeyEntry key) async {
    final updated = state.pools.map((p) {
      final newKeys = p.keys
          .map((k) => k.id == key.id ? key : k)
          .toList(growable: false);
      if (newKeys.length != p.keys.length) return p;
      return p.copyWith(keys: newKeys, updatedAt: DateTime.now());
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  Future<void> removeKey(String poolId, String keyId) async {
    final updated = state.pools.map((p) {
      if (p.id == poolId) {
        return p.copyWith(
          keys: p.keys.where((k) => k.id != keyId).toList(),
          updatedAt: DateTime.now(),
        );
      }
      return p;
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  // ============================================================================
  // 运行时状态追踪
  // ============================================================================

  void recordKeySuccess(String poolId, String keyId) {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        return k.copyWith(
          successCount: k.successCount + 1,
          lastUsedAt: DateTime.now(),
          lastError: null,
          status: k.status == ApiKeyStatus.throttled
              ? ApiKeyStatus.active
              : k.status,
          updatedAt: DateTime.now(),
        );
      }).toList(growable: false);
      return p.copyWith(keys: newKeys, updatedAt: DateTime.now());
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    // 成功状态变化频繁，节流持久化
    _persistThrottled();
  }

  void recordKeyError(String poolId, String keyId, String errorMessage) {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        final newErrorCount = k.errorCount + 1;
        // 连续错误 ≥3 次标记为限流
        final newStatus = newErrorCount >= 3
            ? ApiKeyStatus.throttled
            : k.status;
        return k.copyWith(
          errorCount: newErrorCount,
          lastError: errorMessage,
          lastUsedAt: DateTime.now(),
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }).toList(growable: false);
      return p.copyWith(keys: newKeys, updatedAt: DateTime.now());
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    _persistThrottled();
  }

  void incrementKeyConcurrent(String poolId, String keyId) {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        return k.copyWith(currentConcurrent: k.currentConcurrent + 1);
      }).toList(growable: false);
      return p.copyWith(keys: newKeys);
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
  }

  void decrementKeyConcurrent(String poolId, String keyId) {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        return k.copyWith(
          currentConcurrent: (k.currentConcurrent - 1).clamp(0, 999999),
        );
      }).toList(growable: false);
      return p.copyWith(keys: newKeys);
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
  }

  void recordKeyUsage(String poolId, String keyId, int tokens) {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        return k.copyWith(
          dailyUsage: k.dailyUsage + tokens,
          updatedAt: DateTime.now(),
        );
      }).toList(growable: false);
      return p.copyWith(keys: newKeys, updatedAt: DateTime.now());
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    _persistThrottled();
  }

  /// 重置每日用量（每日凌晨触发）
  void resetDailyUsage() {
    final updated = state.pools.map((p) {
      return p.copyWith(
        keys: p.keys
            .map((k) => k.copyWith(dailyUsage: 0, updatedAt: DateTime.now()))
            .toList(growable: false),
        updatedAt: DateTime.now(),
      );
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    _persist();
  }

  /// 重新启用 throttled key（手动重置）
  Future<void> resetKeyErrors(String poolId, String keyId) async {
    final updated = state.pools.map((p) {
      if (p.id != poolId) return p;
      final newKeys = p.keys.map((k) {
        if (k.id != keyId) return k;
        return k.copyWith(
          errorCount: 0,
          lastError: null,
          status: ApiKeyStatus.active,
          updatedAt: DateTime.now(),
        );
      }).toList(growable: false);
      return p.copyWith(keys: newKeys, updatedAt: DateTime.now());
    }).toList(growable: false);
    state = state.copyWith(pools: updated);
    await _persist();
  }

  /// 节流持久化（避免每次成功/失败都写盘）
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);
  void _persistThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastPersist).inSeconds < 5) return;
    _lastPersist = now;
    _persist();
  }

  /// 清空所有数据
  Future<void> clear() async {
    state = const MultiApiPoolsState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================
final multiApiPoolsProvider =
    StateNotifierProvider<MultiApiPoolsNotifier, MultiApiPoolsState>(
  (ref) => MultiApiPoolsNotifier(),
);
