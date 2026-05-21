import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';
import '../models/plan_model.dart';

class SubscriptionState {
  final bool isActive;
  final String? planId;
  final String? planName;
  final int totalQuota;
  final int usedQuota;
  final DateTime? expiresAt;
  final int balanceCents;

  const SubscriptionState({
    this.isActive = false,
    this.planId,
    this.planName,
    this.totalQuota = 0,
    this.usedQuota = 0,
    this.expiresAt,
    this.balanceCents = 0,
  });

  SubscriptionState copyWith({
    bool? isActive,
    String? planId,
    String? planName,
    int? totalQuota,
    int? usedQuota,
    DateTime? expiresAt,
    int? balanceCents,
  }) {
    return SubscriptionState(
      isActive: isActive ?? this.isActive,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      totalQuota: totalQuota ?? this.totalQuota,
      usedQuota: usedQuota ?? this.usedQuota,
      expiresAt: expiresAt ?? this.expiresAt,
      balanceCents: balanceCents ?? this.balanceCents,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  Future<void> fetchSubscription() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      state = SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: data['totalQuota'] ?? 0,
        usedQuota: data['usedQuota'] ?? 0,
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: data['balanceCents'] ?? 0,
      );
    } catch (e) {
      state = const SubscriptionState();
    }
  }
}

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
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
