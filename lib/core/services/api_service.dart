import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/ai_model_config.dart';
import 'storage_service.dart';
import 'stats_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final statsService = ref.read(statsServiceProvider);
  return ApiService(statsService: statsService);
});

class AudioChunkInfo {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final int size;

  const AudioChunkInfo({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.size,
  });

  String get durationText {
    final start =
        '${startTime.inMinutes}:${(startTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final end =
        '${endTime.inMinutes}:${(endTime.inSeconds % 60).toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

class ApiService {
  late Dio _dio;
  AiModelConfig? _currentConfig;
  String? _apiKey;
  String? _appId;
  bool _isConfigured = false;
  final StatsService? _statsService;

  static const int _chunkDurationSeconds = 30; // 减小分片时长，避免文件过大
  static const int _wavHeaderSize = 44;
  static const int _wavBytesPerSecond = 32000;

  ApiService({StatsService? statsService}) : _statsService = statsService {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 300),
        sendTimeout: const Duration(seconds: 180),
      ),
    );
  }

  bool get isConfigured =>
      _isConfigured && _currentConfig != null && _apiKey != null;

  AiModelConfig? get currentConfig => _currentConfig;

  String get configInfo {
    if (_currentConfig == null) return 'Not configured';
    return 'provider=${_currentConfig!.name}, baseUrl=${_dio.options.baseUrl}, model=${_currentConfig!.defaultModel}';
  }

  void configure({
    required String apiKey,
    required AiModelConfig config,
    String? customBaseUrl,
    String? appId,
  }) {
    _currentConfig = config;
    _apiKey = apiKey;
    _appId = appId;
    _isConfigured = true;
    final baseUrl = customBaseUrl ?? config.baseUrl;

    _dio.options.baseUrl = baseUrl;

    switch (config.provider) {
      case AiProvider.openAI:
      case AiProvider.deepSeek:
      case AiProvider.grok:
      case AiProvider.qwen:
      case AiProvider.zhipu:
      case AiProvider.kimi:
      case AiProvider.spark:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.claude:
        _dio.options.headers = {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.gemini:
        _dio.options.headers = {
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.ernie:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.custom:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
    }

    debugPrint('API configured: $configInfo');
  }

  String _extractDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      debugPrint('Error Response Status: ${response.statusCode}');
      debugPrint('Error Response Headers: ${response.headers}');
      if (response.data != null) {
        debugPrint('Error Response Data: ${response.data}');
        try {
          if (response.data is Map) {
            final error = response.data['error'];
            if (error is Map) {
              return error['message'] ??
                  error['code']?.toString() ??
                  response.data.toString();
            }
            return response.data['message'] ?? response.data.toString();
          }
          return response.data.toString();
        } catch (_) {
          return response.statusMessage ?? e.message ?? 'Unknown error';
        }
      }
    }
    return e.message ?? 'Network error';
  }

  Future<bool> validateApiKey() async {
    if (!isConfigured) {
      debugPrint('API validation failed: not configured');
      return false;
    }

    debugPrint('Validating API: $configInfo');

    try {
      Response response;
      switch (_currentConfig!.provider) {
        case AiProvider.gemini:
          response = await _dio.get(
            '/models',
            queryParameters: {'key': _apiKey},
          );
          break;
        default:
          response = await _dio.get('/models');
          break;
      }
      debugPrint('API validation OK: status=${response.statusCode}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('API validation error: ${_extractDioError(e)}');
      return false;
    } catch (e) {
      debugPrint('API validation error: $e');
      return false;
    }
  }

  String _getMimeType(String filePath) {
    if (filePath.endsWith('.wav')) return 'audio/wav';
    if (filePath.endsWith('.m4a')) return 'audio/mp4';
    if (filePath.endsWith('.aac')) return 'audio/aac';
    if (filePath.endsWith('.ogg')) return 'audio/ogg';
    if (filePath.endsWith('.flac')) return 'audio/flac';
    if (filePath.endsWith('.mp3')) return 'audio/mp3';
    return 'audio/mp3';
  }

  int _getWavDurationSeconds(Uint8List wavBytes) {
    if (wavBytes.length < _wavHeaderSize) return 0;

    final dataView = ByteData.sublistView(wavBytes);

    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') return 0;

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final dataSize = dataView.getUint32(40, Endian.little);

    if (sampleRate == 0 || bitsPerSample == 0 || numChannels == 0) return 0;

    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    if (byteRate == 0) return 0;

    return dataSize ~/ byteRate;
  }

  List<Uint8List> _splitWavFile(Uint8List wavBytes) {
    if (wavBytes.length < _wavHeaderSize) return [];

    final dataView = ByteData.sublistView(wavBytes);

    // Verify RIFF header
    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') {
      debugPrint('Invalid WAV file: missing RIFF header');
      return [];
    }

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);

    if (byteRate == 0) return [];

    final chunkByteSize = byteRate * _chunkDurationSeconds;
    final originalDataSize = dataView.getUint32(40, Endian.little);
    const originalDataStart = _wavHeaderSize;

    if (originalDataSize <= chunkByteSize) {
      return [wavBytes];
    }

    final chunks = <Uint8List>[];
    int offset = 0;
    int chunkIndex = 0;

    while (offset < originalDataSize) {
      final currentChunkSize = (offset + chunkByteSize <= originalDataSize)
          ? chunkByteSize
          : originalDataSize - offset;

      // Build a proper WAV header for this chunk
      final chunkTotalSize = currentChunkSize + _wavHeaderSize - 8;
      const subchunk1Size = 16; // PCM format
      final blockAlign = numChannels * (bitsPerSample ~/ 8);

      final header = Uint8List(_wavHeaderSize);
      final headerView = ByteData.sublistView(header);

      // RIFF header
      header.setRange(0, 4, 'RIFF'.codeUnits);
      headerView.setUint32(4, chunkTotalSize, Endian.little);
      header.setRange(8, 12, 'WAVE'.codeUnits);

      // fmt subchunk
      header.setRange(12, 16, 'fmt '.codeUnits);
      headerView.setUint32(16, subchunk1Size, Endian.little);
      headerView.setUint16(20, 1, Endian.little); // AudioFormat = PCM
      headerView.setUint16(22, numChannels, Endian.little);
      headerView.setUint32(24, sampleRate, Endian.little);
      headerView.setUint32(28, byteRate, Endian.little);
      headerView.setUint16(32, blockAlign, Endian.little);
      headerView.setUint16(34, bitsPerSample, Endian.little);

      // data subchunk
      header.setRange(36, 40, 'data'.codeUnits);
      headerView.setUint32(40, currentChunkSize, Endian.little);

      final chunk = Uint8List(_wavHeaderSize + currentChunkSize);
      chunk.setRange(0, _wavHeaderSize, header);
      chunk.setRange(_wavHeaderSize, _wavHeaderSize + currentChunkSize,
          wavBytes, originalDataStart + offset);

      chunks.add(chunk);
      debugPrint(
          'Chunk ${chunkIndex + 1}: ${currentChunkSize ~/ byteRate}s, ${(chunk.length / 1024).toStringAsFixed(0)}KB');

      offset += currentChunkSize;
      chunkIndex++;
    }

    return chunks;
  }

  Future<String> transcribeAudio(
    String audioFilePath, {
    String? model,
    void Function(String step, String detail)? onProgress,
    bool useChunking = true, // 新增：是否使用分片处理
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 根据提供商选择默认模型
    final effectiveModel = model ?? _currentConfig!.asrModel;
    debugPrint(
        'TranscribeAudio: provider=${_currentConfig!.name}, model=$effectiveModel');

    if (!_currentConfig!.supportsTranscription) {
      throw Exception(
          '${_currentConfig!.displayName} 不支持语音转写。请使用 OpenAI、Gemini 或 Qwen 进行转写。');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;
    debugPrint('=== Transcription Start ===');
    debugPrint('Provider: ${_currentConfig!.name}');
    debugPrint('BaseUrl: ${_dio.options.baseUrl}');
    debugPrint('AudioFile: $audioFilePath');
    debugPrint('FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call('read', '读取音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      String result;

      // 检查是否需要分片处理
      final needsChunk = useChunking && _needsChunking(audioFilePath);

      if (needsChunk) {
        onProgress?.call('split', '音频文件较大，开始分片处理');
        result = await _transcribeWithChunking(audioFilePath,
            model: effectiveModel, onProgress: onProgress);
      } else {
        switch (_currentConfig!.transcriptionMethod) {
          case TranscriptionMethod.whisperApi:
            onProgress?.call('upload', '上传音频到OpenAI Whisper');
            result =
                await _transcribeWhisper(audioFilePath, model: effectiveModel);
            break;
          case TranscriptionMethod.audioUpload:
            onProgress?.call('upload', '上传音频文件');
            result = await _transcribeAudioUpload(audioFilePath,
                model: effectiveModel);
            break;
          case TranscriptionMethod.nativeAsr:
          case TranscriptionMethod.asyncAsr:
            onProgress?.call('process', '进行语音转写');
            result = await _transcribeNativeAsr(audioFilePath,
                model: effectiveModel, onProgress: onProgress);
            break;
          case TranscriptionMethod.realtimeWebSocket:
            throw Exception('Realtime WebSocket does not support file transcription. Use transcribeRealtime() instead.');
        }
      }

      _statsService?.apiVoiceCallCompleted(true);
      return result;
    } catch (e) {
      _statsService?.apiVoiceCallCompleted(false);
      throw e;
    }
  }

  bool _needsChunking(String audioFilePath) {
    final file = File(audioFilePath);
    final fileSize = file.lengthSync();

    // 只有 WAV 文件支持分片
    if (!audioFilePath.toLowerCase().endsWith('.wav')) {
      debugPrint('Chunking check: non-WAV file, cannot split compressed audio');
      return false;
    }

    // Provider-specific chunking logic
    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        // Qwen sync API (qwen3-asr-flash) has 10MB base64 limit via chat/completions
        // After base64 encoding, size increases ~33%, so use 5MB raw file limit (更保守)
        const qwenSyncLimit = 5 * 1024 * 1024;
        debugPrint(
            'Chunking check (Qwen): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=5MB, needsChunk=${fileSize > qwenSyncLimit}');
        return fileSize > qwenSyncLimit;
      case AiProvider.openAI:
        // Whisper API has 25MB file limit
        const openAILimit = 20 * 1024 * 1024;
        debugPrint(
            'Chunking check (OpenAI): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=20MB, needsChunk=${fileSize > openAILimit}');
        return fileSize > openAILimit;
      case AiProvider.gemini:
        // Gemini has 20MB limit for free tier
        const geminiLimit = 16 * 1024 * 1024;
        debugPrint(
            'Chunking check (Gemini): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=16MB, needsChunk=${fileSize > geminiLimit}');
        return fileSize > geminiLimit;
      default:
        if (_currentConfig!.transcriptionLimit != null) {
          final maxSizeBytes =
              _currentConfig!.transcriptionLimit!.maxFileSizeMB * 1024 * 1024;
          final effectiveMaxSize = (maxSizeBytes * 0.7).toInt(); // 更保守的限制
          debugPrint(
              'Chunking check: fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(1)}MB, needsChunk=${fileSize > effectiveMaxSize}');
          return fileSize > effectiveMaxSize;
        }
        return false;
    }
  }

  Future<String> _transcribeWithChunking(
    String audioFilePath, {
    required String model,
    void Function(String step, String detail)? onProgress,
  }) async {
    debugPrint('=== Chunked Transcription Start ===');

    final file = File(audioFilePath);
    final audioBytes = await file.readAsBytes();
    final mimeType = _getMimeType(audioFilePath);

    List<Uint8List> chunks;
    if (audioFilePath.endsWith('.wav')) {
      final totalDuration = _getWavDurationSeconds(audioBytes);
      debugPrint('WAV file, total duration: ${totalDuration}s');
      chunks = _splitWavFile(audioBytes);
    } else {
      chunks = _splitAudioByBytes(audioBytes, mimeType);
    }

    if (chunks.isEmpty) {
      throw Exception('音频文件格式无效，无法分片');
    }

    debugPrint('Split into ${chunks.length} chunks');
    onProgress?.call('split', '已分片为 ${chunks.length} 段，开始逐段转写');

    final results = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      final chunkMsg =
          '转写第 ${i + 1}/${chunks.length} 段 (${(chunks[i].length / 1024).toStringAsFixed(0)}KB)...';
      debugPrint(chunkMsg);
      onProgress?.call('upload', chunkMsg);

      String? chunkResult;
      int retries = 0;
      const maxRetries = 2;

      while (retries <= maxRetries && chunkResult == null) {
        try {
          switch (_currentConfig!.transcriptionMethod) {
            case TranscriptionMethod.whisperApi:
              chunkResult = await _transcribeWhisperChunk(chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.audioUpload:
              chunkResult = await _transcribeAudioUploadChunk(
                  chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.nativeAsr:
            case TranscriptionMethod.asyncAsr:
              chunkResult = await _transcribeNativeAsrChunk(chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.realtimeWebSocket:
              throw Exception('Realtime WebSocket does not support chunk transcription');
          }

          if (chunkResult.isNotEmpty) {
            results.add(chunkResult);
            debugPrint('Chunk ${i + 1} done: ${chunkResult.length} chars');
            onProgress?.call('process', '第 ${i + 1}/${chunks.length} 段转写完成');
          }
        } catch (e) {
          retries++;
          debugPrint('Chunk ${i + 1} attempt $retries failed: $e');
          onProgress?.call(
              'upload', '第 ${i + 1} 段转写失败，重试 $retries/$maxRetries...');
          if (retries <= maxRetries) {
            debugPrint('Retrying chunk ${i + 1} in 3 seconds...');
            await Future.delayed(const Duration(seconds: 3));
          } else {
            debugPrint('Chunk ${i + 1} failed after $maxRetries retries');
            results.add('[转写失败: 第${i + 1}段]');
            onProgress?.call('process', '第 ${i + 1} 段转写失败，跳过');
          }
        }
      }

      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final combinedResult = results.join('\n');
    debugPrint(
        '=== Chunked Transcription Done: ${combinedResult.length} chars from ${results.length} chunks ===');

    if (combinedResult.isEmpty || combinedResult == '[转写失败: 第1段]') {
      throw Exception('所有分片转写均失败');
    }

    await StorageService.incrementUsageStat(
      _currentConfig!.name,
      'transcription',
      tokens: combinedResult.length,
    );

    return combinedResult;
  }

  List<Uint8List> _splitAudioByBytes(Uint8List audioBytes, String mimeType) {
    if (audioBytes.isEmpty) return [];

    // 对于压缩格式（MP3、M4A等），不能简单按字节分片
    // 直接返回原文件，如果太大则会在转写时失败
    // 用户需要使用 WAV 格式或异步接口处理大文件
    debugPrint(
        'Non-WAV file detected ($mimeType), cannot split compressed audio');
    return [audioBytes];
  }

  /// 获取音频文件的分段信息（用于重新转写选择）
  Future<List<AudioChunkInfo>> getAudioChunks(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final audioBytes = await file.readAsBytes();
    final mimeType = _getMimeType(audioFilePath);

    List<Uint8List> chunks;
    if (audioFilePath.endsWith('.wav')) {
      final totalDuration = _getWavDurationSeconds(audioBytes);
      chunks = _splitWavFile(audioBytes);
      return List.generate(chunks.length, (index) {
        final startTime = index * _chunkDurationSeconds;
        final endTime = (index + 1) * _chunkDurationSeconds;
        final actualEndTime = endTime > totalDuration ? totalDuration : endTime;
        return AudioChunkInfo(
          index: index,
          startTime: Duration(seconds: startTime),
          endTime: Duration(seconds: actualEndTime),
          size: chunks[index].length,
        );
      });
    } else {
      // 非WAV文件无法分片，返回整个文件作为一个段落
      return [
        AudioChunkInfo(
          index: 0,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 0), // 未知时长
          size: audioBytes.length,
        ),
      ];
    }
  }

  /// 重新转写指定的段落
  Future<String> retranscribeChunks(
    String audioFilePath, {
    required List<int> chunkIndices,
    String? model,
    void Function(String step, String detail)? onProgress,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final effectiveModel = model ?? _currentConfig!.asrModel;
    debugPrint(
        'RetranscribeChunks: indices=$chunkIndices, model=$effectiveModel');

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final audioBytes = await file.readAsBytes();
    final mimeType = _getMimeType(audioFilePath);

    List<Uint8List> allChunks;
    if (audioFilePath.endsWith('.wav')) {
      allChunks = _splitWavFile(audioBytes);
    } else {
      throw Exception('非WAV文件不支持段落选择转写');
    }

    if (allChunks.isEmpty) {
      throw Exception('音频文件格式无效，无法分片');
    }

    final results = <String>[];
    final totalChunks = chunkIndices.length;

    for (int i = 0; i < chunkIndices.length; i++) {
      final chunkIndex = chunkIndices[i];
      if (chunkIndex < 0 || chunkIndex >= allChunks.length) {
        debugPrint(
            'Invalid chunk index: $chunkIndex, total: ${allChunks.length}');
        continue;
      }

      final chunkMsg =
          '转写第 ${chunkIndex + 1}/${allChunks.length} 段 (${i + 1}/$totalChunks 已选)...';
      debugPrint(chunkMsg);
      onProgress?.call('upload', chunkMsg);

      try {
        String? chunkResult;
        switch (_currentConfig!.transcriptionMethod) {
          case TranscriptionMethod.whisperApi:
            chunkResult = await _transcribeWhisperChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.audioUpload:
            chunkResult = await _transcribeAudioUploadChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.nativeAsr:
          case TranscriptionMethod.asyncAsr:
            chunkResult = await _transcribeNativeAsrChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.realtimeWebSocket:
            throw Exception('Realtime WebSocket does not support chunk retranscription');
        }

        if (chunkResult.isNotEmpty) {
          results.add(chunkResult);
          debugPrint(
              'Chunk ${chunkIndex + 1} done: ${chunkResult.length} chars');
          onProgress?.call('process', '第 ${chunkIndex + 1} 段转写完成');
        }
      } catch (e) {
        debugPrint('Chunk ${chunkIndex + 1} failed: $e');
        results.add('[转写失败: 第${chunkIndex + 1}段]');
        onProgress?.call('process', '第 ${chunkIndex + 1} 段转写失败');
      }

      if (i < chunkIndices.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return results.join('\n');
  }

  Future<String> _transcribeWhisper(String audioFilePath,
      {required String model}) async {
    debugPrint('Using Whisper API with model: $model');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFilePath),
      'model': model,
      'language': 'auto',
      'response_format': 'json',
    });

    final response = await _dio.post(
      '/audio/transcriptions',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final text = response.data['text'] ?? '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(
        _currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeAudioUpload(String audioFilePath,
      {required String model}) async {
    debugPrint('Using Gemini Audio Upload with model: $model');

    final bytes = await File(audioFilePath).readAsBytes();
    final base64Audio = base64Encode(bytes);
    final mimeType = _getMimeType(audioFilePath);

    debugPrint(
        'Audio: mimeType=$mimeType, size=${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB');

    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Please transcribe the following audio file to text. Output only the transcribed text, without any additional explanation.'
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Audio}
              }
            ]
          }
        ]
      },
    );

    final text = response.data['candidates']?[0]?['content']?['parts']?[0]
            ?['text'] ??
        '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(
        _currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeNativeAsr(
    String audioFilePath, {
    required String model,
    void Function(String step, String detail)? onProgress,
  }) async {
    debugPrint('Using Native ASR for ${_currentConfig!.name}');

    final file = File(audioFilePath);
    final fileSize = await file.length();
    final mimeType = _getMimeType(audioFilePath);

    debugPrint(
        'Audio: mimeType=$mimeType, size=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');

    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        final bytes = await file.readAsBytes();
        final base64Audio = base64Encode(bytes);
        return await _transcribeQwenAsr(base64Audio, mimeType, model: model);
      default:
        throw Exception('${_currentConfig!.displayName} 不支持语音转写');
    }
  }

  Future<String> _transcribeQwenAsr(String base64Audio, String mimeType,
      {required String model}) async {
    final audioBytes = base64Decode(base64Audio);
    return await _transcribeQwenAsrBytes(audioBytes, mimeType, model: model);
  }

  Future<String> _transcribeQwenAsrBytes(Uint8List audioBytes, String mimeType,
      {required String model}) async {
    final audioSizeMB = audioBytes.length / 1024 / 1024;

    // Use the provided model, or fall back to config's asrModel, then hardcoded default
    final asrModel = model.isNotEmpty
        ? model
        : (_currentConfig?.asrModel.isNotEmpty == true
            ? _currentConfig!.asrModel
            : 'qwen3-asr-flash');
    debugPrint(
        'Qwen ASR: model=$asrModel, mimeType=$mimeType, size=${audioSizeMB.toStringAsFixed(1)}MB');

    // Qwen ASR uses OpenAI compatible mode with input_audio
    // Reference: https://help.aliyun.com/zh/model-studio/qwen-asr-api-reference
    final base64Audio = base64Encode(audioBytes);
    final dataUri = 'data:$mimeType;base64,$base64Audio';

    debugPrint('Qwen ASR: calling /chat/completions with input_audio');

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': asrModel,
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
      },
    );

    debugPrint(
        'Qwen ASR response: ${response.data.toString().substring(0, response.data.toString().length > 800 ? 800 : response.data.toString().length)}...');

    final text = response.data['choices']?[0]?['message']?['content'] ?? '';
    debugPrint('Qwen ASR result: ${text.length} chars');
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(
        _currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeWhisperChunk(Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(p.join(
        tempDir.path, 'chunk_${DateTime.now().millisecondsSinceEpoch}.wav'));
    await tempFile.writeAsBytes(chunkBytes);

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(tempFile.path),
        'model': model,
        'language': 'auto',
        'response_format': 'json',
      });

      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data['text'] ?? '';
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<String> _transcribeAudioUploadChunk(
      Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    final base64Chunk = base64Encode(chunkBytes);

    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Please transcribe the following audio file to text. Output only the transcribed text.'
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Chunk}
              }
            ]
          }
        ]
      },
    );

    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';
  }

  Future<String> _transcribeNativeAsrChunk(
      Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        // Pass bytes directly, avoid double base64 encode/decode
        return await _transcribeQwenAsrBytes(chunkBytes, mimeType,
            model: model);
      default:
        throw Exception('${_currentConfig!.displayName} 不支持语音转写');
    }
  }

  Future<String> summarizeText(String text, {String? model}) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          return await _claudeChat(
              model: useModel,
              systemPrompt:
                  'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).',
              userContent: text);
        case AiProvider.gemini:
          return await _geminiChat(
              model: useModel,
              prompt:
                  'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).\n\nContent: $text');
        default:
          return await _openAIStyleChat(
              model: useModel,
              systemPrompt:
                  'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).',
              userContent: text);
      }
    } on DioException catch (e) {
      throw Exception('摘要失败: ${_extractDioError(e)}');
    } catch (e) {
      throw Exception('摘要失败: $e');
    }
  }

  Future<String> generateTitle(String text, {String? model}) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          return await _claudeChat(
              model: useModel,
              systemPrompt:
                  'Generate a short title (max 20 characters) for the following content. Return only the title text.',
              userContent: text,
              maxTokens: 50);
        case AiProvider.gemini:
          return await _geminiChat(
              model: useModel,
              prompt:
                  'Generate a short title (max 20 characters) for the following content. Return only the title text.\n\nContent: $text');
        default:
          return await _openAIStyleChat(
              model: useModel,
              systemPrompt:
                  'Generate a short title (max 20 characters) for the following content. Return only the title text.',
              userContent: text,
              maxTokens: 50);
      }
    } on DioException catch (e) {
      throw Exception('标题生成失败: ${_extractDioError(e)}');
    } catch (e) {
      throw Exception('标题生成失败: $e');
    }
  }

  Future<String> chatCompletion(String prompt,
      {String? model, String? toolId}) async {
    return await chatCompletionWithSystem(
      prompt,
      systemPrompt: 'You are a helpful assistant.',
      model: model,
      toolId: toolId,
    );
  }

  Future<String> chatCompletionWithSystem(
    String prompt, {
    required String systemPrompt,
    String? model,
    String? toolId,
  }) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      String result;
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          result = await _claudeChat(
              model: useModel, systemPrompt: systemPrompt, userContent: prompt);
          break;
        case AiProvider.gemini:
          result = await _geminiChatWithSystem(
              model: useModel, prompt: prompt, systemPrompt: systemPrompt);
          break;
        default:
          result = await _openAIStyleChat(
              model: useModel, systemPrompt: systemPrompt, userContent: prompt);
          break;
      }
      _statsService?.apiTextCallCompleted(true, toolId: toolId);
      return result;
    } on DioException catch (e) {
      _statsService?.apiTextCallCompleted(false, toolId: toolId);
      final errorMsg = _extractDioError(e);
      final statusCode = e.response?.statusCode;
      debugPrint('Chat failed: status=$statusCode, error=$errorMsg');
      debugPrint('Request URL: ${e.requestOptions.uri}');
      debugPrint(
          'Request data: ${e.requestOptions.data.toString().substring(0, e.requestOptions.data.toString().length > 200 ? 200 : e.requestOptions.data.toString().length)}...');
      throw Exception('对话失败: $errorMsg');
    } catch (e) {
      _statsService?.apiTextCallCompleted(false, toolId: toolId);
      throw Exception('对话失败: $e');
    }
  }

  Future<String> _openAIStyleChat(
      {required String model,
      required String systemPrompt,
      required String userContent,
      int maxTokens = 1000}) async {
    debugPrint(
        'Chat: model=$model, prompt=${userContent.substring(0, userContent.length > 50 ? 50 : userContent.length)}...');

    final response = await _dio.post('/chat/completions', data: {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });

    debugPrint(
        'Chat response: ${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}...');

    final content = response.data['choices'][0]['message']['content'] ?? '';
    final tokens = response.data['usage']?['total_tokens'] as int? ?? 0;
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: tokens);
    return content;
  }

  Future<String> _claudeChat(
      {required String model,
      required String systemPrompt,
      required String userContent,
      int maxTokens = 1000}) async {
    final response = await _dio.post('/messages', data: {
      'model': model,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': userContent}
      ],
    });
    final content = response.data['content'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: content.length);
    return content;
  }

  Future<String> _geminiChat(
      {required String model, required String prompt}) async {
    return await _geminiChatWithSystem(
        model: model, prompt: prompt, systemPrompt: '');
  }

  Future<String> _geminiChatWithSystem(
      {required String model,
      required String prompt,
      required String systemPrompt}) async {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Understood. I will follow these instructions.'}
        ]
      });
    }

    contents.add({
      'parts': [
        {'text': prompt}
      ]
    });

    final response =
        await _dio.post('/models/$model:generateContent', queryParameters: {
      'key': _apiKey
    }, data: {
      'contents': contents,
    });
    final content =
        response.data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: content.length);
    return content;
  }

  // ==================== 图片识别（OCR via LLM Vision）====================

  Future<String> recognizeImage(String imagePath,
      {String? model, String? systemPrompt}) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('图片文件不存在: $imagePath');
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final useModel = model ?? _currentConfig!.visionModel;
    final prompt = systemPrompt ??
        '请识别这张图片中的所有文字内容。如果图片包含表格，请尽量保持表格结构。如果图片是文档，请按段落输出文字。只输出识别到的文字内容，不要添加任何解释。';

    debugPrint(
        'RecognizeImage: provider=${_currentConfig!.name}, model=$useModel');

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.gemini:
          return await _geminiRecognizeImage(base64Image,
              prompt: prompt, model: useModel);
        case AiProvider.claude:
          return await _claudeRecognizeImage(base64Image,
              prompt: prompt, model: useModel);
        default:
          return await _openAIStyleRecognizeImage(base64Image,
              prompt: prompt, model: useModel);
      }
    } on DioException catch (e) {
      final errorMsg = _extractDioError(e);
      debugPrint('Image recognition failed: $errorMsg');
      throw Exception('图片识别失败: $errorMsg');
    } catch (e) {
      throw Exception('图片识别失败: $e');
    }
  }

  Future<String> _openAIStyleRecognizeImage(String base64Image,
      {required String prompt, required String model}) async {
    final response = await _dio.post('/chat/completions', data: {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              }
            },
          ],
        },
      ],
      'max_tokens': 4000,
    });

    final content = response.data['choices'][0]['message']['content'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'vision',
        tokens: content.length);
    return content;
  }

  Future<String> _claudeRecognizeImage(String base64Image,
      {required String prompt, required String model}) async {
    final response = await _dio.post('/messages', data: {
      'model': model,
      'max_tokens': 4000,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image
              }
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    });
    final content = response.data['content'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'vision',
        tokens: content.length);
    return content;
  }

  Future<String> _geminiRecognizeImage(String base64Image,
      {required String prompt, required String model}) async {
    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              },
            ],
          },
        ],
      },
    );
    final content =
        response.data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'vision',
        tokens: content.length);
    return content;
  }

  // ==================== 异步转写方法 ====================

  Stream<String> chatCompletionStream(String prompt,
      {String? model,
      String systemPrompt = 'You are a helpful assistant.'}) async* {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    switch (_currentConfig!.provider) {
      case AiProvider.claude:
        yield* _claudeChatStream(
            model: useModel, systemPrompt: systemPrompt, userContent: prompt);
        break;
      case AiProvider.gemini:
        yield* _geminiChatStream(
            model: useModel, prompt: prompt, systemPrompt: systemPrompt);
        break;
      default:
        yield* _openAIStyleChatStream(
            model: useModel, systemPrompt: systemPrompt, userContent: prompt);
    }
  }

  Stream<String> _openAIStyleChatStream(
      {required String model,
      required String systemPrompt,
      required String userContent,
      int maxTokens = 4000}) async* {
    final response = await _dio.post<ResponseBody>(
      '/chat/completions',
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.7,
        'max_tokens': maxTokens,
        'stream': true,
      },
      options: Options(responseType: ResponseType.stream),
    );

    String fullContent = '';
    final decoder = Utf8Decoder(allowMalformed: false);
    await for (final chunk in response.data!.stream) {
      final text = decoder.convert(chunk);
      final lines = text.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null) {
            fullContent += delta;
            yield delta;
          }
        } catch (_) {}
      }
    }
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: fullContent.length);
  }

  Stream<String> _claudeChatStream(
      {required String model,
      required String systemPrompt,
      required String userContent,
      int maxTokens = 4000}) async* {
    final response = await _dio.post<ResponseBody>(
      '/messages',
      data: {
        'model': model,
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userContent}
        ],
        'stream': true,
      },
      options: Options(responseType: ResponseType.stream),
    );

    String fullContent = '';
    final decoder = Utf8Decoder(allowMalformed: false);
    await for (final chunk in response.data!.stream) {
      final text = decoder.convert(chunk);
      final lines = text.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final type = json['type'] as String?;
          if (type == 'content_block_delta') {
            final delta = json['delta']?['text'] as String?;
            if (delta != null) {
              fullContent += delta;
              yield delta;
            }
          }
        } catch (_) {}
      }
    }
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: fullContent.length);
  }

  Stream<String> _geminiChatStream(
      {required String model,
      required String prompt,
      required String systemPrompt}) async* {
    final contents = <Map<String, dynamic>>[];
    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Understood. I will follow these instructions.'}
        ]
      });
    }
    contents.add({
      'parts': [
        {'text': prompt}
      ]
    });

    final response = await _dio.post<ResponseBody>(
      '/models/$model:streamGenerateContent?alt=sse&key=$_apiKey',
      data: {'contents': contents},
      options: Options(responseType: ResponseType.stream),
    );

    String fullContent = '';
    final decoder = Utf8Decoder(allowMalformed: false);
    await for (final chunk in response.data!.stream) {
      final text = decoder.convert(chunk);
      final lines = text.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final parts =
              json['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
          if (parts != null) {
            for (final part in parts) {
              final text = part['text'] as String?;
              if (text != null) {
                fullContent += text;
                yield text;
              }
            }
          }
        } catch (_) {}
      }
    }
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat',
        tokens: fullContent.length);
  }

  /// 异步转写音频（适用于长音频 > 5分钟）
  ///
  /// 使用 qwen3-asr-flash-filetrans 模型
  /// 支持最长12小时，最大2GB音频文件
  ///
  /// 流程：
  /// 1. 上传音频文件获取 file_url
  /// 2. 提交异步转写任务
  /// 3. 轮询任务状态
  /// 4. 获取转写结果
  Future<String> transcribeAudioAsync(
    String audioFilePath, {
    void Function(String step, String detail)? onProgress,
    String? language,
    bool enableWords = false,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    if (_currentConfig!.provider != AiProvider.qwen) {
      throw Exception('异步转写仅支持 Qwen 提供商');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;

    debugPrint('=== Async Transcription Start ===');
    debugPrint('Provider: ${_currentConfig!.name}');
    debugPrint('AudioFile: $audioFilePath');
    debugPrint('FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call('upload', '上传音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      // 步骤1: 上传音频文件获取 file_url
      final fileUrl = await _uploadAudioForAsync(audioFilePath);
      debugPrint('File uploaded: $fileUrl');
      onProgress?.call('submit', '提交转写任务');

      // 步骤2: 提交异步转写任务
      final taskId = await _submitAsyncTranscription(
        fileUrl: fileUrl,
        language: language,
        enableWords: enableWords,
      );
      debugPrint('Task submitted: $taskId');
      onProgress?.call('process', '转写任务已提交，正在处理...');

      // 步骤3: 轮询任务状态
      final result = await _pollAsyncResult(
        taskId: taskId,
        onProgress: onProgress,
      );

      onProgress?.call('complete', '转写完成');
      debugPrint('=== Async Transcription Success: ${result.length} chars ===');
      return result;
    } catch (e) {
      debugPrint('=== Async Transcription Failed ===');
      debugPrint('Error: $e');
      rethrow;
    }
  }

  /// 上传音频文件到阿里云 OSS 获取临时 URL
  Future<String> _uploadAudioForAsync(String audioFilePath) async {
    final file = File(audioFilePath);
    final fileName = file.uri.pathSegments.last;
    final mimeType = _getMimeType(audioFilePath);

    // 读取文件内容
    final fileBytes = await file.readAsBytes();
    final base64Data = base64Encode(fileBytes);

    debugPrint(
        'Uploading audio: $fileName, mimeType: $mimeType, size: ${fileBytes.length} bytes');

    // 调用 DashScope 文件上传接口
    final response = await _dio.post(
      'https://dashscope.aliyuncs.com/api/v1/files',
      data: {
        'model': 'qwen3-asr-flash-filetrans',
        'file': 'data:$mimeType;base64,$base64Data',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final fileUrl = response.data['file_url'] as String?;
      if (fileUrl == null || fileUrl.isEmpty) {
        throw Exception('文件上传成功但未返回 URL');
      }
      return fileUrl;
    } else {
      throw Exception('文件上传失败: ${response.statusCode} - ${response.data}');
    }
  }

  /// 提交异步转写任务
  Future<String> _submitAsyncTranscription({
    required String fileUrl,
    String? language,
    bool enableWords = false,
  }) async {
    final requestData = <String, dynamic>{
      'model': 'qwen3-asr-flash-filetrans',
      'input': {
        'file_url': fileUrl,
      },
      'parameters': {
        'enable_itn': false,
        'enable_words': enableWords,
        if (language != null) 'language': language,
      },
    };

    debugPrint('Submitting async task: ${jsonEncode(requestData)}');

    final response = await _dio.post(
      'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
      data: requestData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final taskId = response.data['output']?['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        throw Exception('任务提交成功但未返回 task_id');
      }
      return taskId;
    } else {
      throw Exception('任务提交失败: ${response.statusCode} - ${response.data}');
    }
  }

  /// 轮询异步转写任务状态
  Future<String> _pollAsyncResult({
    required String taskId,
    void Function(String step, String detail)? onProgress,
    int maxRetries = 60, // 最多轮询60次
    Duration interval = const Duration(seconds: 5), // 每次间隔5秒
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      debugPrint(
          'Polling task status: $taskId (attempt ${attempt + 1}/$maxRetries)');

      final response = await _dio.get(
        'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('查询任务状态失败: ${response.statusCode}');
      }

      final taskStatus =
          response.data['output']?['task_status'] as String? ?? 'UNKNOWN';
      final result = response.data['output']?['results']?['transcription']
          ?['text'] as String?;

      debugPrint('Task status: $taskStatus');

      switch (taskStatus) {
        case 'PENDING':
          onProgress?.call('pending', '任务排队中... (${attempt + 1}/$maxRetries)');
          break;
        case 'RUNNING':
          onProgress?.call('running', '正在转写中... (${attempt + 1}/$maxRetries)');
          break;
        case 'SUCCEEDED':
          if (result != null && result.isNotEmpty) {
            return result;
          } else {
            throw Exception('转写成功但结果为空');
          }
        case 'FAILED':
          final errorMessage =
              response.data['output']?['error_message'] as String? ?? '未知错误';
          throw Exception('转写任务失败: $errorMessage');
        case 'UNKNOWN':
          throw Exception('任务不存在或状态未知');
        default:
          debugPrint('Unknown status: $taskStatus');
      }

      // 等待后再次轮询
      await Future.delayed(interval);
    }

    throw Exception('转写超时，请稍后通过任务ID查询结果: $taskId');
  }

  // ==================== 实时语音转写方法 ====================

  /// 实时语音转写 - 返回增量文本流
  ///
  /// 使用方式：
  /// ```dart
  /// final stream = apiService.transcribeRealtime(
  ///   audioStream: microphoneStream,
  ///   onStatusChange: (status) => print(status),
  /// );
  /// await for (final text in stream) {
  ///   print('增量文本: $text');
  /// }
  /// ```
  Stream<RealtimeTranscriptionResult> transcribeRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    if (!_currentConfig!.supportsRealtimeTranscription) {
      throw Exception(
          '${_currentConfig!.displayName} 不支持实时语音转写。请使用讯飞 Spark 或阿里云 Qwen。');
    }

    debugPrint('=== Realtime Transcription Start ===');
    debugPrint('Provider: ${_currentConfig!.name}');

    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        yield* _transcribeQwenRealtime(
          audioStream: audioStream,
          onStatusChange: onStatusChange,
          language: language,
        );
        break;
      case AiProvider.spark:
        yield* _transcribeIflytekRealtime(
          audioStream: audioStream,
          onStatusChange: onStatusChange,
          language: language,
        );
        break;
      default:
        throw Exception('${_currentConfig!.displayName} 不支持实时语音转写');
    }
  }

  /// 阿里云 Qwen 实时转写 (WebSocket)
  ///
  /// 支持两种模式：
  /// 1. DashScope Fun-ASR: 需要 sk-xxx 格式的 API Key
  /// 2. 通义听悟 TingWu: 需要 sk-xxx API Key + AppId
  ///
  /// 文档:
  /// - Fun-ASR: https://help.aliyun.com/zh/model-studio/fun-asr-real-time-speech-recognition-api-reference/
  /// - TingWu: https://help.aliyun.com/zh/model-studio/tingwu-industrial-instruction-api-websocket
  Stream<RealtimeTranscriptionResult> _transcribeQwenRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    final taskId = _generateTaskId();

    const wsUrl = 'wss://dashscope.aliyuncs.com/api-ws/v1/inference/';

    onStatusChange?.call('connecting', '连接 Qwen 实时转写服务...');

    // 判断使用哪种协议
    final hasAppId = _appId != null && _appId!.isNotEmpty;
    final isDashScopeApiKey = _apiKey != null && _apiKey!.startsWith('sk-');

    debugPrint('Qwen realtime: apiKey=${_apiKey?.substring(0, _apiKey!.length > 5 ? 5 : _apiKey!.length)}..., appId=$_appId, hasAppId=$hasAppId, isDashScopeApiKey=$isDashScopeApiKey');

    WebSocketChannel? channel;
    try {
      // 统一使用 Authorization: Bearer 认证
      channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer ${_apiKey ?? ''}',
        },
      );

      onStatusChange?.call('connected', '已连接，启动任务...');

      // 根据 appId 判断使用哪种协议
      Map<String, dynamic> runTaskMessage;
      if (hasAppId) {
        // 通义听悟协议
        runTaskMessage = {
          'header': {
            'action': 'run-task',
            'task_id': taskId,
            'streaming': 'duplex',
          },
          'payload': {
            'model': 'tingwu-industrial-instruction',
            'task_group': 'aigc',
            'task': 'multimodal-generation',
            'function': 'generation',
            'input': {
              'appId': _appId,
              'directive': 'start',
            },
            'parameters': {
              'sampleRate': 16000,
              'format': 'pcm',
            },
          },
        };
      } else {
        // DashScope Fun-ASR 协议
        runTaskMessage = {
          'header': {
            'action': 'run-task',
            'task_id': taskId,
            'streaming': 'duplex',
          },
          'payload': {
            'task_group': 'audio',
            'task': 'asr',
            'function': 'recognition',
            'model': _currentConfig!.realtimeAsrModel.isNotEmpty
                ? _currentConfig!.realtimeAsrModel
                : 'fun-asr-realtime',
            'parameters': {
              'sample_rate': 16000,
              'format': 'wav',
              if (language != null) 'language': language,
            },
            'input': {},
          },
        };
      }

      debugPrint('Sending run-task: ${jsonEncode(runTaskMessage)}');
      channel.sink.add(jsonEncode(runTaskMessage));

      bool taskStarted = false;
      bool speechListening = false;
      final audioController = StreamController<List<int>>();

      // 转发音频数据
      audioStream.listen(
        (data) {
          audioController.add(data);
        },
        onDone: () {
          audioController.close();
        },
        onError: (e) {
          debugPrint('Audio stream error: $e');
          audioController.addError(e);
        },
      );

      // 接收事件并处理
      await for (final message in channel.stream) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final header = data['header'] as Map<String, dynamic>?;
          final event = header?['event'] as String?;
          final payload = data['payload'] as Map<String, dynamic>?;
          final output = payload?['output'] as Map<String, dynamic>?;

          debugPrint('Received event: $event, action: ${output?['action']}');

          if (hasAppId) {
            // 通义听悟协议处理
            final action = output?['action'] as String?;
            switch (action) {
              case 'speech-listen':
                speechListening = true;
                taskStarted = true;
                onStatusChange?.call('streaming', '开始发送音频数据...');
                _sendAudioStream(audioController.stream, channel!);
                break;
              case 'recognize-result':
                final result = _parseTingwuResult(data);
                if (result != null) {
                  yield result;
                }
                break;
              case 'ai-result':
                final correction = output?['aiResult']?['correction'] as String?;
                if (correction != null && correction.isNotEmpty) {
                  yield RealtimeTranscriptionResult(
                    text: correction,
                    isFinal: true,
                    beginTime: Duration.zero,
                    endTime: Duration.zero,
                  );
                }
                break;
              case 'speech-end':
                onStatusChange?.call('completed', '转写完成');
                break;
              case 'task-failed':
                final errorCode = output?['errorCode'] ?? 'unknown';
                final errorMsg = output?['errorMessage'] ?? '任务失败';
                debugPrint('TingWu task failed: $errorCode - $errorMsg');
                onStatusChange?.call('error', '转写失败: $errorMsg');
                throw Exception('通义听悟实时转写失败: $errorMsg');
            }
          } else {
            // DashScope Fun-ASR 协议处理
            switch (event) {
              case 'task-started':
                taskStarted = true;
                onStatusChange?.call('streaming', '开始发送音频数据...');
                _sendAudioStream(audioController.stream, channel!);
                break;
              case 'result-generated':
                final result = _parseQwenRealtimeResult(data);
                if (result != null) {
                  yield result;
                }
                break;
              case 'task-finished':
                onStatusChange?.call('completed', '转写完成');
                break;
              case 'task-failed':
                final errorMsg = header?['error_message'] ?? '任务失败';
                debugPrint('Qwen ASR task failed: $errorMsg');
                onStatusChange?.call('error', '转写失败: $errorMsg');
                throw Exception('Qwen 实时转写失败: $errorMsg');
              default:
                debugPrint('Unknown event: $event');
            }
          }
        } catch (e) {
          if (e is Exception) rethrow;
          debugPrint('Parse realtime result error: $e');
        }
      }

      if (!taskStarted) {
        throw Exception('任务未启动，连接已关闭');
      }
    } catch (e) {
      onStatusChange?.call('error', '连接失败: $e');
      throw Exception('Qwen 实时转写连接失败: $e');
    } finally {
      // 发送 finish-task 指令
      Map<String, dynamic> finishTaskMessage;
      if (hasAppId) {
        finishTaskMessage = {
          'header': {
            'action': 'finish-task',
            'task_id': taskId,
            'streaming': 'duplex',
          },
          'payload': {
            'model': 'tingwu-industrial-instruction',
            'task_group': 'aigc',
            'task': 'multimodal-generation',
            'function': 'generation',
            'input': {
              'directive': 'stop',
            },
          },
        };
      } else {
        finishTaskMessage = {
          'header': {
            'action': 'finish-task',
            'task_id': taskId,
            'streaming': 'duplex',
          },
          'payload': {
            'input': {},
          },
        };
      }
      channel?.sink.add(jsonEncode(finishTaskMessage));
      await Future.delayed(const Duration(milliseconds: 500));
      channel?.sink.close();
      onStatusChange?.call('disconnected', '连接已关闭');
    }
  }

  String _generateTaskId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    for (var i = 0; i < 32; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  void _sendAudioStream(
    Stream<List<int>> audioStream,
    WebSocketChannel channel,
  ) {
    audioStream.listen(
      (data) {
        if (channel.closeCode == null) {
          channel.sink.add(Uint8List.fromList(data));
        }
      },
      onDone: () {
        debugPrint('Audio stream ended');
      },
      onError: (e) {
        debugPrint('Audio stream error: $e');
      },
    );
  }

  RealtimeTranscriptionResult? _parseQwenRealtimeResult(
      Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    final output = payload['output'] as Map<String, dynamic>?;
    if (output == null) return null;

    final sentence = output['sentence'] as Map<String, dynamic>?;
    if (sentence == null) return null;

    final text = sentence['text'] as String? ?? '';
    final isFinal = sentence['end_time'] != null;
    final beginTime = sentence['begin_time'] as int? ?? 0;
    final endTime = sentence['end_time'] as int? ?? beginTime;

    if (text.isEmpty) return null;

    return RealtimeTranscriptionResult(
      text: text,
      isFinal: isFinal,
      beginTime: Duration(milliseconds: beginTime),
      endTime: Duration(milliseconds: endTime),
    );
  }

  RealtimeTranscriptionResult? _parseTingwuResult(
      Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    final output = payload['output'] as Map<String, dynamic>?;
    if (output == null) return null;

    final transcription = output['transcription'] as Map<String, dynamic>?;
    if (transcription == null) return null;

    final text = transcription['text'] as String? ?? '';
    final isFinal = transcription['sentenceEnd'] as bool? ?? false;
    final beginTime = transcription['beginTime'] as int? ?? 0;
    final endTime = transcription['endTime'] as int? ?? beginTime;

    if (text.isEmpty) return null;

    return RealtimeTranscriptionResult(
      text: text,
      isFinal: isFinal,
      beginTime: Duration(milliseconds: beginTime),
      endTime: Duration(milliseconds: endTime),
    );
  }

  /// 讯飞实时转写 (WebSocket)
  ///
  /// 文档: https://www.xfyun.cn/doc/asr/rtasr/API.html
  Stream<RealtimeTranscriptionResult> _transcribeIflytekRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    onStatusChange?.call('connecting', '连接讯飞实时转写服务...');

    // 讯飞需要 AppID + APIKey + APISecret
    final apiKey = _apiKey ?? '';
    final appId = _appId;
    if (appId == null || appId.isEmpty) {
      throw Exception('讯飞实时转写需要配置 AppID，请在设置中配置');
    }

    // 构建鉴权 URL
    final wsUrl = await _buildIflytekWsUrl(apiKey, appId);

    WebSocketChannel? channel;
    try {
      channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      onStatusChange?.call('connected', '已连接，开始发送音频...');

      // 发送第一帧参数
      final firstFrame = {
        'common': {
          'app_id': appId,
        },
        'business': {
          'language': language ?? 'zh_cn',
          'domain': 'iat',
          'accent': 'mandarin',
          'vad_eos': 3000,
          'dwa': 'wpgs', // 动态修正
        },
        'data': {
          'status': 0, // 第一帧
          'format': 'audio/L16;rate=16000',
          'encoding': 'raw',
          'audio': '',
        },
      };
      channel.sink.add(jsonEncode(firstFrame));

      bool isFirst = true;

      // 发送音频数据
      audioStream.listen(
        (data) {
          if (channel != null) {
            final frame = {
              'data': {
                'status': isFirst ? 0 : 1, // 0=第一帧, 1=中间帧
                'format': 'audio/L16;rate=16000',
                'encoding': 'raw',
                'audio': base64Encode(Uint8List.fromList(data)),
              }
            };
            channel.sink.add(jsonEncode(frame));
            isFirst = false;
          }
        },
        onDone: () {
          // 发送最后一帧
          final lastFrame = {
            'data': {
              'status': 2, // 最后一帧
              'format': 'audio/L16;rate=16000',
              'encoding': 'raw',
              'audio': '',
            }
          };
          channel?.sink.add(jsonEncode(lastFrame));
        },
        onError: (e) {
          debugPrint('Audio stream error: $e');
          onStatusChange?.call('error', '音频流错误: $e');
        },
      );

      // 接收转写结果
      await for (final message in channel.stream) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final result = _parseIflytekRealtimeResult(data);
          if (result != null) {
            yield result;
          }
        } catch (e) {
          debugPrint('Parse realtime result error: $e');
        }
      }
    } catch (e) {
      onStatusChange?.call('error', '连接失败: $e');
      throw Exception('讯飞实时转写连接失败: $e');
    } finally {
      channel?.sink.close();
      onStatusChange?.call('disconnected', '连接已关闭');
    }
  }

  Future<String> _buildIflytekWsUrl(String apiKey, String appId) async {
    // 讯飞 WebSocket 鉴权 URL 构建
    // 参考: https://www.xfyun.cn/doc/asr/rtasr/API.html#_鉴权说明
    final host = 'rtasr.xfyun.cn';
    final path = '/v1/ws';
    final date = HttpDate.format(DateTime.now().toUtc());

    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';
    // 使用 HMAC-SHA256 签名
    // 这里简化处理，实际需要根据讯飞文档实现完整鉴权

    return 'wss://$host$path?appid=$appId&$apiKey';
  }

  RealtimeTranscriptionResult? _parseIflytekRealtimeResult(
      Map<String, dynamic> data) {
    final code = data['code'] as String? ?? '';
    if (code != '0') {
      final message = data['message'] as String? ?? 'Unknown error';
      debugPrint('iFlytek error: $message');
      return null;
    }

    final resultData = data['data'] as Map<String, dynamic>?;
    if (resultData == null) return null;

    final result = resultData['result'] as String? ?? '';
    final isFinal = resultData['ls'] == true;
    final bg = resultData['bg'] as String? ?? '0';
    final ed = resultData['ed'] as String? ?? bg;

    if (result.isEmpty) return null;

    return RealtimeTranscriptionResult(
      text: result,
      isFinal: isFinal,
      beginTime: Duration(milliseconds: int.tryParse(bg) ?? 0),
      endTime: Duration(milliseconds: int.tryParse(ed) ?? 0),
    );
  }
}

/// 实时转写结果
class RealtimeTranscriptionResult {
  final String text;
  final bool isFinal;
  final Duration beginTime;
  final Duration endTime;

  const RealtimeTranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.beginTime,
    required this.endTime,
  });

  @override
  String toString() {
    return 'RealtimeTranscriptionResult(text: $text, isFinal: $isFinal, beginTime: $beginTime, endTime: $endTime)';
  }
}
