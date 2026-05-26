import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';
import '../models/plan_model.dart';

class ApiPolicy {
  final String provider;
  final String? modelPattern;
  final double multiplier;
  final bool isAllowed;

  const ApiPolicy({
    required this.provider,
    this.modelPattern,
    required this.multiplier,
    this.isAllowed = true,
  });

  factory ApiPolicy.fromJson(Map<String, dynamic> json) {
    return ApiPolicy(
      provider: json['provider'] ?? '',
      modelPattern: json['modelPattern'],
      multiplier: (json['multiplier'] ?? 1.0).toDouble(),
      isAllowed: json['isAllowed'] ?? true,
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

  const SubscriptionState({
    this.isActive = false,
    this.planId,
    this.planName,
    this.totalQuota = 0,
    this.usedQuota = 0,
    this.expiresAt,
    this.balanceCents = 0,
    this.apiPolicies = const [],
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
    );
  }
}

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      final policies = (data['apiPolicies'] as List<dynamic>?)
          ?.map((e) => ApiPolicy.fromJson(e))
          .toList() ?? [];
      return SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: data['totalQuota'] ?? 0,
        usedQuota: data['usedQuota'] ?? 0,
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: data['balanceCents'] ?? 0,
        apiPolicies: policies,
      );
    } catch (e) {
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
      state = AsyncData(SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: data['totalQuota'] ?? 0,
        usedQuota: data['usedQuota'] ?? 0,
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: data['balanceCents'] ?? 0,
        apiPolicies: policies,
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

final cloudApiEnabledProvider = StateProvider<bool>((ref) => false);
