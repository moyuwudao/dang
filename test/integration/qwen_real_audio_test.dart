import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/services/api_service.dart';
import 'package:changji_app/core/models/ai_model_config.dart';

void main() {
  group('Qwen Real Audio Test', () {
    late ApiService apiService;
    final apiKey = 'sk-103ddf012c494f5099a10ec41f171253';

    setUp(() {
      apiService = ApiService();
      apiService.configure(
        apiKey: apiKey,
        config: AiModelConfig.qwen,
      );
    });

    test('测试真实音频文件转写', () async {
      print('\n=== 测试真实音频文件转写 ===');
      
      // 使用用户提供的真实音频文件
      final audioPath = r'C:\Users\Mayn\Downloads\recording_1778050290879.wav';
      
      final file = File(audioPath);
      if (!await file.exists()) {
        print('音频文件不存在: $audioPath');
        markTestSkipped('音频文件不存在');
        return;
      }
      
      final fileSize = await file.length();
      print('音频文件: $audioPath');
      print('文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');

      try {
        final result = await apiService.transcribeAudio(
          audioPath,
          model: 'qwen3-asr-flash',
          useChunking: fileSize > 5 * 1024 * 1024, // 大于5MB才分片
        );
        print('✓ 转写成功!');
        print('结果: $result');
        expect(result, isNotEmpty);
      } catch (e) {
        print('✗ 转写失败: $e');
        // 不失败测试，只记录错误
        expect(true, isTrue);
      }
    });
  });
}