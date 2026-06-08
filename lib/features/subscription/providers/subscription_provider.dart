import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/services/cloud_config_sync_service.dart';
import '../../../core/services/app_logger.dart';
import '../models/plan_model.dart';

class ApiPolicy {
  final String provider;
  final String? modelPattern;
  final String? model;
  final double multiplier;
  final bool isAllowed;

  const ApiPolicy({
    required this.provider,
    this.modelPattern,
    this.model,
    required this.multiplier,
    this.isAllowed = true,
  });

  factory ApiPolicy.fromJson(Map<String, dynamic> json) {
    final rawMultiplier = json['multiplier'];
    final multiplier = rawMultiplier is num
        ? rawMultiplier.toDouble()
        : rawMultiplier is String
            ? double.tryParse(rawMultiplier) ?? 1.0
            : 1.0;
    return ApiPolicy(
      provider: json['provider'] ?? '',
      modelPattern: json['modelPattern'],
      model: json['model'],
      multiplier: multiplier,
      isAllowed: json['isAllowed'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'modelPattern': modelPattern,
    'model': model,
    'multiplier': multiplier,
    'isAllowed': isAllowed,
  };
}

class DefaultConfig {
  final String functionType;
  final String modelPattern;

  const DefaultConfig({
    required this.functionType,
    required this.modelPattern,
  });

  factory DefaultConfig.fromJson(Map<String, dynamic> json) {
    return DefaultConfig(
      functionType: json['functionType'] ?? '',
      modelPattern: json['modelPattern'] ?? '',
    );
  }
}

// 单个订阅的完整信息（多套餐场景使用）
class PlanSubscription {
  final String subscriptionId;
  final String planId;
  final String planName;
  final DateTime? expiresAt;
  final String status;
  final List<DefaultConfig> defaultConfigs;
  final List<ApiPolicy> apiPolicies;
  final List<String> allowedModels;
  // 套餐特性（云端录入，Mine 屏对齐展示）
  final List<String> features;
  // 是否推荐
  final bool isRecommended;

  const PlanSubscription({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    this.expiresAt,
    this.status = 'active',
    this.defaultConfigs = const [],
    this.apiPolicies = const [],
    this.allowedModels = const [],
    this.features = const [],
    this.isRecommended = false,
  });

  factory PlanSubscription.fromJson(Map<String, dynamic> json) {
    return PlanSubscription(
      subscriptionId: (json['subscriptionId'] ?? json['id'] ?? '').toString(),
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '未知套餐',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
      defaultConfigs: (json['defaultConfigs'] as List<dynamic>?)
              ?.map((e) => DefaultConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      apiPolicies: (json['apiPolicies'] as List<dynamic>?)
              ?.map((e) => ApiPolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      allowedModels: (json['allowedModels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isRecommended: json['isRecommended'] as bool? ?? false,
    );
  }
}

class SubscriptionState {
  final bool isActive;
  final String? planId;
  final String? planName;
  final DateTime? expiresAt;
  final TokenBalance tokenBalance;
  final List<ApiPolicy> apiPolicies;
  final List<DefaultConfig> defaultConfigs;
  // 多套餐支持
  final List<PlanSubscription> subscriptions;
  // 当前激活的 subscriptionId（多套餐时供切换）
  final String? activeSubscriptionId;
  // 套餐配额（服务端 /subscription 返回）
  final int totalQuota;
  final int usedQuota;

  const SubscriptionState({
    this.isActive = false,
    this.planId,
    this.planName,
    this.expiresAt,
    this.tokenBalance = const TokenBalance(
      balanceTokens: 0,
      freeTokensRemaining: 0,
      totalTokens: 0,
      usedTokens: 0,
    ),
    this.apiPolicies = const [],
    this.defaultConfigs = const [],
    this.subscriptions = const [],
    this.activeSubscriptionId,
    this.totalQuota = 0,
    this.usedQuota = 0,
  });

  SubscriptionState copyWith({
    bool? isActive,
    String? planId,
    String? planName,
    DateTime? expiresAt,
    TokenBalance? tokenBalance,
    List<ApiPolicy>? apiPolicies,
    List<DefaultConfig>? defaultConfigs,
    List<PlanSubscription>? subscriptions,
    String? activeSubscriptionId,
    int? totalQuota,
    int? usedQuota,
  }) {
    return SubscriptionState(
      isActive: isActive ?? this.isActive,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      apiPolicies: apiPolicies ?? this.apiPolicies,
      defaultConfigs: defaultConfigs ?? this.defaultConfigs,
      subscriptions: subscriptions ?? this.subscriptions,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,
      totalQuota: totalQuota ?? this.totalQuota,
      usedQuota: usedQuota ?? this.usedQuota,
    );
  }

  // 当前选中的套餐（多套餐时为选中那个，否则为默认）
  PlanSubscription? get currentSubscription {
    if (subscriptions.isEmpty) return null;
    if (activeSubscriptionId == null) return subscriptions.first;
    return subscriptions.firstWhere(
      (s) => s.subscriptionId == activeSubscriptionId,
      orElse: () => subscriptions.first,
    );
  }

  /// 序列化为 JSON（用于本地缓存）
  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'planId': planId,
    'planName': planName,
    'expiresAt': expiresAt?.toIso8601String(),
    'tokenBalance': {
      'balanceTokens': tokenBalance.balanceTokens,
      'freeTokensRemaining': tokenBalance.freeTokensRemaining,
      'totalTokens': tokenBalance.totalTokens,
      'usedTokens': tokenBalance.usedTokens,
      'totalQuota': tokenBalance.totalQuota,
      'usedQuota': tokenBalance.usedQuota,
      'quotaRemaining': tokenBalance.quotaRemaining,
      'rechargeBalance': tokenBalance.rechargeBalance,
    },
    'apiPolicies': apiPolicies.map((p) => p.toJson()).toList(),
    'defaultConfigs': defaultConfigs.map((c) => {'functionType': c.functionType, 'modelPattern': c.modelPattern}).toList(),
    'subscriptions': subscriptions.map((s) => {
      'subscriptionId': s.subscriptionId,
      'planId': s.planId,
      'planName': s.planName,
      'expiresAt': s.expiresAt?.toIso8601String(),
      'status': s.status,
      'defaultConfigs': s.defaultConfigs.map((c) => {'functionType': c.functionType, 'modelPattern': c.modelPattern}).toList(),
      'apiPolicies': s.apiPolicies.map((p) => p.toJson()).toList(),
      'allowedModels': s.allowedModels,
      'features': s.features,
      'isRecommended': s.isRecommended,
    }).toList(),
    'activeSubscriptionId': activeSubscriptionId,
    'totalQuota': totalQuota,
    'usedQuota': usedQuota,
  };

  /// 从 JSON 反序列化（用于读取本地缓存）
  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    TokenBalance parseTokenBalance(dynamic raw) {
      if (raw is! Map) return const TokenBalance(balanceTokens: 0, freeTokensRemaining: 0, totalTokens: 0, usedTokens: 0);
      return TokenBalance(
        balanceTokens: (raw['balanceTokens'] as num?)?.toInt() ?? 0,
        freeTokensRemaining: (raw['freeTokensRemaining'] as num?)?.toInt() ?? 0,
        totalTokens: (raw['totalTokens'] as num?)?.toInt() ?? 0,
        usedTokens: (raw['usedTokens'] as num?)?.toInt() ?? 0,
        totalQuota: (raw['totalQuota'] as num?)?.toInt() ?? 0,
        usedQuota: (raw['usedQuota'] as num?)?.toInt() ?? 0,
        quotaRemaining: (raw['quotaRemaining'] as num?)?.toInt() ?? 0,
        rechargeBalance: (raw['rechargeBalance'] as num?)?.toInt() ?? 0,
      );
    }

    return SubscriptionState(
      isActive: json['isActive'] as bool? ?? false,
      planId: json['planId'] as String?,
      planName: json['planName'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
      tokenBalance: parseTokenBalance(json['tokenBalance']),
      apiPolicies: (json['apiPolicies'] as List<dynamic>?)
              ?.map((e) => ApiPolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultConfigs: (json['defaultConfigs'] as List<dynamic>?)
              ?.map((e) => DefaultConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subscriptions: (json['subscriptions'] as List<dynamic>?)
              ?.map((e) => PlanSubscription.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeSubscriptionId: json['activeSubscriptionId'] as String?,
      totalQuota: (json['totalQuota'] as num?)?.toInt() ?? 0,
      usedQuota: (json['usedQuota'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  static const _cacheKey = 'subscription_state_cache';
  static const _cacheMaxAge = Duration(hours: 24);

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<SubscriptionState> build() async {
    return _fetchSubscriptionInternal();
  }

  /// 从本地缓存加载套餐状态
  Future<SubscriptionState?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson == null) return null;

      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(cached['cachedAt'] ?? '');
      if (cachedAt == null) return null;

      final age = DateTime.now().difference(cachedAt);
      if (age > _cacheMaxAge) {
        AppLogger().i('Subscription', '缓存已过期 (${age.inHours}h)，忽略');
        return null;
      }

      final state = SubscriptionState.fromJson(cached['state'] as Map<String, dynamic>);
      AppLogger().i('Subscription', '从缓存加载套餐数据: plan=${state.planName}, age=${age.inMinutes}min');
      return state;
    } catch (e) {
      AppLogger().w('Subscription', '加载缓存失败: $e');
      return null;
    }
  }

  /// 保存套餐状态到本地缓存
  Future<void> _saveCache(SubscriptionState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'cachedAt': DateTime.now().toIso8601String(),
        'state': state.toJson(),
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
      AppLogger().i('Subscription', '套餐数据已缓存');
    } catch (e) {
      AppLogger().w('Subscription', '保存缓存失败: $e');
    }
  }

  /// 清除本地缓存
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      AppLogger().i('Subscription', '套餐缓存已清除');
    } catch (e) {
      AppLogger().w('Subscription', '清除缓存失败: $e');
    }
  }

  Future<SubscriptionState> _fetchSubscriptionInternal({String? subscriptionId}) async {
    try {
      final endpoint = subscriptionId != null
          ? '/subscription/switch/$subscriptionId'
          : '/subscription';
      final response = await CloudApiService.instance.get(endpoint);
      final data = response.data['data'];

      // 并行拉取套餐列表（用来给每个 subscription 注入 features 和 isRecommended）
      // 仅当 /subscription 没有返回这些字段时才需要从 /subscription/plans 取
      List<PlanModel> allPlans = const [];
      try {
        final plansResp = await CloudApiService.instance.get('/subscription/plans');
        final List<dynamic> plansData = plansResp.data['data'];
        allPlans = plansData.map((e) => PlanModel.fromJson(e)).toList();
      } catch (_) {}

      // 索引：planId -> PlanModel（用于补充 features/isRecommended）
      final planById = {for (final p in allPlans) p.id: p};

      List<PlanSubscription> _enrich(List<dynamic> raw) {
        return raw.map((e) {
          final sub = PlanSubscription.fromJson(e as Map<String, dynamic>);
          final p = planById[sub.planId];
          if (p == null) return sub;
          // 补 features 和 isRecommended
          return PlanSubscription(
            subscriptionId: sub.subscriptionId,
            planId: sub.planId,
            planName: sub.planName,
            expiresAt: sub.expiresAt,
            status: sub.status,
            defaultConfigs: sub.defaultConfigs,
            apiPolicies: sub.apiPolicies,
            allowedModels: sub.allowedModels,
            features: p.features,
            isRecommended: p.isRecommended,
          );
        }).toList();
      }

      final policies = (data['apiPolicies'] as List<dynamic>?)
          ?.map((e) => ApiPolicy.fromJson(e))
          .toList() ?? [];
      final defaultConfigs = (data['defaultConfigs'] as List<dynamic>?)
          ?.map((e) => DefaultConfig.fromJson(e))
          .toList() ?? [];

      // 多订阅列表（若 /subscription 已含 features 则用之，否则用 /subscription/plans 补）
      final rawSubs = data['subscriptions'] as List<dynamic>?;
      final hasFeaturesInResp = (rawSubs?.isNotEmpty ?? false) &&
          (rawSubs!.first as Map)['features'] != null;
      final subscriptions = hasFeaturesInResp
          ? rawSubs
              .map((e) => PlanSubscription.fromJson(e as Map<String, dynamic>))
              .toList()
          : _enrich(rawSubs ?? const []);

      TokenBalance tokenBalance;
      try {
        final balanceResponse = await CloudApiService.instance.get('/subscription/balance');
        final balanceData = balanceResponse.data['data'] as Map<String, dynamic>;
        tokenBalance = TokenBalance.fromJson(balanceData);
      } catch (_) {
        tokenBalance = const TokenBalance(
          balanceTokens: 0,
          freeTokensRemaining: 0,
          totalTokens: 0,
          usedTokens: 0,
        );
      }

      final result = SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        tokenBalance: tokenBalance,
        apiPolicies: policies,
        defaultConfigs: defaultConfigs,
        subscriptions: subscriptions,
        activeSubscriptionId: data['subscriptionId']?.toString(),
        totalQuota: _parseInt(data['totalQuota']),
        usedQuota: _parseInt(data['usedQuota']),
      );

      // 成功获取后保存到缓存
      await _saveCache(result);
      return result;
    } catch (e) {
      // API 请求失败时：
      // - 401/token 过期：尝试返回缓存，无缓存则返回空状态
      // - 其他错误：尝试返回缓存，无缓存则 rethrow
      AppLogger().w('Subscription', '获取套餐数据失败: $e');
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.contains('Unauthorized')) {
        final cached = await _loadCache();
        if (cached != null) {
          AppLogger().i('Subscription', '401 时返回缓存数据');
          return cached;
        }
        return const SubscriptionState();
      }
      // 其他错误（网络超时等）也尝试返回缓存
      final cached = await _loadCache();
      if (cached != null) {
        AppLogger().i('Subscription', '网络错误时返回缓存数据');
        return cached;
      }
      rethrow;
    }
  }

  Future<void> fetchSubscription() async {
    state = const AsyncLoading<SubscriptionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchSubscriptionInternal());
    _autoSyncCloudConfig();
  }

  // 切换套餐
  Future<void> switchSubscription(String subscriptionId) async {
    state = const AsyncLoading<SubscriptionState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchSubscriptionInternal(subscriptionId: subscriptionId));
    _autoSyncCloudConfig();
  }

  /// 自动同步云端配置到本地 MultiApiConfig
  /// 在 fetchSubscription / switchSubscription 成功后调用
  void _autoSyncCloudConfig() {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.defaultConfigs.isEmpty && current.apiPolicies.isEmpty) return;

    // 异步同步，不阻塞 UI
    CloudConfigSyncService.syncCloudDefaults(
      defaultConfigs: current.defaultConfigs,
      apiPolicies: current.apiPolicies,
    ).then((result) {
      AppLogger().i('Subscription', '自动同步云端配置: ${result.message}');
    }).catchError((e) {
      AppLogger().w('Subscription', '自动同步云端配置失败: $e');
    });
  }

  Future<void> refreshBalance() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final balanceResponse = await CloudApiService.instance.get('/subscription/balance');
      final balanceData = balanceResponse.data['data'] as Map<String, dynamic>;
      final tokenBalance = TokenBalance.fromJson(balanceData);

      final updated = current.copyWith(tokenBalance: tokenBalance);
      state = AsyncData(updated);
      // 余额更新后也保存缓存
      await _saveCache(updated);
    } catch (_) {}
  }
}

