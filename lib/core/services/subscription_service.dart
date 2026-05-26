import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

class SubscriptionService {
  Future<bool> isSubscribed() async {
    return false;
  }

  Future<String?> getSubscriptionPlan() async {
    return null;
  }
}
