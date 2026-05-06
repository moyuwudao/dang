import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 录音转写功能集成测试
/// 
/// 运行方式:
/// ```bash
/// # Windows PowerShell
/// $env:QWEN_API_KEY="your-api-key"; flutter test test/integration/transcription_integration_test.dart
/// 
/// # Windows CMD
/// set QWEN_API_KEY=your-api-key
/// flutter test test/integration/transcription_integration_test.dart
/// ```
/// 
/// 测试流程:
/// 1. 生成测试音频文件 (WAV格式)
/// 2. 配置 Qwen API
/// 3. 调用转写接口
/// 4. 验证转写结果
void main() {
  group('录音转写功能集成测试', () {
    late ApiService apiService;
    String? apiKey;
    String? testAudioPath;

    setUp(() async {
      apiService = ApiService();
      
      // 从环境变量获取 API Key
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
      
      // 生成测试音频文件路径
      final tempDir = Directory.systemTemp;
      testAudioPath = '${tempDir.path}${Platform.pathSeparator}test_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    });

    tearDown(() async {
      // 清理测试音频文件
      if (testAudioPath != null) {
        final file = File(testAudioPath!);
        if (await file.exists()) {
          await file.delete();
          print('✓ 清理测试音频文件');
        }
      }
    });

    test('环境检查 - API Key 已提供', () {
      expect(apiKey, isNotNull,
          reason: '请提供 QWEN_API_KEY 环境变量进行测试\n'
                  '设置方式: set QWEN_API_KEY=your-api-key');
      expect(apiKey, isNotEmpty,
          reason: 'QWEN_API_KEY 不能为空');
      
      if (apiKey != null && apiKey!.isNotEmpty) {
        print('✓ API Key 已提供: ${apiKey!.substring(0, apiKey!.length > 15 ? 15 : apiKey!.length)}...');
      }
    });

    group('1. 生成测试音频', () {
      test('创建测试 WAV 音频文件', () async {
        print('\n=== 步骤1: 生成测试音频 ===');
        
        // 生成简单的测试音频数据 (1秒静音 + 1秒正弦波)
        final audioData = _generateTestWav(
          durationSeconds: 2,
          sampleRate: 16000,
          frequency: 440, // A4音符
        );
        
        // 保存到临时文件
        final file = File(testAudioPath!);
        await file.writeAsBytes(audioData);
        
        expect(await file.exists(), isTrue,
            reason: '测试音频文件创建失败');
        
        final fileSize = await file.length();
        print('✓ 测试音频已生成');
        print('  路径: $testAudioPath');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        print('  时长: 2秒');
        print('  采样率: 16000 Hz');
        
        expect(fileSize, greaterThan(0));
      });
    });

    group('2. 配置 Qwen API', () {
      test('配置 API 服务', () {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        print('\n=== 步骤2: 配置 Qwen API ===');
        
        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );
        
        expect(apiService.isConfigured, isTrue);
        expect(apiService.currentConfig!.provider, AiProvider.qwen);
        
        print('✓ API 配置成功');
        print('  提供商: ${apiService.currentConfig!.displayName}');
        print('  Base URL: ${apiService.currentConfig!.baseUrl}');
        print('  转写模型: ${apiService.currentConfig!.asrModel}');
        print('  文件大小限制: ${apiService.currentConfig!.transcriptionLimit?.maxFileSizeMB} MB');
      });

      test('验证 API Key 有效性', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n验证 API Key...');
        final isValid = await apiService.validateApiKey();
        
        if (isValid) {
          print('✓ API Key 验证通过');
        } else {
          print('✗ API Key 验证失败');
          print('  请检查: ');
          print('    1. API Key 是否正确');
          print('    2. 网络连接是否正常');
          print('    3. Qwen 服务是否可用');
        }
        
        expect(isValid, isTrue,
            reason: 'API Key 无效，无法进行转写测试');
      });
    });

    group('3. 执行转写', () {
      test('转写测试音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        // 确保音频文件已生成
        final file = File(testAudioPath!);
        if (!await file.exists()) {
          // 生成测试音频
          final audioData = _generateTestWav(
            durationSeconds: 2,
            sampleRate: 16000,
            frequency: 440,
          );
          await file.writeAsBytes(audioData);
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 步骤3: 执行转写 ===');
        print('正在转写，请稍候...');
        print('(转写时间取决于音频长度和网络状况)');
        
        String? transcription;
        Exception? error;
        
        try {
          transcription = await apiService.transcribeAudio(
            testAudioPath!,
            onProgress: (step, detail) {
              print('  [$step] $detail');
            },
          );
        } catch (e) {
          error = e is Exception ? e : Exception(e.toString());
        }
        
        if (error != null) {
          print('\n✗ 转写失败');
          print('  错误: $error');
          throw error;
        }
        
        expect(transcription, isNotNull,
            reason: '转写结果不应为空');
        
        print('\n✓ 转写完成!');
        print('  结果: $transcription');
        
        // 记录转写结果长度
        if (transcription != null) {
          print('  字符数: ${transcription.length}');
        }
      }, timeout: const Timeout(Duration(minutes: 5)));
    });

    group('4. 转写进度回调', () {
      test('转写进度回调功能', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        // 确保音频文件已生成
        final file = File(testAudioPath!);
        if (!await file.exists()) {
          final audioData = _generateTestWav(
            durationSeconds: 2,
            sampleRate: 16000,
            frequency: 440,
          );
          await file.writeAsBytes(audioData);
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试转写进度回调 ===');
        
        final progressSteps = <String>[];
        
        await apiService.transcribeAudio(
          testAudioPath!,
          onProgress: (step, detail) {
            progressSteps.add(step);
            print('  进度 [$step]: $detail');
          },
        );
        
        print('\n✓ 进度回调测试完成');
        print('  收到 ${progressSteps.length} 个进度更新');
        print('  步骤: ${progressSteps.join(', ')}');
        
        // 验证至少收到了一些进度回调
        expect(progressSteps, isNotEmpty,
            reason: '应该收到至少一个进度回调');
      }, timeout: const Timeout(Duration(minutes: 5)));
    });

    group('5. 错误处理', () {
      test('处理不存在的音频文件', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试错误处理 ===');
        print('测试不存在的音频文件...');
        
        expect(
          () => apiService.transcribeAudio('/nonexistent/audio.wav'),
          throwsException,
        );
        
        print('✓ 正确处理不存在的文件');
      });

      test('处理未配置 API 的情况', () {
        print('\n测试未配置 API...');
        
        expect(
          () => apiService.transcribeAudio(testAudioPath!),
          throwsException,
        );
        
        print('✓ 正确处理未配置状态');
      });
    });
  });
}

