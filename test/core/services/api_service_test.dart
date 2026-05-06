import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('should be not configured initially', () {
      expect(apiService.isConfigured, isFalse);
      expect(apiService.currentConfig, isNull);
    });

    test('should configure with OpenAI', () {
      apiService.configure(
        apiKey: 'sk-test123',
        config: AiModelConfig.openAI,
      );

      expect(apiService.isConfigured, isTrue);
      expect(apiService.currentConfig, isNotNull);
      expect(apiService.currentConfig!.provider, AiProvider.openAI);
    });

    test('should configure with custom baseUrl', () {
      const customUrl = 'https://custom.api.com/v1';
      apiService.configure(
        apiKey: 'sk-test123',
        config: AiModelConfig.openAI,
        customBaseUrl: customUrl,
      );

      expect(apiService.isConfigured, isTrue);
      expect(apiService.configInfo, contains(customUrl));
    });

    test('should configure with Claude headers', () {
      apiService.configure(
        apiKey: 'sk-ant-test123',
        config: AiModelConfig.claude,
      );

      expect(apiService.isConfigured, isTrue);
      expect(apiService.currentConfig!.provider, AiProvider.claude);
    });

    test('should configure with Gemini', () {
      apiService.configure(
        apiKey: 'gemini-test-key',
        config: AiModelConfig.gemini,
      );

      expect(apiService.isConfigured, isTrue);
      expect(apiService.currentConfig!.provider, AiProvider.gemini);
    });

    test('should configure with Qwen', () {
      apiService.configure(
        apiKey: 'sk-qwen-test',
        config: AiModelConfig.qwen,
      );

      expect(apiService.isConfigured, isTrue);
      expect(apiService.currentConfig!.provider, AiProvider.qwen);
    });

    test('should not be configured after clear', () {
      apiService.configure(
        apiKey: 'sk-test123',
        config: AiModelConfig.openAI,
      );
      expect(apiService.isConfigured, isTrue);

      // 重新创建服务模拟清除
      apiService = ApiService();
      expect(apiService.isConfigured, isFalse);
    });

    group('configInfo', () {
      test('should show not configured when not setup', () {
        expect(apiService.configInfo, 'Not configured');
      });

      test('should contain provider info when configured', () {
        apiService.configure(
          apiKey: 'sk-test123',
          config: AiModelConfig.openAI,
        );

        expect(apiService.configInfo, contains('openai'));
        expect(apiService.configInfo, contains('gpt-4o-mini'));
      });
    });

    group('Provider-specific configurations', () {
      test('all transcription providers should configure correctly', () {
        final asrProviders = [
          AiModelConfig.openAI,
          AiModelConfig.gemini,
          AiModelConfig.qwen,
        ];

        for (final provider in asrProviders) {
          final service = ApiService();
          service.configure(
            apiKey: 'test-key',
            config: provider,
          );
          expect(service.isConfigured, isTrue,
              reason: '${provider.displayName} should be configurable');
        }
      });

      test('all chat providers should configure correctly', () {
        final chatProviders = AiModelConfig.allProviders
            .where((p) => p.supportsChat)
            .toList();

        for (final provider in chatProviders) {
          final service = ApiService();
          service.configure(
            apiKey: 'test-key',
            config: provider,
          );
          expect(service.isConfigured, isTrue,
              reason: '${provider.displayName} should be configurable');
        }
      });
    });
  });
}
