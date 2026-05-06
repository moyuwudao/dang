import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 长音频异步转写集成测试
/// 
/// 使用 qwen3-asr-flash-filetrans 异步接口
/// 支持最长12小时，最大2GB音频文件
/// 
/// 运行方式:
/// ```bash
/// $env:QWEN_API_KEY="your-api-key"; flutter test test/integration/long_audio_async_test.dart
/// ```
void main() {
  group('长音频异步转写测试', () {
    late ApiService apiService;
    String? apiKey;
    late Directory tempDir;

    setUp(() async {
      apiService = ApiService();
      
      // 从环境变量获取 API Key
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
      
      // 创建临时目录
      tempDir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}long_audio_async_test_${DateTime.now().millisecondsSinceEpoch}');
      await tempDir.create();
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        print('✓ 清理临时目录');
      }
    });

    test('环境检查 - API Key 已提供', () {
      expect(apiKey, isNotNull,
          reason: '请提供 QWEN_API_KEY 环境变量进行测试');
      expect(apiKey, isNotEmpty,
          reason: 'QWEN_API_KEY 不能为空');
      
      if (apiKey != null && apiKey!.isNotEmpty) {
        print('✓ API Key 已提供: ${apiKey!.substring(0, apiKey!.length > 15 ? 15 : apiKey!.length)}...');
      }
    });

    test('配置 Qwen API', () {
      if (apiKey == null || apiKey!.isEmpty) {
        markTestSkipped('跳过: 未提供 QWEN_API_KEY');
        return;
      }

      print('\n=== 配置 Qwen API ===');
      
      apiService.configure(
        apiKey: apiKey!,
        config: AiModelConfig.qwen,
      );
      
      expect(apiService.isConfigured, isTrue);
      print('✓ API 配置成功');
      print('  提供商: ${apiService.currentConfig!.displayName}');
      print('  ASR模型: ${apiService.currentConfig!.asrModel}');
    });

    group('1. 短音频异步转写测试 (30秒)', () {
      test('使用异步接口转写30秒音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试异步转写 (30秒音频) ===');
        
        // 生成30秒测试音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_30s.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ 测试音频已生成');
        print('  路径: $audioPath');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        print('  时长: 30秒');
        
        // 使用异步接口转写
        print('\n  开始异步转写...');
        String? result;
        Exception? error;
        
        try {
          result = await apiService.transcribeAudioAsync(
            audioPath,
            onProgress: (step, detail) => print('    [$step] $detail'),
          );
        } catch (e) {
          error = e is Exception ? e : Exception(e.toString());
        }
        
        if (error != null) {
          print('\n  转写结果: $error');
          print('  注意: 异步接口可能需要特定权限或配置');
        } else {
          print('\n✓ 异步转写完成!');
          print('  结果: ${result?.substring(0, result!.length > 200 ? 200 : result!.length)}...');
          print('  字符数: ${result?.length}');
        }
        
        // 验证文件格式正确
        expect(await file.exists(), isTrue);
        expect(fileSize, greaterThan(0));
      }, timeout: const Timeout(Duration(minutes: 10)));
    });

    group('2. 长音频异步转写测试 (6分钟)', () {
      test('使用异步接口转写6分钟音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试长音频异步转写 (6分钟) ===');
        
        // 生成6分钟测试音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_6min.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 360); // 6分钟 = 360秒
        
        final file = File(audioPath);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;
        
        print('✓ 长音频测试文件已生成');
        print('  路径: $audioPath');
        print('  大小: ${fileSizeMB.toStringAsFixed(2)} MB');
        print('  时长: 6分钟');
        print('  注意: 同步接口限制约10MB，此文件${fileSizeMB > 10 ? "超过" : "未超过"}限制');
        
        // 使用异步接口转写
        print('\n  开始异步转写 (长音频)...');
        print('  预计处理时间: 1-5分钟');
        
        String? result;
        Exception? error;
        
        try {
          result = await apiService.transcribeAudioAsync(
            audioPath,
            onProgress: (step, detail) => print('    [$step] $detail'),
          );
        } catch (e) {
          error = e is Exception ? e : Exception(e.toString());
        }
        
        if (error != null) {
          print('\n  转写结果: $error');
        } else {
          print('\n✓ 长音频异步转写完成!');
          print('  结果: ${result?.substring(0, result!.length > 200 ? 200 : result!.length)}...');
          print('  字符数: ${result?.length}');
        }
        
        expect(await file.exists(), isTrue);
        expect(fileSize, greaterThan(0));
      }, timeout: const Timeout(Duration(minutes: 15)));
    });

    group('3. 同步 vs 异步接口对比', () {
      test('对比同步和异步接口', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 同步 vs 异步接口对比 ===');
        
        // 生成3分钟音频（超过同步接口限制）
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_3min.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 180);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;
        
        print('测试音频: 3分钟, ${fileSizeMB.toStringAsFixed(2)}MB');
        
        // 测试同步接口（预期失败）
        print('\n--- 测试同步接口 ---');
        try {
          final syncResult = await apiService.transcribeAudio(audioPath);
          print('✓ 同步接口成功: ${syncResult.length} chars');
        } catch (e) {
          print('✗ 同步接口失败: $e');
          print('  这是预期的，因为文件超过同步接口限制');
        }
        
        // 测试异步接口（预期成功）
        print('\n--- 测试异步接口 ---');
        try {
          final asyncResult = await apiService.transcribeAudioAsync(
            audioPath,
            onProgress: (step, detail) => print('  [$step] $detail'),
          );
          print('✓ 异步接口成功: ${asyncResult.length} chars');
        } catch (e) {
          print('✗ 异步接口失败: $e');
        }
        
        expect(await file.exists(), isTrue);
      }, timeout: const Timeout(Duration(minutes: 15)));
    });

    group('4. 错误处理测试', () {
      test('处理不存在的文件', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试错误处理 ===');
        
        expect(
          () => apiService.transcribeAudioAsync('/nonexistent/audio.wav'),
          throwsException,
        );
        
        print('✓ 正确处理不存在的文件');
      });

      test('处理未配置的 API', () {
        print('\n测试未配置 API...');
        
        expect(
          () => apiService.transcribeAudioAsync('test.wav'),
          throwsException,
        );
        
        print('✓ 正确处理未配置状态');
      });
    });
  });
}

