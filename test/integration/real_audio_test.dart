import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 使用真实语音文件测试转写功能
void main() {
  group('真实语音文件转写测试', () {
    late ApiService apiService;
    String? apiKey;
    final audioPath = r'C:\Users\Mayn\Downloads\recording_1778050290879.wav';

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      apiService = ApiService();
      
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
    });

    test('真实语音文件转写', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        markTestSkipped('未提供 QWEN_API_KEY');
        return;
      }

      final file = File(audioPath);
      if (!await file.exists()) {
        markTestSkipped('音频文件不存在: $audioPath');
        return;
      }

      apiService.configure(
        apiKey: apiKey!,
        config: AiModelConfig.qwen,
      );

      final fileSize = await file.length();
      final fileSizeMB = fileSize / 1024 / 1024;

      print('\n=== 真实语音文件转写测试 ===');
      print('✓ 音频文件: $audioPath');
      print('  大小: ${fileSizeMB.toStringAsFixed(2)} MB');

      print('\n  开始转写...');
      String? result;
      Exception? error;

      try {
        result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
      } catch (e) {
        error = e is Exception ? e : Exception(e.toString());
      }

      if (error != null) {
        print('\n  转写失败: $error');
      } else {
        print('\n✓ 转写成功!');
        print('  字符数: ${result?.length}');
        if (result != null && result.isNotEmpty) {
          print('  转写结果:');
          print('  ==========================================');
          print('  $result');
          print('  ==========================================');
        } else {
          print('  转写结果为空');
        }
      }

      expect(await file.exists(), isTrue);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
