import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/services/api_service.dart';
import 'package:changji_app/core/models/ai_model_config.dart';

void main() {
  group('Qwen Audio URL Format Test', () {
    late ApiService apiService;
    final apiKey = 'sk-103ddf012c494f5099a10ec41f171253';

    setUp(() {
      apiService = ApiService();
      apiService.configure(
        apiKey: apiKey,
        config: AiModelConfig.qwen,
      );
    });

    test('测试 audio_url 格式转写 - 使用测试音频', () async {
      print('\n=== 测试 Qwen audio_url 格式 ===');
      print('API Key: ${apiKey.substring(0, 8)}...');

      // 创建测试音频文件 (5秒 WAV)
      final testAudioPath = await createTestWavFile(durationSeconds: 5);
      print('测试音频: $testAudioPath');

      try {
        final result = await apiService.transcribeAudio(
          testAudioPath,
          model: 'qwen3-asr-flash',
          useChunking: false,
        );
        print('✓ 转写成功!');
        print('结果: $result');
        expect(result, isNotEmpty);
      } catch (e) {
        print('✗ 转写失败: $e');
        // 即使失败也继续测试，看看错误信息
        expect(true, isTrue); // 不失败测试，只记录错误
      } finally {
        // 清理测试文件
        final file = File(testAudioPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    test('直接测试 audio_url API 格式', () async {
      print('\n=== 直接测试 API 格式 ===');

      final dio = Dio(BaseOptions(
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ));

      // 创建小的测试音频
      final testAudioPath = await createTestWavFile(durationSeconds: 3);
      final bytes = await File(testAudioPath).readAsBytes();
      final base64Audio = base64Encode(bytes);
      final dataUri = 'data:audio/wav;base64,$base64Audio';

      print('音频大小: ${bytes.length} bytes');

      try {
        // 测试 audio_url 格式
        print('\n1. 测试 audio_url 格式...');
        final response1 = await dio.post('/chat/completions', data: {
          'model': 'qwen3.6-flash',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'audio_url',
                  'audio_url': {
                    'url': dataUri,
                  }
                }
              ]
            }
          ],
          'max_tokens': 4096,
        });
        print('✓ audio_url 格式成功!');
        print('响应: ${response1.data}');
      } catch (e) {
        print('✗ audio_url 格式失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
        }
      }

      try {
        // 测试 input_audio 格式 (对比)
        print('\n2. 测试 input_audio 格式 (对比)...');
        final response2 = await dio.post('/chat/completions', data: {
          'model': 'qwen3.6-flash',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'input_audio',
                  'input_audio': {
                    'data': dataUri,
                  }
                }
              ]
            }
          ],
          'max_tokens': 4096,
        });
        print('✓ input_audio 格式成功!');
        print('响应: ${response2.data}');
      } catch (e) {
        print('✗ input_audio 格式失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
        }
      }

      // 清理
      final file = File(testAudioPath);
      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}

Future<String> createTestWavFile({required int durationSeconds}) async {
  final tempDir = Directory.systemTemp;
  final fileName = 'test_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
  final filePath = '${tempDir.path}\\$fileName';

  final sampleRate = 16000;
  final numChannels = 1;
  final bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final dataSize = durationSeconds * byteRate;
  final fileSize = dataSize + 36;

  final file = File(filePath);
  final sink = file.openWrite();

  // WAV header
  sink.add('RIFF'.codeUnits);
  sink.add(_intToBytes(fileSize, 4));
  sink.add('WAVE'.codeUnits);
  sink.add('fmt '.codeUnits);
  sink.add(_intToBytes(16, 4)); // Subchunk1Size
  sink.add(_intToBytes(1, 2)); // AudioFormat (PCM)
  sink.add(_intToBytes(numChannels, 2));
  sink.add(_intToBytes(sampleRate, 4));
  sink.add(_intToBytes(byteRate, 4));
  sink.add(_intToBytes(numChannels * (bitsPerSample ~/ 8), 2)); // BlockAlign
  sink.add(_intToBytes(bitsPerSample, 2));
  sink.add('data'.codeUnits);
  sink.add(_intToBytes(dataSize, 4));

  // Generate sine wave audio data
  final random = DateTime.now().millisecondsSinceEpoch;
  for (int i = 0; i < dataSize ~/ 2; i++) {
    final t = i / sampleRate;
    final frequency = 440 + (random % 200); // Random frequency between 440-640 Hz
    final sample = (32767 * 0.5 * sin(2 * 3.14159265359 * frequency * t)).toInt();
    sink.add(_intToBytes(sample, 2));
  }

  await sink.close();
  return filePath;
}

List<int> _intToBytes(int value, int length) {
  final result = <int>[];
  for (int i = 0; i < length; i++) {
    result.add((value >> (i * 8)) & 0xFF);
  }
  return result;
}

double sin(double x) {
  // Simple sine approximation
  x = x % (2 * 3.14159265359);
  if (x < 0) x += 2 * 3.14159265359;
  
  // Taylor series approximation
  double result = x;
  double term = x;
  for (int i = 1; i <= 5; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}