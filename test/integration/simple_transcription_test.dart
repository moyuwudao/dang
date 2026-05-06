import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 简单转写测试 - 不使用 SharedPreferences
void main() {
  group('简单转写测试', () {
    late ApiService apiService;
    String? apiKey;
    late Directory tempDir;

    setUp(() async {
      // 初始化 Flutter 绑定
      TestWidgetsFlutterBinding.ensureInitialized();
      
      apiService = ApiService();
      
      // 从环境变量获取 API Key
      apiKey = const String.fromEnvironment('QWEN_API_KEY');
      if (apiKey == null || apiKey!.isEmpty) {
        apiKey = Platform.environment['QWEN_API_KEY'];
      }
      
      // 创建临时目录
      tempDir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}simple_test_${DateTime.now().millisecondsSinceEpoch}');
      await tempDir.create();
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('10秒音频转写测试', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        markTestSkipped('未提供 QWEN_API_KEY');
        return;
      }

      apiService.configure(
        apiKey: apiKey!,
        config: AiModelConfig.qwen,
      );

      print('\n=== 10秒音频转写测试 ===');
      
      // 生成10秒测试音频
      final audioPath = '${tempDir.path}${Platform.pathSeparator}test_10s.wav';
      await _generateVoiceLikeWav(audioPath, durationSeconds: 10);
      
      final file = File(audioPath);
      final fileSize = await file.length();
      
      print('✓ 测试音频已生成');
      print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      print('  时长: 10秒');
      
      // 转写
      print('\n  开始转写...');
      String? result;
      Exception? error;
      
      try {
        result = await apiService.transcribeAudio(
          audioPath,
          useChunking: false,
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
          print('  结果预览: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        }
      }
      
      expect(await file.exists(), isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('30秒音频转写测试', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        markTestSkipped('未提供 QWEN_API_KEY');
        return;
      }

      apiService.configure(
        apiKey: apiKey!,
        config: AiModelConfig.qwen,
      );

      print('\n=== 30秒音频转写测试 ===');
      
      // 生成30秒测试音频
      final audioPath = '${tempDir.path}${Platform.pathSeparator}test_30s.wav';
      await _generateVoiceLikeWav(audioPath, durationSeconds: 30);
      
      final file = File(audioPath);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / 1024 / 1024;
      
      print('✓ 测试音频已生成');
      print('  大小: ${fileSizeMB.toStringAsFixed(2)} MB');
      print('  时长: 30秒');
      
      // 转写
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
          print('  结果预览: ${result.substring(0, result.length > 150 ? 150 : result.length)}...');
        }
      }
      
      expect(await file.exists(), isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));
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
    
    // 模拟语音特征
    var sample = 0.0;
    
    // 基频
    sample += 0.3 * _sin(2 * _pi * 120 * t);
    
    // 谐波
    sample += 0.2 * _sin(2 * _pi * 240 * t);
    sample += 0.15 * _sin(2 * _pi * 360 * t);
    
    // 高频成分
    sample += 0.1 * _sin(2 * _pi * 2000 * t);
    
    // 添加变化
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
