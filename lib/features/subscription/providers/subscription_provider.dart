import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/billing_service.dart';
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

  const PlanSubscription({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    this.expiresAt,
    this.status = 'active',
    this.defaultConfigs = const [],
    this.apiPolicies = const [],
    this.allowedModels = const [],
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
}

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
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

  Future<SubscriptionState> _fetchSubscriptionInternal({String? subscriptionId}) async {
    try {
      final endpoint = subscriptionId != null
          ? '/subscription/switch/$subscriptionId'
          : '/subscription';
      final response = await CloudApiService.instance.get(endpoint);
      final data = response.data['data'];

      final policies = (data['apiPolicies'] as List<dynamic>?)
          ?.map((e) => ApiPolicy.fromJson(e))
          .toList() ?? [];
      final defaultConfigs = (data['defaultConfigs'] as List<dynamic>?)
          ?.map((e) => DefaultConfig.fromJson(e))
          .toList() ?? [];

      // 多订阅列表
      final subscriptions = (data['subscriptions'] as List<dynamic>?)
              ?.map((e) => PlanSubscription.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

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

      return SubscriptionState(
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
      );
    } catch (e) {
      return const SubscriptionState();
    }
  }

  Future<void> fetchSubscription() async {
    state = const AsyncLoading().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchSubscriptionInternal());
  }

  // 切换套餐
  Future<void> switchSubscription(String subscriptionId) async {
    state = const AsyncLoading().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchSubscriptionInternal(subscriptionId: subscriptionId));
  }

  Future<void> refreshBalance() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final balanceResponse = await CloudApiService.instance.get('/subscription/balance');
      final balanceData = balanceResponse.data['data'] as Map<String, dynamic>;
      final tokenBalance = TokenBalance.fromJson(balanceData);

      state = AsyncData(current.copyWith(tokenBalance: tokenBalance));
    } catch (_) {}
  }
}

final subscriptionNotifierProvider = AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});

final subscriptionPlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await CloudApiService.instance.get('/subscription/plans?type=subscription');
  final List<dynamic> data = response.data['data'];
  return data.map((e) => PlanModel.fromJson(e)).toList();
});

final packagePlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await CloudApiService.instance.get('/subscription/plans?type=package');
  final List<dynamic> data = response.data['data'];
  return data.map((e) => PlanModel.fromJson(e)).toList();
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
