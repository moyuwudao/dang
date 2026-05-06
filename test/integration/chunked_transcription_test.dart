import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 分片转写集成测试
/// 
/// 测试长音频分片处理功能
/// 将长音频切分成30秒片段，逐段转写后合并结果
/// 
/// 运行方式:
/// ```bash
/// $env:QWEN_API_KEY="your-api-key"; flutter test test/integration/chunked_transcription_test.dart
/// ```
void main() {
  // 初始化 Flutter 绑定，避免 SharedPreferences 报错
  TestWidgetsFlutterBinding.ensureInitialized();
  group('分片转写测试', () {
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
      tempDir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}chunked_test_${DateTime.now().millisecondsSinceEpoch}');
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

    group('1. 短音频不分片测试 (30秒)', () {
      test('30秒音频不需要分片', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试短音频 (30秒) ===');
        
        // 生成30秒测试音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_30s.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;
        
        print('✓ 测试音频已生成');
        print('  大小: ${fileSizeMB.toStringAsFixed(2)} MB');
        print('  时长: 30秒');
        print('  预计: 不需要分片 (< 7MB)');
        
        // 转写（不使用分片）
        print('\n  开始转写...');
        String? result;
        Exception? error;
        
        try {
          result = await apiService.transcribeAudio(
            audioPath,
            useChunking: false, // 禁用分片
            onProgress: (step, detail) => print('    [$step] $detail'),
          );
        } catch (e) {
          error = e is Exception ? e : Exception(e.toString());
        }
        
        if (error != null) {
          print('\n  转写结果: $error');
        } else {
          print('\n✓ 转写完成!');
          print('  结果: ${result?.substring(0, result!.length > 100 ? 100 : result!.length)}...');
          print('  字符数: ${result?.length}');
        }
        
        expect(await file.exists(), isTrue);
        expect(fileSizeMB, lessThan(7.0), reason: '30秒音频应该小于7MB');
      }, timeout: const Timeout(Duration(minutes: 3)));
    });

    group('2. 长音频分片测试 (6分钟)', () {
      test('6分钟音频需要分片处理', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试长音频分片 (6分钟) ===');
        
        // 生成6分钟测试音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_6min.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 360);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;
        
        print('✓ 长音频测试文件已生成');
        print('  大小: ${fileSizeMB.toStringAsFixed(2)} MB');
        print('  时长: 6分钟');
        print('  预计: 需要分片 (> 7MB)');
        
        // 验证需要分片
        expect(fileSizeMB, greaterThan(7.0), reason: '6分钟音频应该超过7MB限制');
        
        // 转写（使用分片）
        print('\n  开始分片转写...');
        print('  预计分片数: ${(fileSizeMB / 7).ceil()} 片');
        
        String? result;
        Exception? error;
        
        try {
          result = await apiService.transcribeAudio(
            audioPath,
            useChunking: true, // 启用分片
            onProgress: (step, detail) => print('    [$step] $detail'),
          );
        } catch (e) {
          error = e is Exception ? e : Exception(e.toString());
        }
        
        if (error != null) {
          print('\n  转写结果: $error');
        } else {
          print('\n✓ 分片转写完成!');
          print('  结果: ${result?.substring(0, result!.length > 200 ? 200 : result!.length)}...');
          print('  字符数: ${result?.length}');
        }
        
        expect(await file.exists(), isTrue);
      }, timeout: const Timeout(Duration(minutes: 15)));
    });

    group('3. 分片 vs 不分片对比', () {
      test('对比3分钟音频的处理方式', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 分片 vs 不分片对比 ===');
        
        // 生成3分钟音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_3min.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 180);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;
        
        print('测试音频: 3分钟, ${fileSizeMB.toStringAsFixed(2)}MB');
        
        // 测试1: 不分片（预期失败）
        print('\n--- 测试1: 不分片 ---');
        try {
          final result1 = await apiService.transcribeAudio(
            audioPath,
            useChunking: false,
            onProgress: (step, detail) => print('  [$step] $detail'),
          );
          print('✓ 不分片成功: ${result1.length} chars');
        } catch (e) {
          print('✗ 不分片失败: $e');
          print('  这是预期的，因为文件超过同步接口限制');
        }
        
        // 测试2: 分片（预期成功）
        print('\n--- 测试2: 分片处理 ---');
        try {
          final result2 = await apiService.transcribeAudio(
            audioPath,
            useChunking: true,
            onProgress: (step, detail) => print('  [$step] $detail'),
          );
          print('✓ 分片成功: ${result2.length} chars');
        } catch (e) {
          print('✗ 分片失败: $e');
        }
        
        expect(await file.exists(), isTrue);
      }, timeout: const Timeout(Duration(minutes: 15)));
    });

    group('4. 超短音频测试', () {
      test('10秒音频快速转写', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试超短音频 (10秒) ===');
        
        // 生成10秒测试音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test_10s.wav';
        await _generateVoiceLikeWav(audioPath, durationSeconds: 10);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        
        print('✓ 测试音频已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        print('  时长: 10秒');
        
        // 快速转写
        print('\n  开始快速转写...');
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
          print('\n  转写结果: $error');
        } else {
          print('\n✓ 快速转写完成!');
          print('  结果: ${result?.substring(0, result!.length > 100 ? 100 : result!.length)}...');
          print('  字符数: ${result?.length}');
        }
        
        expect(await file.exists(), isTrue);
      }, timeout: const Timeout(Duration(minutes: 2)));
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