final subscriptionNotifierProvider = AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});

final subscriptionPlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await CloudApiService.instance.get('/subscription/plans?type=monthly');
  final List<dynamic> data = response.data['data'];
  // 过滤掉下架套餐（isActive=false），保证 Store 列表只展示上架套餐
  return data
      .map((e) => PlanModel.fromJson(e))
      .where((p) => p.isActive)
      .toList();
});

final packagePlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await CloudApiService.instance.get('/subscription/plans?type=recharge');
  final List<dynamic> data = response.data['data'];
  return data
      .map((e) => PlanModel.fromJson(e))
      .where((p) => p.isActive)
      .toList();
});

final userTokenBalanceProvider = FutureProvider<TokenBalance>((ref) async {
  try {
    final response = await CloudApiService.instance.get('/subscription/balance');
    final data = response.data['data'] as Map<String, dynamic>;
    return TokenBalance.fromJson(data);
  } catch (e) {
    return const TokenBalance(
      balanceTokens: 0,
      freeTokensRemaining: 0,
      totalTokens: 0,
      usedTokens: 0,
    );
  }
});

@Deprecated('使用 userTokenBalanceProvider 替代')
final userBalanceProvider = FutureProvider<int>((ref) async {
  try {
    final response = await CloudApiService.instance.get('/subscription/balance');
    return response.data['data']['balanceCents'] as int? ?? 0;
  } catch (e) {
    return 0;
  }
});

final cloudApiEnabledProvider = AsyncNotifierProvider<CloudApiEnabledNotifier, bool>(() {
  return CloudApiEnabledNotifier();
});

class CloudApiEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return SecureStorageService().getCloudApiEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    await SecureStorageService().saveCloudApiEnabled(enabled);
    state = AsyncData(enabled);
  }
}
