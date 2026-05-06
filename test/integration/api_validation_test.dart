import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

void main() {
  group('API 验证测试', () {
    late ApiService apiService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      apiService = ApiService();
    });

    test('验证 Qwen API Key 是否有效', () async {
      final apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey.isEmpty) return;

      apiService.configure(
        apiKey: apiKey,
        config: AiModelConfig.qwen,
      );

      print('\n=== 验证 Qwen API Key ===');
      
      try {
        final response = await apiService.chatCompletion('Hello');
        print('✓ API Key 有效!');
        print('  响应长度: ${response.length}');
        print('  响应预览: ${response.substring(0, response.length > 50 ? 50 : response.length)}...');
      } catch (e) {
        print('✗ API Key 无效或服务不可用: $e');
      }
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
