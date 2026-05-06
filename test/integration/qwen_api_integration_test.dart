import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// Qwen API 集成测试
/// 
/// 运行方式:
/// ```bash
/// flutter test test/integration/qwen_api_integration_test.dart --dart-define=QWEN_API_KEY=your_api_key
/// ```
/// 
/// 或者设置环境变量:
/// ```bash
/// set QWEN_API_KEY=your_api_key
/// flutter test test/integration/qwen_api_integration_test.dart
/// ```
void main() {
  group('Qwen API Integration Tests', () {
    late ApiService apiService;
    String? apiKey;

    setUp(() {
      apiService = ApiService();
      
      // 从环境变量或 dart-define 获取 API Key
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
    });

    test('API Key should be provided', () {
      expect(apiKey, isNotNull,
          reason: '请提供 QWEN_API_KEY 环境变量进行测试');
      expect(apiKey, isNotEmpty,
          reason: 'QWEN_API_KEY 不能为空');
      
      if (apiKey != null && apiKey!.isNotEmpty) {
        print('✓ API Key 已提供: ${apiKey!.substring(0, apiKey!.length > 10 ? 10 : apiKey!.length)}...');
      }
    });

    group('Configuration', () {
      test('should configure with Qwen', () {
        // 跳过测试如果没有 API Key
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        expect(apiService.isConfigured, isTrue);
        expect(apiService.currentConfig, isNotNull);
        expect(apiService.currentConfig!.provider, AiProvider.qwen);
        print('✓ Qwen API 配置成功');
        print('  - Base URL: ${apiService.currentConfig!.baseUrl}');
        print('  - Model: ${apiService.currentConfig!.defaultModel}');
        print('  - ASR Model: ${apiService.currentConfig!.asrModel}');
      });

      test('should validate API key', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n正在验证 API Key...');
        final isValid = await apiService.validateApiKey();
        
        if (isValid) {
          print('✓ API Key 验证通过');
        } else {
          print('✗ API Key 验证失败');
        }
        
        expect(isValid, isTrue,
            reason: 'API Key 无效或无法连接到 Qwen 服务');
      });
    });

    group('Chat Completion', () {
      test('should generate text response', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n测试文本对话...');
        final response = await apiService.chatCompletion(
          '你好，请用一句话介绍自己',
        );

        expect(response, isNotNull);
        expect(response, isNotEmpty);
        print('✓ 对话测试通过');
        print('  响应: $response');
      });

      test('should generate title', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n测试标题生成...');
        final title = await apiService.generateTitle(
          '今天开了一个很重要的会议，讨论了产品发布计划和营销策略',
        );

        expect(title, isNotNull);
        expect(title, isNotEmpty);
        expect(title.length, lessThanOrEqualTo(20),
            reason: '标题应该不超过20个字符');
        print('✓ 标题生成测试通过');
        print('  标题: $title');
      });

      test('should summarize text', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n测试文本摘要...');
        final summary = await apiService.summarizeText(
          '今天的会议主要讨论了三个方面：第一，产品发布计划定在下周三；'
          '第二，营销策略需要调整，重点放在社交媒体推广；'
          '第三，团队需要增加两名开发人员。',
        );

        expect(summary, isNotNull);
        expect(summary, isNotEmpty);
        print('✓ 摘要测试通过');
        print('  摘要: $summary');
      });
    });

    group('Transcription (if audio file provided)', () {
      test('should transcribe audio file', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过测试: 未提供 QWEN_API_KEY');
          return;
        }

        // 检查是否有测试音频文件
        const testAudioPath = 'test/assets/test_audio.wav';
        final audioFile = File(testAudioPath);
        
        if (!await audioFile.exists()) {
          markTestSkipped('跳过测试: 未找到测试音频文件 $testAudioPath');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n测试语音转写...');
        print('音频文件: $testAudioPath');
        
        final transcription = await apiService.transcribeAudio(
          testAudioPath,
          onProgress: (step, detail) {
            print('  [$step] $detail');
          },
        );

        expect(transcription, isNotNull);
        expect(transcription, isNotEmpty);
        print('✓ 转写测试通过');
        print('  转写结果: $transcription');
      });
    });

    group('Error Handling', () {
      test('should handle invalid API key', () async {
        apiService.configure(
          apiKey: 'invalid-api-key',
          config: AiModelConfig.qwen,
        );

        print('\n测试无效 API Key...');
        final isValid = await apiService.validateApiKey();
        
        expect(isValid, isFalse);
        print('✓ 正确识别无效 API Key');
      });

      test('should throw when not configured', () async {
        print('\n测试未配置状态...');
        
        expect(
          () => apiService.chatCompletion('test'),
          throwsException,
        );
        print('✓ 未配置时正确抛出异常');
      });
    });
  });
}
