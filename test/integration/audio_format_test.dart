import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';
import 'package:changji_app/core/services/api_service.dart';

/// 多格式音频转写测试
/// 
/// 测试所有支持的音频格式:
/// - WAV (audio/wav)
/// - M4A (audio/mp4)
/// - AAC (audio/aac)
/// - OGG (audio/ogg)
/// - FLAC (audio/flac)
/// - MP3 (audio/mp3)
/// 
/// 运行方式:
/// ```bash
/// $env:QWEN_API_KEY="your-api-key"; flutter test test/integration/audio_format_test.dart
/// ```
void main() {
  group('多格式音频转写测试', () {
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
      tempDir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}audio_format_test_${DateTime.now().millisecondsSinceEpoch}');
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
          reason: '请提供 QWEN_API_KEY 环境变量进行测试\n'
                  '设置方式: \$env:QWEN_API_KEY="your-api-key"');
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

    group('1. WAV 格式测试', () {
      test('生成并转写 WAV 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 WAV 格式 ===');
        
        // 生成短 WAV 音频 (30秒，避免大小限制)
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.wav';
        await _generateWav(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ WAV 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ WAV 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('2. M4A 格式测试', () {
      test('生成并转写 M4A 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 M4A 格式 ===');
        
        // 生成短 M4A 音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.m4a';
        await _generateM4a(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ M4A 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ M4A 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('3. MP3 格式测试', () {
      test('生成并转写 MP3 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 MP3 格式 ===');
        
        // 生成短 MP3 音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.mp3';
        await _generateMp3(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ MP3 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ MP3 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('4. AAC 格式测试', () {
      test('生成并转写 AAC 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 AAC 格式 ===');
        
        // 生成短 AAC 音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.aac';
        await _generateAac(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ AAC 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ AAC 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('5. OGG 格式测试', () {
      test('生成并转写 OGG 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 OGG 格式 ===');
        
        // 生成短 OGG 音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.ogg';
        await _generateOgg(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ OGG 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ OGG 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('6. FLAC 格式测试', () {
      test('生成并转写 FLAC 音频', () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped('跳过: 未提供 QWEN_API_KEY');
          return;
        }

        apiService.configure(
          apiKey: apiKey!,
          config: AiModelConfig.qwen,
        );

        print('\n=== 测试 FLAC 格式 ===');
        
        // 生成短 FLAC 音频
        final audioPath = '${tempDir.path}${Platform.pathSeparator}test.flac';
        await _generateFlac(audioPath, durationSeconds: 30);
        
        final file = File(audioPath);
        final fileSize = await file.length();
        print('✓ FLAC 文件已生成');
        print('  大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        
        // 转写
        print('  正在转写...');
        final result = await apiService.transcribeAudio(
          audioPath,
          onProgress: (step, detail) => print('    [$step] $detail'),
        );
        
        print('✓ FLAC 转写完成');
        print('  结果: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
        expect(result, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    });

    group('7. 格式对比测试', () {
      test('比较所有格式的文件大小', () async {
        print('\n=== 格式大小对比 (30秒音频) ===');
        
        final formats = {
          'WAV': '${tempDir.path}${Platform.pathSeparator}compare.wav',
          'M4A': '${tempDir.path}${Platform.pathSeparator}compare.m4a',
          'MP3': '${tempDir.path}${Platform.pathSeparator}compare.mp3',
          'AAC': '${tempDir.path}${Platform.pathSeparator}compare.aac',
          'OGG': '${tempDir.path}${Platform.pathSeparator}compare.ogg',
          'FLAC': '${tempDir.path}${Platform.pathSeparator}compare.flac',
        };
        
        // 生成所有格式
        await _generateWav(formats['WAV']!, durationSeconds: 30);
        await _generateM4a(formats['M4A']!, durationSeconds: 30);
        await _generateMp3(formats['MP3']!, durationSeconds: 30);
        await _generateAac(formats['AAC']!, durationSeconds: 30);
        await _generateOgg(formats['OGG']!, durationSeconds: 30);
        await _generateFlac(formats['FLAC']!, durationSeconds: 30);
        
        // 比较大小
        final sizes = <String, int>{};
        for (final entry in formats.entries) {
          final file = File(entry.value);
          if (await file.exists()) {
            sizes[entry.key] = await file.length();
          }
        }
        
        // 排序并显示
        final sorted = sizes.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        print('\n文件大小排名 (从小到大):');
        for (int i = 0; i < sorted.length; i++) {
          final entry = sorted[i];
          final sizeKB = entry.value / 1024;
          print('  ${i + 1}. ${entry.key}: ${sizeKB.toStringAsFixed(2)} KB');
        }
        
        // 验证所有文件都生成了
        expect(sizes.length, 6, reason: '所有格式都应该生成成功');
      });
    });
  });
}

// ==================== 音频生成函数 ====================

/// 生成 WAV 格式音频
Future<void> _generateWav(String path, {required int durationSeconds}) async {
  final sampleRate = 16000;
  final numChannels = 1;
  final bitsPerSample = 16;
  final totalSamples = sampleRate * durationSeconds;
  final dataSize = totalSamples * numChannels * (bitsPerSample ~/ 8);
  final fileSize = dataSize + 36;
  
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
  header.setUint16(32, numChannels * (bitsPerSample ~/ 2), Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  header.setUint8(36, 'd'.codeUnitAt(0));
  header.setUint8(37, 'a'.codeUnitAt(0));
  header.setUint8(38, 't'.codeUnitAt(0));
  header.setUint8(39, 'a'.codeUnitAt(0));
  header.setUint32(40, dataSize, Endian.little);
  
  final result = Uint8List(44 + dataSize);
  result.setRange(0, 44, header.buffer.asUint8List());
  
  // 生成正弦波
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final sample = (32767 * 0.5 * _sin(2 * _pi * 440 * t)).toInt();
    final byteOffset = 44 + i * 2;
    result[byteOffset] = sample & 0xFF;
    result[byteOffset + 1] = (sample >> 8) & 0xFF;
  }
  
  await File(path).writeAsBytes(result);
}

/// 生成 M4A 格式音频 (简化版，使用 WAV 伪装)
Future<void> _generateM4a(String path, {required int durationSeconds}) async {
  // 由于无法真正编码 M4A，我们生成一个带 M4A 头的文件
  // 实际测试中可能需要使用真实 M4A 文件
  final header = Uint8List.fromList([
    0x00, 0x00, 0x00, 0x20, // ftyp box size
    0x66, 0x74, 0x79, 0x70, // "ftyp"
    0x4D, 0x34, 0x41, 0x20, // "M4A "
    0x00, 0x00, 0x00, 0x00, // minor version
    0x4D, 0x34, 0x41, 0x20, // compatible brands
    0x6D, 0x70, 0x34, 0x32, // "mp42"
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
  ]);
  
  // 添加一些模拟音频数据
  final audioData = Uint8List(durationSeconds * 16000); // 模拟压缩数据
  for (int i = 0; i < audioData.length; i++) {
    audioData[i] = (128 + 64 * _sin(2 * _pi * 440 * (i / 16000))).toInt();
  }
  
  final result = Uint8List(header.length + audioData.length);
  result.setRange(0, header.length, header);
  result.setRange(header.length, result.length, audioData);
  
  await File(path).writeAsBytes(result);
}

/// 生成 MP3 格式音频 (简化版)
Future<void> _generateMp3(String path, {required int durationSeconds}) async {
  // MP3 帧头 (模拟)
  final frameHeader = Uint8List.fromList([
    0xFF, 0xFB, // MPEG-1 Layer 3
    0x90, 0x00, // 比特率 etc
  ]);
  
  // 生成模拟 MP3 帧
  final framesPerSecond = 38; // 约 1152 samples/frame at 44100Hz
  final totalFrames = durationSeconds * framesPerSecond;
  final frameSize = 417; // 典型帧大小
  
  final result = Uint8List(totalFrames * frameSize);
  
  for (int frame = 0; frame < totalFrames; frame++) {
    final offset = frame * frameSize;
    // 帧头
    result[offset] = 0xFF;
    result[offset + 1] = 0xFB;
    result[offset + 2] = 0x90;
    result[offset + 3] = 0x00;
    
    // 填充模拟音频数据
    for (int i = 4; i < frameSize; i++) {
      result[offset + i] = (128 + 64 * _sin(2 * _pi * 440 * ((frame * 1152 + i) / 44100))).toInt();
    }
  }
  
  await File(path).writeAsBytes(result);
}

/// 生成 AAC 格式音频 (简化版)
Future<void> _generateAac(String path, {required int durationSeconds}) async {
  // AAC ADTS 头
  final adtsHeader = Uint8List.fromList([
    0xFF, 0xF1, // syncword
    0x50, 0x80, // MPEG-4, LC, 16kHz
    0x00, 0x1F, // frame length
    0xFC, // CRC
  ]);
  
  // 模拟 AAC 帧
  final framesPerSecond = 15; // 1024 samples/frame at 16kHz
  final totalFrames = durationSeconds * framesPerSecond;
  final frameSize = 128;
  
  final result = Uint8List(totalFrames * frameSize);
  
  for (int frame = 0; frame < totalFrames; frame++) {
    final offset = frame * frameSize;
    // ADTS 头
    result[offset] = 0xFF;
    result[offset + 1] = 0xF1;
    result[offset + 2] = 0x50;
    result[offset + 3] = 0x80;
    
    // 填充模拟数据
    for (int i = 4; i < frameSize; i++) {
      result[offset + i] = (128 + 64 * _sin(2 * _pi * 440 * ((frame * 1024 + i) / 16000))).toInt();
    }
  }
  
  await File(path).writeAsBytes(result);
}

/// 生成 OGG 格式音频 (简化版)
Future<void> _generateOgg(String path, {required int durationSeconds}) async {
  // OGG 页头
  final pageHeader = Uint8List.fromList([
    0x4F, 0x67, 0x67, 0x53, // "OggS"
    0x00, // version
    0x02, // header type (BOS)
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // granule position
    0x01, 0x00, 0x00, 0x00, // serial number
    0x00, 0x00, 0x00, 0x00, // page sequence
    0x00, 0x00, 0x00, 0x00, // CRC
    0x01, // number of segments
    0x1E, // segment table
  ]);
  
  // Vorbis identification 头
  final vorbisId = Uint8List.fromList([
    0x01, // packet type
    0x76, 0x6F, 0x72, 0x62, 0x69, 0x73, // "vorbis"
    0x00, 0x00, 0x00, 0x00, // version
    0x01, // channels
    0x00, 0x7D, 0x00, 0x00, // sample rate (32000)
    0x00, 0x00, 0x00, 0x00, // bitrate max
    0x00, 0x00, 0x00, 0x00, // bitrate nominal
    0x00, 0x00, 0x00, 0x00, // bitrate min
    0xB8, 0x01, // block sizes
  ]);
  
  // 模拟音频页
  final audioPageSize = durationSeconds * 16000 ~/ 50; // 粗略估计
  final audioPage = Uint8List(audioPageSize);
  for (int i = 0; i < audioPageSize; i++) {
    audioPage[i] = (128 + 64 * _sin(2 * _pi * 440 * (i / 16000))).toInt();
  }
  
  final result = Uint8List(pageHeader.length + vorbisId.length + audioPage.length);
  result.setRange(0, pageHeader.length, pageHeader);
  result.setRange(pageHeader.length, pageHeader.length + vorbisId.length, vorbisId);
  result.setRange(pageHeader.length + vorbisId.length, result.length, audioPage);
  
  await File(path).writeAsBytes(result);
}

/// 生成 FLAC 格式音频 (简化版)
Future<void> _generateFlac(String path, {required int durationSeconds}) async {
  // FLAC 标记
  final flacMarker = Uint8List.fromList([
    0x66, 0x4C, 0x61, 0x43, // "fLaC"
  ]);
  
  // STREAMINFO block
  final streamInfo = Uint8List.fromList([
    0x00, // block type (STREAMINFO)
    0x00, 0x00, 0x22, // block size (34 bytes)
    0x0F, 0x00, // min block size
    0x00, 0x0F, // max block size
    0x00, 0x00, 0x0F, // min frame size
    0x00, 0x00, 0x0F, // max frame size
    0x0A, // sample rate (44.1kHz >> 12) | channels
    0xC4, // channels | bits per sample
    0x42, // bits per sample | total samples
    0xF0, 0x00, 0x00, 0x01, // total samples
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // MD5
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]);
  
  // 模拟 FLAC 帧
  final frameSize = durationSeconds * 16000 * 2; // 16-bit mono
  final audioData = Uint8List(frameSize);
  for (int i = 0; i < frameSize ~/ 2; i++) {
    final sample = (32767 * 0.5 * _sin(2 * _pi * 440 * (i / 16000))).toInt();
    audioData[i * 2] = sample & 0xFF;
    audioData[i * 2 + 1] = (sample >> 8) & 0xFF;
  }
  
  final result = Uint8List(flacMarker.length + streamInfo.length + audioData.length);
  result.setRange(0, flacMarker.length, flacMarker);
  result.setRange(flacMarker.length, flacMarker.length + streamInfo.length, streamInfo);
  result.setRange(flacMarker.length + streamInfo.length, result.length, audioData);
  
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
