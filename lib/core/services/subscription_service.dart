import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cloud_api_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

class SubscriptionInfo {
  final bool isActive;
  final String? planId;
  final String? planName;
  final DateTime? expiresAt;
  final String? status;

  SubscriptionInfo({
    this.isActive = false,
    this.planId,
    this.planName,
    this.expiresAt,
    this.status,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      isActive: json['status'] == 'active',
      planId: json['planId'] as String?,
      planName: json['planName'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      status: json['status'] as String?,
    );
  }
}

class SubscriptionService {
  Future<bool> isSubscribed() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      return data['status'] == 'active';
    } catch (e) {
      return false;
    }
  }

  Future<String?> getSubscriptionPlan() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'];
      return data['planName'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<SubscriptionInfo?> getSubscriptionInfo() async {
    try {
      final response = await CloudApiService.instance.get('/subscription');
      final data = response.data['data'] as Map<String, dynamic>;
      return SubscriptionInfo.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createSubscription(String planId) async {
    try {
      final response = await CloudApiService.instance.post(
        '/subscription',
        data: {'planId': planId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final response = await CloudApiService.instance.delete('/subscription');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
