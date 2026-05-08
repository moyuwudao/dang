import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Qwen Multipart Upload Test', () {
    final apiKey = 'sk-103ddf012c494f5099a10ec41f171253';

    test('测试 multipart 文件上传', () async {
      print('\n=== 测试 Multipart 文件上传 ===');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      ));

      // 创建测试音频 (3秒)
      final testAudioPath = await createTestWavFile(durationSeconds: 3);
      print('测试音频: $testAudioPath');

      try {
        // 使用 multipart/form-data 上传
        print('\n1. 使用 multipart/form-data 上传...');
        
        final formData = FormData.fromMap({
          'model': 'qwen3-asr-flash',
          'file': await MultipartFile.fromFile(
            testAudioPath,
            filename: 'test.wav',
            contentType: DioMediaType.parse('audio/wav'),
          ),
        });

        final response = await dio.post(
          'https://dashscope.aliyuncs.com/api/v1/files',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          ),
        );
        
        print('✓ 上传成功!');
        print('响应: ${response.data}');

        final fileUrl = response.data['file_url'] as String?;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          print('File URL: $fileUrl');

          // 调用 ASR API
          print('\n2. 调用 ASR API...');
          final asrResponse = await dio.post(
            'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
            data: {
              'model': 'qwen3-asr-flash',
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
          print('✓ ASR API 成功!');
          print('响应: ${asrResponse.data}');
        }
      } catch (e) {
        print('✗ 测试失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
          print('错误类型: ${e.type}');
          print('错误信息: ${e.message}');
        }
      } finally {
        // 清理
        final file = File(testAudioPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    test('测试使用 URL 而不是 base64', () async {
      print('\n=== 测试使用外部 URL ===');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      ));

      try {
        // 使用一个公开的音频 URL 测试
        print('\n1. 使用公开音频 URL 测试 ASR...');
        final response = await dio.post(
          'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
          data: {
            'model': 'qwen3-asr-flash',
            'input': {
              'file_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
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
        print('✓ ASR API 成功!');
        print('响应: ${response.data}');
      } catch (e) {
        print('✗ 测试失败: $e');
        if (e is DioException) {
          print('状态码: ${e.response?.statusCode}');
          print('响应: ${e.response?.data}');
        }
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