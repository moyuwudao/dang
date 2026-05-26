import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiKeyServiceProvider = Provider<ApiKeyService>((ref) {
  return ApiKeyService();
});

class ApiKeyService {
  Future<String?> getApiKey() async {
    return null;
  }

  Future<void> saveApiKey(String apiKey) async {
    // TODO: Implement
  }

  Future<void> deleteApiKey() async {
    // TODO: Implement
  }
}
