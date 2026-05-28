import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/secure_storage_service.dart';
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

/// 场景默认模型配置
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

class SubscriptionState {
  final bool isActive;
  final String? planId;
  final String? planName;
  final int totalQuota;
  final int usedQuota;
  final DateTime? expiresAt;
  final int balanceCents;
  final List<ApiPolicy> apiPolicies;
  final List<DefaultConfig> defaultConfigs;

  const SubscriptionState({
    this.isActive = false,
    this.planId,
    this.planName,
    this.totalQuota = 0,
    this.usedQuota = 0,
    this.expiresAt,
    this.balanceCents = 0,
    this.apiPolicies = const [],
    this.defaultConfigs = const [],
  });

  SubscriptionState copyWith({
    bool? isActive,
    String? planId,
    String? planName,
    int? totalQuota,
    int? usedQuota,
    DateTime? expiresAt,
    int? balanceCents,
    List<ApiPolicy>? apiPolicies,
    List<DefaultConfig>? defaultConfigs,
  }) {
    return SubscriptionState(
      isActive: isActive ?? this.isActive,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      totalQuota: totalQuota ?? this.totalQuota,
      usedQuota: usedQuota ?? this.usedQuota,
      expiresAt: expiresAt ?? this.expiresAt,
      balanceCents: balanceCents ?? this.balanceCents,
      apiPolicies: apiPolicies ?? this.apiPolicies,
      defaultConfigs: defaultConfigs ?? this.defaultConfigs,
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
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      final policies = (data['apiPolicies'] as List<dynamic>?)
          ?.map((e) => ApiPolicy.fromJson(e))
          .toList() ?? [];
      final defaultConfigs = (data['defaultConfigs'] as List<dynamic>?)
          ?.map((e) => DefaultConfig.fromJson(e))
          .toList() ?? [];
      final state = SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: _parseInt(data['totalQuota']),
        usedQuota: _parseInt(data['usedQuota']),
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: _parseInt(data['balanceCents']),
        apiPolicies: policies,
        defaultConfigs: defaultConfigs,
      );
      return state;
    } catch (e, stack) {
      return const SubscriptionState();
    }
  }

  Future<void> fetchSubscription() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      final policies = (data['apiPolicies'] as List<dynamic>?)
          ?.map((e) => ApiPolicy.fromJson(e))
          .toList() ?? [];
      final defaultConfigs = (data['defaultConfigs'] as List<dynamic>?)
          ?.map((e) => DefaultConfig.fromJson(e))
          .toList() ?? [];
      state = AsyncData(SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: _parseInt(data['totalQuota']),
        usedQuota: _parseInt(data['usedQuota']),
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: _parseInt(data['balanceCents']),
        apiPolicies: policies,
        defaultConfigs: defaultConfigs,
      ));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
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