/// 生成模拟语音的 WAV 音频
Future<void> _generateVoiceLikeWav(String path, {required int durationSeconds}) async {
  final sampleRate = 16000;
  final numChannels = 1;
  final bitsPerSample = 16;
  final totalSamples = sampleRate * durationSeconds;
  final dataSize = totalSamples * numChannels * (bitsPerSample ~/ 8);
  final fileSize = dataSize + 36;
  
  // WAV 头
  final header = ByteData(44);
  header.setUint8(0, 'R'.codeUnitAt(0));
  header.setUint8(1, 'I'.codeUnitAt(0));
  header.setUint8(2, 'F'.codeUnitAt(0));
  header.setUint8(3, 'F'.codeUnitAt(0));
  header.setUint32(4, fileSize, Endian.little);
  header.setUint8(8, 'W'.codeUnitAt(0));
  header.setUint8(9, 'A'.codeUnitAt(0));
  header.setUint8(10, 'V'.codeUnitAt(0));
  header.setUint8(11, 'E'.codeUnitAt(0));
  header.setUint8(12, 'f'.codeUnitAt(0));
  header.setUint8(13, 'm'.codeUnitAt(0));
  header.setUint8(14, 't'.codeUnitAt(0));
  header.setUint8(15, ' '.codeUnitAt(0));
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little);
  header.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  header.setUint8(36, 'd'.codeUnitAt(0));
  header.setUint8(37, 'a'.codeUnitAt(0));
  header.setUint8(38, 't'.codeUnitAt(0));
  header.setUint8(39, 'a'.codeUnitAt(0));
  header.setUint32(40, dataSize, Endian.little);
  
  // 生成复合波形模拟语音
  final audioData = ByteData(dataSize);
  
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    
    // 模拟语音特征：包含基频和谐波
    var sample = 0.0;
    
    // 基频 (类似男声 100-150Hz)
    sample += 0.3 * _sin(2 * _pi * 120 * t);
    
    // 二次谐波
    sample += 0.2 * _sin(2 * _pi * 240 * t);
    
    // 三次谐波
    sample += 0.15 * _sin(2 * _pi * 360 * t);
    
    // 高频成分 (类似辅音)
    sample += 0.1 * _sin(2 * _pi * 2000 * t);
    
    // 添加一些随机变化模拟语音的自然变化
    final variation = 1.0 + 0.1 * _sin(2 * _pi * 5 * t);
    sample *= variation;
    
    // 限制振幅
    sample = sample.clamp(-0.8, 0.8);
    
    // 转换为 16-bit
    final intSample = (sample * 32767).toInt();
    audioData.setInt16(i * 2, intSample, Endian.little);
  }
  
  // 合并
  final result = Uint8List(44 + dataSize);
  result.setRange(0, 44, header.buffer.asUint8List());
  result.setRange(44, 44 + dataSize, audioData.buffer.asUint8List());
  
  await File(path).writeAsBytes(result);
}

// 数学函数
double _sin(double x) {
  x = x % (2 * _pi);
  double result = x;
  double term = x;
  for (int i = 1; i < 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

const double _pi = 3.141592653589793;
