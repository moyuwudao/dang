import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Qwen Native API Test', () {
    final apiKey = 'sk-103ddf012c494f5099a10ec41f171253';

    test('测试 Qwen 原生 ASR API', () async {
      print('\n=== 测试 Qwen 原生 ASR API ===');

      // 创建测试音频
      final testAudioPath = await createTestWavFile(durationSeconds: 5);
      final bytes = await File(testAudioPath).readAsBytes();
      final base64Audio = base64Encode(bytes);

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      ));

      // 测试1: 原生语音识别 API (非兼容模式)
      print('\n1. 测试原生 ASR API...');
      try {
        final response = await dio.post(
          'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
          data: {
            'model': 'qwen3-asr-flash',
            'input': {
              'audio': base64Audio,
            },
            'parameters': {
              'language_hints': ['zh', 'en'],
            },
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
        );
        print('✓ 原生 ASR API 成功!');
        print('响应: ${response.data}');
      } catch (e) {
        print('✗ 原生 ASR API 失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
        }
      }

      // 测试2: 使用 file_url 方式
      print('\n2. 测试 file_url 方式...');
      try {
        // 先上传文件
        final uploadResponse = await dio.post(
          'https://dashscope.aliyuncs.com/api/v1/files',
          data: {
            'model': 'qwen3-asr-flash-filetrans',
            'file': 'data:audio/wav;base64,$base64Audio',
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
        );
        print('上传成功: ${uploadResponse.data}');

        final fileUrl = uploadResponse.data['file_url'];
        if (fileUrl != null) {
          // 提交转写任务
          final submitResponse = await dio.post(
            'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
            data: {
              'model': 'qwen3-asr-flash-filetrans',
              'input': {
                'file_url': fileUrl,
              },
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
            ),
          );
          print('✓ file_url 方式成功!');
          print('响应: ${submitResponse.data}');
        }
      } catch (e) {
        print('✗ file_url 方式失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
        }
      }

      // 测试3: 兼容模式但使用正确的音频格式
      print('\n3. 测试兼容模式 + 正确的音频参数...');
      try {
        final response = await dio.post(
          'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
          data: {
            'model': 'qwen3.6-flash',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a helpful assistant that transcribes audio.'
              },
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text': 'Please transcribe this audio:'
                  },
                  {
                    'type': 'audio',
                    'audio': {
                      'url': 'data:audio/wav;base64,$base64Audio'
                    }
                  }
                ]
              }
            ],
            'max_tokens': 4096,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
        );
        print('✓ 兼容模式成功!');
        print('响应: ${response.data}');
      } catch (e) {
        print('✗ 兼容模式失败: $e');
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

  sink.add('RIFF'.codeUnits);
  sink.add(_intToBytes(fileSize, 4));
  sink.add('WAVE'.codeUnits);
  sink.add('fmt '.codeUnits);
  sink.add(_intToBytes(16, 4));
  sink.add(_intToBytes(1, 2));
  sink.add(_intToBytes(numChannels, 2));
  sink.add(_intToBytes(sampleRate, 4));
  sink.add(_intToBytes(byteRate, 4));
  sink.add(_intToBytes(numChannels * (bitsPerSample ~/ 8), 2));
  sink.add(_intToBytes(bitsPerSample, 2));
  sink.add('data'.codeUnits);
  sink.add(_intToBytes(dataSize, 4));

  final random = DateTime.now().millisecondsSinceEpoch;
  for (int i = 0; i < dataSize ~/ 2; i++) {
    final t = i / sampleRate;
    final frequency = 440 + (random % 200);
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
  x = x % (2 * 3.14159265359);
  if (x < 0) x += 2 * 3.14159265359;
  double result = x;
  double term = x;
  for (int i = 1; i <= 5; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}