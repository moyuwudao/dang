import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 验证 API Key 权限和模型可用性
void main() {
  group('API 权限验证', () {
    late ApiService apiService;
    String? apiKey;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      apiService = ApiService();
      
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
    });

    test('验证所有模型可用性', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        markTestSkipped('未提供 QWEN_API_KEY');
        return;
      }

      apiService.configure(
        apiKey: apiKey!,
        config: AiModelConfig.qwen,
      );

      print('\n=== 验证 API Key 权限 ===');
      print('API Key: ${apiKey!.substring(0, 8)}...');
      
      // 测试聊天功能
      print('\n1. 测试聊天功能 (qwen3.6-flash)...');
      try {
        final chatResponse = await apiService.chatCompletion('Hello');
        print('✓ 聊天功能正常');
        print('  响应: ${chatResponse.substring(0, chatResponse.length > 50 ? 50 : chatResponse.length)}...');
      } catch (e) {
        print('✗ 聊天功能失败: $e');
      }

      // 测试标题生成
      print('\n2. 测试标题生成功能...');
      try {
        final title = await apiService.generateTitle('这是一段测试文本');
        print('✓ 标题生成正常');
        print('  标题: $title');
      } catch (e) {
        print('✗ 标题生成失败: $e');
      }

      // 测试文本摘要
      print('\n3. 测试文本摘要功能...');
      try {
        final summary = await apiService.summarizeText('这是一段需要摘要的测试文本，用于验证API权限。');
        print('✓ 文本摘要正常');
        print('  摘要: ${summary.substring(0, summary.length > 50 ? 50 : summary.length)}...');
      } catch (e) {
        print('✗ 文本摘要失败: $e');
      }

      // 测试音频转写（使用真实文件）
      print('\n4. 测试音频转写功能...');
      final audioPath = r'C:\Users\Mayn\Downloads\recording_1778050290879.wav';
      final audioFile = File(audioPath);
      
      if (await audioFile.exists()) {
        print('  使用真实音频文件: $audioPath');
        try {
          final result = await apiService.transcribeAudio(
            audioPath,
            useChunking: false,
            onProgress: (step, detail) => print('    [$step] $detail'),
          );
          print('✓ 音频转写正常');
          print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        } catch (e) {
          print('✗ 音频转写失败: $e');
        }
      } else {
        print('  真实音频文件不存在，跳过音频测试');
      }

      print('\n=== 权限验证完成 ===');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