/// 生成测试 WAV 音频文件数据
/// 
/// 生成包含正弦波的 WAV 格式音频数据
Uint8List _generateTestWav({
  required int durationSeconds,
  required int sampleRate,
  required double frequency,
}) {
  final numChannels = 1; // 单声道
  final bitsPerSample = 16; // 16位采样
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final totalSamples = sampleRate * durationSeconds;
  final dataSize = totalSamples * numChannels * (bitsPerSample ~/ 8);
  final fileSize = dataSize + 36; // 44字节头部 - 8
  
  // WAV 头部 (44字节)
  final header = ByteData(44);
  
  // RIFF 标识
  header.setUint8(0, 'R'.codeUnitAt(0));
  header.setUint8(1, 'I'.codeUnitAt(0));
  header.setUint8(2, 'F'.codeUnitAt(0));
  header.setUint8(3, 'F'.codeUnitAt(0));
  
  // 文件大小
  header.setUint32(4, fileSize, Endian.little);
  
  // WAVE 标识
  header.setUint8(8, 'W'.codeUnitAt(0));
  header.setUint8(9, 'A'.codeUnitAt(0));
  header.setUint8(10, 'V'.codeUnitAt(0));
  header.setUint8(11, 'E'.codeUnitAt(0));
  
  // fmt 标识
  header.setUint8(12, 'f'.codeUnitAt(0));
  header.setUint8(13, 'm'.codeUnitAt(0));
  header.setUint8(14, 't'.codeUnitAt(0));
  header.setUint8(15, ' '.codeUnitAt(0));
  
  // 子块大小 (16 for PCM)
  header.setUint32(16, 16, Endian.little);
  
  // 音频格式 (1 = PCM)
  header.setUint16(20, 1, Endian.little);
  
  // 声道数
  header.setUint16(22, numChannels, Endian.little);
  
  // 采样率
  header.setUint32(24, sampleRate, Endian.little);
  
  // 字节率
  header.setUint32(28, byteRate, Endian.little);
  
  // 块对齐
  header.setUint16(32, numChannels * (bitsPerSample ~/ 2), Endian.little);
  
  // 采样位数
  header.setUint16(34, bitsPerSample, Endian.little);
  
  // data 标识
  header.setUint8(36, 'd'.codeUnitAt(0));
  header.setUint8(37, 'a'.codeUnitAt(0));
  header.setUint8(38, 't'.codeUnitAt(0));
  header.setUint8(39, 'a'.codeUnitAt(0));
  
  // 数据大小
  header.setUint32(40, dataSize, Endian.little);
  
  // 生成音频数据 (正弦波)
  final audioData = ByteData(totalSamples * 2); // 16位 = 2字节/采样
  
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    // 生成正弦波，振幅为最大值的 50%
    final amplitude = 0.5;
    final sample = (32767 * amplitude * 
                    sin(2 * pi * frequency * t)).toInt();
    audioData.setInt16(i * 2, sample, Endian.little);
  }
  
  // 合并头部和数据
  final result = Uint8List(44 + dataSize);
  result.setRange(0, 44, header.buffer.asUint8List());
  result.setRange(44, 44 + dataSize, audioData.buffer.asUint8List());
  
  return result;
}

// 简单的 sin 函数实现 (避免导入 dart:math 如果不需要)
double sin(double x) {
  // 使用泰勒级数近似
  x = x % (2 * 3.141592653589793);
  double result = x;
  double term = x;
  for (int i = 1; i < 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

const double pi = 3.141592653589793;
